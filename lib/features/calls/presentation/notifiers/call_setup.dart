import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/data/call_peer_state.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/call_signaling.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/webrtc_peer.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_constants.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_listener.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_signal_handler.dart';
import 'package:tander_flutter_v3/features/calls/presentation/providers/call_providers.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/providers/messaging_providers.dart';

/// WebRTC peer setup, media acquisition, and signal subscription.
///
/// Extracted from CallManager to keep each class under 400 lines.
/// Handles the full setup flow for both outgoing and incoming calls.
final class CallSetup {
  CallSetup({
    required Ref ref,
    required CallSignalHandler signalHandler,
    required void Function(String, CallEndReason, [String?]) onTerminate,
    required Future<void> Function() onCleanup,
    required void Function() onScheduleIdleReset,
  })  : _ref = ref,
        _signalHandler = signalHandler,
        _onTerminate = onTerminate,
        _onCleanup = onCleanup,
        _onScheduleIdleReset = onScheduleIdleReset;

  final Ref _ref;
  final CallSignalHandler _signalHandler;
  final void Function(String, CallEndReason, [String?]) _onTerminate;
  final Future<void> Function() _onCleanup;
  final void Function() _onScheduleIdleReset;

  /// Creates peer connection, acquires media, subscribes to signals,
  /// and either sends an offer (outgoing) or drains the buffered offer (incoming).
  Future<void> setupCall(
    CallInfo callInfo, {
    required bool isOutgoing,
  }) async {
    final callRefs = getCallRefs();
    final userId = _ref.read(currentUserIdProvider);
    final notifier = _ref.read(callNotifierProvider.notifier);

    // Fetch ICE servers (non-fatal if fails)
    List<IceServerDto> iceServers = [];
    try {
      final datasource = _ref.read(callsRemoteDatasourceProvider);
      iceServers = await datasource.fetchIceServers();
    } on Exception {
      // Fall back to public STUN servers
    }

    // Create peer connection with callbacks
    final peer = WebrtcPeer(
      callbacks: WebrtcPeerCallbacks(
        onIceCandidate: (RTCIceCandidate candidate) {
          AppLogger.debug(
            'ICE candidate generated: ${candidate.candidate?.substring(0, 40) ?? "null"}...',
            operation: 'CallSetup.onIceCandidate',
          );
          final freshCallInfo = _ref.read(callNotifierProvider).callInfo;
          if (freshCallInfo != null) {
            sendIceCandidate(
              freshCallInfo.roomName,
              IceCandidateInfo(
                candidate: candidate.candidate ?? '',
                sdpMid: candidate.sdpMid,
                sdpMLineIndex: candidate.sdpMLineIndex,
              ),
              freshCallInfo.remoteUserId,
            );
          } else {
            AppLogger.warning('ICE candidate dropped — no callInfo', operation: 'CallSetup.onIceCandidate');
          }
        },
        onIceStateChange: _signalHandler.handleIceStateChange,
        onRemoteStream: (MediaStream stream) {
          callRefs.remoteStream = stream;
          try {
            callRefs.onRemoteStream?.call(stream);
          } on Exception {
            // Video renderer detached
          }
        },
        onConnectionStateChange: (_) {
          // Handled via ICE state
        },
      ),
    );

    await peer.create(iceServers);
    callRefs.peer = peer;

    // Subscribe to room signals BEFORE acquireMedia (which is slow on
    // emulators). This ensures ICE candidates from the remote peer are
    // captured and buffered by the signal handler while media initializes.
    callRefs.unsubRoom = subscribeToRoomSignals(
      callInfo.roomName,
      userId,
      _signalHandler.handleSignalEvent,
    );

    // For incoming calls: cancel the early subscription from CallListener
    // now that the full handler is active.
    if (!isOutgoing) {
      try {
        _ref.read(callListenerProvider).cancelEarlySignalSubscription();
      } on Object {
        // Provider might not be available
      }
    }

    // Acquire media (slow — camera init can take seconds on emulators)
    final isVideo = callInfo.callType == CallType.video;
    final localStream = await peer.acquireMedia(isVideo: isVideo);
    callRefs.localStream = localStream;
    try {
      callRefs.onLocalStream?.call(localStream);
    } on Exception {
      // Video renderer detached
    }

    if (isOutgoing) {
      await _handleOutgoingSetup(callInfo, peer, isVideo, callRefs, notifier);
    } else {
      await _handleIncomingSetup(callRefs);
    }
  }

  Future<void> _handleOutgoingSetup(
    CallInfo callInfo,
    WebrtcPeer peer,
    bool isVideo,
    CallRefs callRefs,
    CallNotifier notifier,
  ) async {
    final offerSdp = await peer.createOffer(isVideo: isVideo);
    sendOffer(callInfo.roomName, offerSdp, callInfo.remoteUserId);
    notifier.setStatus(const CallRinging());

    callRefs.timeoutTimer = Timer(CallTimeouts.initiating, () {
      final freshState = _ref.read(callNotifierProvider);
      final freshStatus = freshState.status;
      if (freshStatus is CallRinging || freshStatus is CallInitiating) {
        final freshInfo = freshState.callInfo;
        if (freshInfo != null) {
          sendHangup(
              freshInfo.roomName, 'no_response', freshInfo.remoteUserId);
          final datasource = _ref.read(callsRemoteDatasourceProvider);
          unawaited(
            datasource.cancelCall(freshInfo.roomName).catchError((_) {}),
          );
        }
        unawaited(_onCleanup());
        _ref
            .read(callNotifierProvider.notifier)
            .endCall(CallEndReason.noAnswer);
        _onScheduleIdleReset();
      }
    });
  }

  Future<void> _handleIncomingSetup(CallRefs callRefs) async {
    // Drain the module-level buffer (set by CallListener's early subscription)
    final earlyOffer = drainPendingOfferBuffer();
    if (earlyOffer != null) {
      callRefs.pendingOffer = earlyOffer;
    }

    // Also check if signal handler buffered one into callRefs directly
    if (callRefs.pendingOffer != null) {
      final bufferedOffer = callRefs.pendingOffer!;
      callRefs.pendingOffer = null;
      await processRemoteOffer(bufferedOffer.roomName, bufferedOffer.sdp);
    }

    callRefs.timeoutTimer = Timer(CallTimeouts.connecting, () {
      final freshStatus = _ref.read(callNotifierProvider).status;
      if (freshStatus is CallConnecting) {
        _onTerminate(
            'timeout', CallEndReason.timeout, 'Connection timed out');
      }
    });
  }

  // -----------------------------------------------------------------------
  // Offer/answer processing (called by signal handler too)
  // -----------------------------------------------------------------------

  Future<void> processRemoteOffer(String roomName, String sdp) async {
    final callRefs = getCallRefs();
    if (callRefs.peer == null || !callRefs.peer!.isAlive) {
      AppLogger.warning(
        'processRemoteOffer skipped — peer is null or closed',
        operation: 'CallSetup.processRemoteOffer',
      );
      return;
    }

    // Capture callInfo NOW before any async gaps where state could be cleared
    final capturedCallInfo = _ref.read(callNotifierProvider).callInfo;
    final capturedIsVideo = capturedCallInfo?.callType == CallType.video;

    if (capturedCallInfo == null) {
      AppLogger.error('processRemoteOffer: callInfo is null', operation: 'CallSetup.processRemoteOffer');
      return;
    }

    try {
      await callRefs.peer!.setRemoteOffer(sdp);
      await flushPendingIceCandidates();

      final answerSdp =
          await callRefs.peer!.createAnswer(isVideo: capturedIsVideo);

      AppLogger.info('Sending SDP answer', operation: 'CallSetup.processRemoteOffer',
        context: {'roomName': capturedCallInfo.roomName, 'answerLength': answerSdp.length},
      );
      sendAnswer(capturedCallInfo.roomName, answerSdp, capturedCallInfo.remoteUserId);
    } on Exception catch (error) {
      AppLogger.error('processRemoteOffer failed', operation: 'CallSetup.processRemoteOffer', error: error);
      _onTerminate('failed', CallEndReason.failed, error.toString());
    }
  }

  Future<void> processRemoteAnswer(String sdp) async {
    final callRefs = getCallRefs();
    if (callRefs.peer == null || !callRefs.peer!.isAlive) return;

    try {
      await callRefs.peer!.setRemoteAnswer(sdp);
      await flushPendingIceCandidates();
    } on Exception catch (error) {
      _onTerminate('failed', CallEndReason.failed, error.toString());
    }
  }

  Future<void> flushPendingIceCandidates() async {
    final callRefs = getCallRefs();
    if (callRefs.peer == null) return;

    final candidates =
        List<IceCandidateInfo>.from(callRefs.pendingIceCandidates);
    callRefs.pendingIceCandidates = [];

    for (final candidate in candidates) {
      await callRefs.peer!.addIceCandidate(candidate);
    }
  }
}
