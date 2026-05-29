import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_manager.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/states/call_state.dart';
import 'package:tander_flutter_v3/features/calls/presentation/widgets/call_screen_widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Full-screen call page with video renderers, controls, and status overlays.
///
/// Design: warm dark gradient matching Tander brand. Senior-friendly touch
/// targets (56px+), large avatar, clear status hierarchy.
/// bg gradient(160deg, #1A0800 0%, #0D0A06 40%, #06100E 100%)
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({required this.roomName, super.key});

  final String roomName;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    WakelockPlus.enable();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    if (!mounted) return;
    setState(() => _renderersInitialized = true);

    final callManager = ref.read(callManagerProvider);
    callManager.setStreamCallbacks(
      onLocal: (stream) {
        if (mounted) setState(() => _localRenderer.srcObject = stream);
      },
      onRemote: (stream) {
        if (mounted) setState(() => _remoteRenderer.srcObject = stream);
      },
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _handleHangUpAndPop() {
    ref.read(callManagerProvider).hangUp();
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted && context.canPop()) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callNotifierProvider);
    final callManager = ref.read(callManagerProvider);

    // Navigate back if idle with no call info
    if (callState.status is CallIdle && callState.callInfo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.canPop()) context.pop();
      });
    }

    final isVideoCall = callState.callInfo?.callType == CallType.video;
    final displayName = callState.callInfo?.remoteUsername ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A06),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          const DecoratedBox(
            decoration: BoxDecoration(gradient: callBackgroundGradient),
            child: SizedBox.expand(),
          ),

          // Video layout
          if (isVideoCall && _renderersInitialized) ...[
            _RemoteVideoView(renderer: _remoteRenderer),
            _RemoteVideoOffOverlay(
              callState: callState,
              displayName: displayName,
            ),
            _LocalPipView(
              renderer: _localRenderer,
              isCameraOn: callState.media.isCameraOn,
            ),
          ],

          // Audio layout
          if (!isVideoCall)
            CallAudioLayout(callState: callState, displayName: displayName),

          // Pre-connect overlay (video only)
          if (callState.isPreConnect && isVideoCall)
            CallPreConnectOverlay(
              callState: callState,
              displayName: displayName,
            ),

          // Ended overlay
          if (callState.isEnded)
            CallEndedOverlay(
              callState: callState,
              onReturn: () {
                if (context.canPop()) context.pop();
              },
            ),

          // Top bar
          if (!callState.isEnded)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _CallTopBar(
                callState: callState,
                onBack: _handleHangUpAndPop,
              ),
            ),

          // Controls
          if (!callState.isEnded)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _CallControls(
                callState: callState,
                callManager: callManager,
                isVideoCall: isVideoCall,
                onHangUp: _handleHangUpAndPop,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Remote video off overlay — shown when connected but remote camera is off
// ---------------------------------------------------------------------------

class _RemoteVideoOffOverlay extends StatelessWidget {
  const _RemoteVideoOffOverlay({
    required this.callState,
    required this.displayName,
  });

  final CallState callState;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    if (!callState.remoteMedia.isVideoOff || !callState.isConnected) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: const Color(0xCC000000),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CallAvatar(
              photoUrl: callState.callInfo?.remotePhotoUrl,
              displayName: displayName,
              radius: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera is off',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video sub-widgets (screen-specific, not reusable)
// ---------------------------------------------------------------------------

class _RemoteVideoView extends StatelessWidget {
  const _RemoteVideoView({required this.renderer});

  final RTCVideoRenderer renderer;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RTCVideoView(
        renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    );
  }
}

/// Local PiP: top-16(64) right-4(16) w-28(112) h-36(144) radius-2xl border-2 white/20
class _LocalPipView extends StatelessWidget {
  const _LocalPipView({required this.renderer, required this.isCameraOn});

  final RTCVideoRenderer renderer;
  final bool isCameraOn;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 64,
      right: 16,
      child: Container(
        width: 112,
        height: 144,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black45)],
        ),
        clipBehavior: Clip.antiAlias,
        child: isCameraOn
            ? RTCVideoView(
                renderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            : ColoredBox(
                color: const Color(0xCC000000),
                child: Center(
                  child: Icon(
                    Icons.videocam_off,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Call controls bar
// Controls: gradient(to top, rgba(0,0,0,0.50)->transparent), gap-5(20) pb-10(40) pt-16(64)
// ---------------------------------------------------------------------------

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.callState,
    required this.callManager,
    required this.isVideoCall,
    required this.onHangUp,
  });

  final CallState callState;
  final CallManager callManager;
  final bool isVideoCall;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CallControlButton(
            onTap: callManager.toggleMute,
            isActive: callState.media.isMuted,
            icon: callState.media.isMuted ? Icons.mic_off : Icons.mic,
            label: callState.media.isMuted ? 'Unmute' : 'Mute',
          ),
          if (isVideoCall) ...[
            const SizedBox(width: 20),
            CallControlButton(
              onTap: callManager.toggleCamera,
              isActive: !callState.media.isCameraOn,
              icon: callState.media.isCameraOn
                  ? Icons.videocam
                  : Icons.videocam_off,
              label: callState.media.isCameraOn ? 'Camera off' : 'Camera on',
            ),
          ],
          const SizedBox(width: 20),
          CallHangupButton(onTap: onHangUp),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _CallTopBar extends StatelessWidget {
  const _CallTopBar({required this.callState, required this.onBack});

  final CallState callState;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back,
                size: 20,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            if (callState.isConnected &&
                callState.callInfo?.callType == CallType.video)
              Text(
                callState.formattedDuration,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const Spacer(),
            Text(
              callState.callInfo?.callType == CallType.video
                  ? 'Video Call'
                  : 'Audio Call',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
