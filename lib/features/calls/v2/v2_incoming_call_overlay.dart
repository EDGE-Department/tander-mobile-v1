import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/services/call_push_bridge.dart';
import 'package:tander_flutter_v3/features/calls/services/twilio_native_bridge.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_active_call_banner.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_active_call_state.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_in_call_screen.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_incoming_call_state.dart';

/// Full-screen overlay shown when WPS delivers CALL_RINGING and the
/// local user is the callee. Mirrors web's IncomingCallOverlay UX.
///
/// Mount once near the app root via [V2IncomingCallOverlayHost] — the
/// host wraps the router child and conditionally overlays this widget
/// when [v2IncomingCallProvider] has a value.
class V2IncomingCallOverlayHost extends ConsumerWidget {
  const V2IncomingCallOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(v2IncomingCallProvider);
    // Only rebuild the host when the maximized flag flips — not on every
    // per-second timer tick inside the call state.
    final maximized = ref.watch(
      v2ActiveCallProvider.select((c) => c?.maximized ?? false),
    );
    // Mount the bubble ONLY while a minimized call exists. Keeping it as a
    // permanent child (rendering shrink when idle) leaked per-call State
    // across calls — e.g. `_hangingUp` stayed true after the first hangup and
    // dead-disabled every button on the next call. The banner's State must die
    // with the call. See [[mobile-call-screen-phases]].
    final bannerVisible = ref.watch(
      v2ActiveCallProvider.select((c) => c != null && !c.maximized),
    );
    return Stack(
      children: <Widget>[
        child,
        // Minimized island bubble — ephemeral, so its State resets per call.
        if (bannerVisible)
          const Align(
            alignment: Alignment.topCenter,
            child: V2ActiveCallBanner(),
          ),
        // Maximized full-screen in-call UI — covers the bubble. An overlay
        // layer (NOT a route) so it shares the call's single lifecycle.
        if (maximized) const Positioned.fill(child: V2InCallScreen()),
        // Incoming ring sits on top of everything — a new call must preempt
        // the in-progress call's UI.
        if (incoming != null)
          Positioned.fill(child: _V2IncomingCallOverlay(call: incoming)),
      ],
    );
  }
}

class _V2IncomingCallOverlay extends ConsumerStatefulWidget {
  const _V2IncomingCallOverlay({required this.call});
  final V2IncomingCall call;

  @override
  ConsumerState<_V2IncomingCallOverlay> createState() =>
      _V2IncomingCallOverlayState();
}

class _V2IncomingCallOverlayState
    extends ConsumerState<_V2IncomingCallOverlay> {
  bool _processing = false;

  Future<void> _onAccept() async {
    if (_processing) return;
    setState(() => _processing = true);

    final call = widget.call;
    AppLogger.info(
      'accept tapped callId=${call.callId}',
      operation: 'V2IncomingCallOverlay',
    );

    // Dismiss any CallKit/system notification for the same call so the
    // user doesn't see the lingering heads-up after accepting via the
    // Flutter overlay. Either-direction Accept (overlay or CallKit)
    // should clear both UIs. roomName normalizes to the same UUID the
    // FCM push pipeline used in [CallPushBridge.showNativeCallUI].
    unawaited(CallPushBridge.dismissNativeCallUI(call.roomName));
    // Record handled NOW so the ~3s-late FCM incoming push is suppressed
    // (not re-raised) — the dismiss above is a no-op when the push hasn't
    // arrived yet, which is exactly the lingering-notification case.
    unawaited(CallPushBridge.markCallHandled(call.callId));

    // Capture provider refs BEFORE any await. The incoming overlay can be
    // unmounted mid-flight (V2IncomingCallNotifier clears state on the WPS
    // CALL_CONNECTING event), which disposes this widget. Provider notifiers
    // outlive the widget, so capturing them up front avoids the
    // "Cannot use ref after widget was disposed" crash.
    final datasource = ref.read(callsV2RemoteDatasourceProvider);
    final incomingNotifier = ref.read(v2IncomingCallProvider.notifier);
    final activeNotifier = ref.read(v2ActiveCallProvider.notifier);

    // Mic permission gate — same as debug screen's outgoing path.
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _showSnack('Microphone permission denied');
      incomingNotifier.clear();
      return;
    }

    // Video calls also need camera. Must be settled BEFORE connect so the
    // native camera-typed foreground service can claim it (Android 14+).
    // If denied we still join — the native side falls back to audio-only.
    if (call.callType.toUpperCase() == 'VIDEO') {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        _showSnack('Camera permission denied — joining with audio only');
      }
    }

    try {
      final accept = await datasource.accept(call.callId);
      if (!accept.accepted) {
        _showSnack('Call could not be accepted: ${accept.outcome}');
        incomingNotifier.clear();
        return;
      }

      final twilioToken = accept.twilioToken;
      final roomName = accept.roomName ?? call.roomName;
      if (twilioToken == null) {
        _showSnack('No Twilio token in accept response');
        incomingNotifier.clear();
        return;
      }

      // Surface the non-blocking active-call banner BEFORE connecting, so
      // the always-subscribed V2ActiveCallNotifier is tracking and the
      // banner is on screen when roomConnected/participantConnected fire.
      activeNotifier.start(
        callId: call.callId,
        roomName: roomName,
        peerName: call.callerName,
        callType: call.callType,
        peerPhotoUrl: call.callerPhotoUrl,
      );
      // Dismiss the ring overlay (provider-level — survives this widget's
      // disposal). No router.push: the banner is an app-root overlay, so
      // the user keeps navigating freely.
      incomingNotifier.clear();

      unawaited(
        TwilioNativeBridge.instance.connect(
          roomName: roomName,
          twilioToken: twilioToken,
          isAudioOnly: call.callType != 'VIDEO',
          peerName: call.callerName,
        ),
      );
    } catch (e, st) {
      AppLogger.warning(
        'accept failed: $e\n$st',
        operation: 'V2IncomingCallOverlay',
      );
      _showSnack(_friendlyAcceptError(e));
      incomingNotifier.clear();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _onDecline() async {
    if (_processing) return;
    setState(() => _processing = true);

    final call = widget.call;
    AppLogger.info(
      'decline tapped callId=${call.callId}',
      operation: 'V2IncomingCallOverlay',
    );

    // Dismiss the CallKit notification too — same rationale as accept.
    unawaited(CallPushBridge.dismissNativeCallUI(call.roomName));
    unawaited(CallPushBridge.markCallHandled(call.callId));

    try {
      final datasource = ref.read(callsV2RemoteDatasourceProvider);
      await datasource.decline(call.callId, reason: 'user_declined');
    } catch (e) {
      AppLogger.warning(
        'decline failed: $e',
        operation: 'V2IncomingCallOverlay',
      );
    } finally {
      ref.read(v2IncomingCallProvider.notifier).clear();
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Map an accept failure to a user-facing message. A network/connection
  /// problem must not read as "session expired" — that misdirects the user
  /// into re-logging-in when they just need to retry.
  String _friendlyAcceptError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('network') ||
        s.contains('connection') ||
        s.contains('socket') ||
        s.contains('host lookup') ||
        s.contains('timed out') ||
        s.contains('timeout')) {
      return "Couldn't reach the server. Check your connection and try again.";
    }
    if (s.contains('session expired')) {
      return 'Your session expired. Please sign in again.';
    }
    return 'Could not answer the call. Please try again.';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final theme = Theme.of(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 32),
              Text(
                'Incoming ${call.callType.toLowerCase()} call',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white24,
                  backgroundImage: call.callerPhotoUrl != null
                      ? NetworkImage(call.callerPhotoUrl!)
                      : null,
                  child: call.callerPhotoUrl == null
                      ? Text(
                          call.callerName.characters
                              .take(1)
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                call.callerName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _CircleButton(
                    icon: Icons.call_end,
                    label: 'Decline',
                    color: Colors.redAccent,
                    onPressed: _processing ? null : _onDecline,
                  ),
                  _CircleButton(
                    icon: Icons.call,
                    label: 'Accept',
                    color: Colors.greenAccent.shade400,
                    onPressed: _processing ? null : _onAccept,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_processing)
                const Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
