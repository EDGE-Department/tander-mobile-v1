import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/services/twilio_native_bridge.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_active_call_state.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_call_preflight.dart';

/// Throwaway test screen for the Phase 5 v2 call path.
///
/// Verifies the full chain works end-to-end:
///   /api/v2/calls (start) → twilioToken
///   TwilioNativeBridge.connect → MethodChannel
///   TwilioCallManager.connect → Video.connect
///   peer joins → participantConnected event back to Flutter
///
/// Not user-facing — accessed from a hidden settings/profile entry. The
/// production replacement will live in `call_manager.dart` rewritten to
/// route through this same datasource + bridge.
class DebugV2CallScreen extends ConsumerStatefulWidget {
  const DebugV2CallScreen({super.key});

  @override
  ConsumerState<DebugV2CallScreen> createState() => _DebugV2CallScreenState();
}

class _DebugV2CallScreenState extends ConsumerState<DebugV2CallScreen> {
  final _calleeController = TextEditingController(
    text: '17a4541e-6b0d-4295-87bb-f3981ad0c7d2', // hint: standard test user
  );
  StreamSubscription<TwilioRoomEvent>? _eventsSub;

  String _status = 'idle';
  String? _activeCallId;
  String? _activeRoomName;
  final List<String> _log = <String>[];

  @override
  void initState() {
    super.initState();
    _eventsSub = TwilioNativeBridge.instance.events.listen(_onTwilioEvent);
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _calleeController.dispose();
    super.dispose();
  }

  void _appendLog(String line) {
    setState(() {
      _log.insert(
        0,
        '${DateTime.now().toIso8601String().substring(11, 19)}  $line',
      );
      if (_log.length > 40) _log.removeLast();
    });
  }

  void _onTwilioEvent(TwilioRoomEvent event) {
    switch (event) {
      case RoomConnected(:final roomName, :final roomSid):
        _appendLog('roomConnected name=$roomName sid=$roomSid');
        setState(() => _status = 'connected — waiting for peer');
      case RoomConnectFailure(:final code, :final message):
        _appendLog('roomConnectFailure code=$code msg=$message');
        setState(() => _status = 'connect failed: $message');
      case RoomReconnecting(:final message):
        _appendLog('reconnecting: $message');
        setState(() => _status = 'reconnecting');
      case RoomReconnected():
        _appendLog('reconnected');
        setState(() => _status = 'connected');
      case RoomDisconnected(:final code, :final message):
        _appendLog('roomDisconnected code=$code msg=$message');
        setState(() {
          _status = 'disconnected';
          _activeCallId = null;
          _activeRoomName = null;
        });
      case ParticipantConnected(:final identity, :final participantSid):
        _appendLog('participantConnected id=$identity sid=$participantSid');
        setState(() => _status = 'active — peer joined ($identity)');
      case ParticipantDisconnected(:final identity):
        _appendLog('participantDisconnected id=$identity');
        setState(() => _status = 'peer left');
      case AudioTrackSubscribed(:final participantSid, :final trackSid):
        _appendLog('audioTrack participant=$participantSid track=$trackSid');
      case NetworkQualityChanged(:final participantSid, :final level):
        _appendLog('netQual $participantSid → $level');
      case RemoteVideoTrackSubscribed(:final participantSid):
        _appendLog('remoteVideo subscribed $participantSid');
      case RemoteVideoTrackUnsubscribed(:final participantSid):
        _appendLog('remoteVideo unsubscribed $participantSid');
      case LocalVideoTrackPublished():
        _appendLog('localVideo published');
      case RemoteVideoEnabled(:final participantSid):
        _appendLog('remoteVideo enabled $participantSid');
      case RemoteVideoDisabled(:final participantSid):
        _appendLog('remoteVideo disabled $participantSid');
      case HangUpRequested():
        _appendLog('hangUpRequested (notification)');
    }
  }

  Future<void> _placeAudioCall() async {
    final calleeId = _calleeController.text.trim();
    if (calleeId.isEmpty) {
      _appendLog('callee UUID is required');
      return;
    }

    // Android 6+ runtime permission — Twilio's LocalAudioTrack.create
    // throws IllegalStateException if RECORD_AUDIO isn't granted.
    setState(() => _status = 'requesting mic permission...');
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _appendLog('mic permission denied (status=$micStatus)');
      setState(() => _status = 'mic permission denied');
      return;
    }

    final datasource = ref.read(callsV2RemoteDatasourceProvider);

    // Preflight: auto-end any existing active call so this one isn't rejected
    // as caller-busy. Never blocks (see resolveV2CallConflict).
    setState(() => _status = 'checking active call...');
    await resolveV2CallConflict(datasource: datasource);
    if (!mounted) return;

    setState(() => _status = 'starting...');
    _appendLog('startCall → calleeUserId=$calleeId callType=AUDIO');
    try {
      final response = await datasource.startCall(
        calleeUserId: calleeId,
        callType: 'AUDIO',
      );
      _appendLog(
        'startCall OK callId=${response.callId} room=${response.roomName}',
      );
      setState(() {
        _status = 'ringing — connecting to Twilio room';
        _activeCallId = response.callId;
        _activeRoomName = response.roomName;
      });
      // Surface the non-blocking active-call banner (app-root overlay).
      // The user can navigate freely; the debug screen stays for logs.
      ref
          .read(v2ActiveCallProvider.notifier)
          .start(
            callId: response.callId,
            roomName: response.roomName,
            peerName: 'Callee',
            callType: 'AUDIO',
          );
      await TwilioNativeBridge.instance.connect(
        roomName: response.roomName,
        twilioToken: response.twilioToken,
        isAudioOnly: true,
        peerName: 'Callee',
      );
      _appendLog('TwilioNativeBridge.connect dispatched — banner active');
    } catch (e, st) {
      AppLogger.warning(
        'startCall failed: $e\n$st',
        operation: 'DebugV2CallScreen._placeAudioCall',
      );
      _appendLog('startCall FAILED: $e');
      setState(() => _status = 'failed: $e');
    }
  }

  Future<void> _hangUp() async {
    final callId = _activeCallId;
    _appendLog('hangUp callId=$callId');
    try {
      // Disconnect Twilio first (idempotent on native side; mirrors web's
      // disconnectFromRoom-then-REST pattern per the lessons-from-web memory).
      await TwilioNativeBridge.instance.disconnect();
      if (callId != null) {
        final datasource = ref.read(callsV2RemoteDatasourceProvider);
        await datasource.end(callId, reason: 'user_hangup');
        _appendLog('end OK');
      }
    } catch (e) {
      _appendLog('hangUp error: $e');
    } finally {
      setState(() {
        _status = 'idle';
        _activeCallId = null;
        _activeRoomName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActive = _activeCallId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Debug v2 call')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Status: $_status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_activeCallId != null) ...<Widget>[
              SelectableText(
                'callId: $_activeCallId',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              SelectableText(
                'room:   $_activeRoomName',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _calleeController,
              enabled: !hasActive,
              decoration: const InputDecoration(
                labelText: 'Callee UUID',
                helperText: 'Pre-filled with the standard test user UUID',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasActive ? null : _placeAudioCall,
                    icon: const Icon(Icons.phone),
                    label: const Text('Call (audio)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasActive ? _hangUp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    icon: const Icon(Icons.call_end),
                    label: const Text('Hang up'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Event log',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withValues(alpha: 0.04),
                child: ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (_, i) => Text(
                    _log[i],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
