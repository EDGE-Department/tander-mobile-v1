import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tander_flutter_v3/app/router/app_router.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';
import 'package:tander_flutter_v3/app/widgets/top_nav_bar.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/auth/data/datasources/notification_handler.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/push_providers.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_listener.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/states/call_state.dart';
import 'package:tander_flutter_v3/features/calls/presentation/widgets/incoming_call_overlay.dart';
import 'package:tander_flutter_v3/features/calls/services/call_push_bridge.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// Root scaffold for the authenticated app matching the web's layout:
/// - **Phone** (width < 1024): bottom dock nav bar
/// - **Tablet/Desktop** (width >= 1024): top header nav bar
///
/// Also wires push-notification init + the foreground incoming-call push →
/// native ring UI. CallKit accept/decline events are owned by
/// [V2CallkitListener] (flutter_callkit_incoming delivers onEvent to a single
/// effective listener), so this shell deliberately does NOT subscribe to them;
/// cold-start accept is handled natively via MainActivity.pendingColdStartAccept.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _hasNavigatedToCall = false;
  bool _hasPushInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasPushInitialized) {
        _hasPushInitialized = true;
        _initializePushNotifications();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Push notifications
  // ---------------------------------------------------------------------------

  Future<void> _initializePushNotifications() async {
    try {
      debugPrint('[AppShell] Starting push notification initialization...');

      // Let push_notification_service handle permission request — don't duplicate
      final pushService = ref.read(pushNotificationServiceProvider);
      await pushService.initialize();

      debugPrint(
        '[AppShell] Push service initialized, setting up notification routing...',
      );

      // Wire foreground notification routing with call push handling
      final router = ref.read(appRouterProvider);
      await NotificationHandler.initialize(
        router: router,
        onForegroundCall: _handleForegroundCallPush,
        onCallCancelled: _handleCallCancelledPush,
        onForegroundToast: (_) {
          // Generic toast notifications — handled by the system notification
        },
      );

      debugPrint('[AppShell] Push notification service fully initialized');
    } catch (error, stackTrace) {
      debugPrint('[AppShell] Push init failed: $error');
      debugPrint('[AppShell] Stack trace: $stackTrace');
    }
  }

  /// Handle incoming call push while app is in foreground.
  ///
  /// Shows native CallKit UI for ringtone (no bundled ringtone asset exists).
  /// The native UI is dismissed when call state leaves ringing (see the
  /// ref.listen block in build() which calls dismissNativeCallUI).
  ///
  /// Phase 5 v2 fields (real UUID callId, opaque accept/decline/dismiss
  /// tokens) ride along through CallKit extras so V2CallkitListener can
  /// route the answer event to /api/v2/calls/{callId}/accept-action.
  void _handleForegroundCallPush(RemoteMessage message) {
    final data = message.data;
    final isV2 = data['acceptToken'] is String;

    // v2 prefers `callId`; legacy uses `roomId`. Fall back across both.
    final callId = data['callId'] as String?;
    final roomId =
        (data['roomId'] as String?) ??
        (data['roomName'] as String?) ??
        callId ??
        '';
    final callerName =
        (data['callerName'] as String?) ??
        (data['displayName'] as String?) ??
        'Unknown Caller';
    final callType = (data['callType'] as String?) ?? 'audio';
    final callerPhoto =
        (data['callerPhoto'] as String?) ??
        (data['callerPhotoUrl'] as String?) ??
        (data['profilePhoto'] as String?);
    // v2 uses `callerUserId`; legacy uses `callerId`.
    final callerUserId =
        (data['callerUserId'] ?? data['callerId'] ?? data['userId'] ?? '')
            .toString();

    if (roomId.isEmpty) return;

    debugPrint(
      '[AppShell] Foreground call push (${isV2 ? "v2" : "legacy"}): '
      'room=$roomId caller=$callerName callId=$callId',
    );

    // Show native call UI for ringtone + lock screen. Threads v2 fields
    // into CallKit extras so V2CallkitListener.onAccept can read them.
    unawaited(
      CallPushBridge.showNativeCallUI(
        roomId: roomId,
        callerName: callerName,
        callType: callType,
        callerPhoto: callerPhoto,
        callId: callId,
        acceptToken: data['acceptToken'] as String?,
        declineToken: data['declineToken'] as String?,
        dismissToken: data['dismissToken'] as String?,
        callerUserId: isV2 ? callerUserId : null,
      ),
    );

    // Persist metadata for cold-start recovery — v2 fields included so
    // a future native fast-path can read them without booting Flutter.
    unawaited(
      CallPushBridge.persistCallMetadata(
        roomId: roomId,
        callerName: callerName,
        callType: callType,
        callerPhoto: callerPhoto,
        callerUserId: callerUserId,
        callId: callId,
        twilioRoomSid: data['twilioRoomSid'] as String?,
        acceptToken: data['acceptToken'] as String?,
        declineToken: data['declineToken'] as String?,
        dismissToken: data['dismissToken'] as String?,
        expiresAt: data['expiresAt'] as String?,
      ),
    );
  }

  /// Handle call cancelled push while app is in foreground.
  void _handleCallCancelledPush(RemoteMessage message) {
    final roomId =
        message.data['roomId'] as String? ??
        message.data['roomName'] as String? ??
        '';

    if (roomId.isNotEmpty) {
      unawaited(CallPushBridge.dismissNativeCallUI(roomId));
    }
    unawaited(CallPushBridge.clearPersistedMetadata());
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(callListenerProvider);

    // Auto-navigate to call screen for both incoming and outgoing calls
    ref.listen<CallState>(callNotifierProvider, (previous, next) {
      if (previous == null) return;
      final wasRinging = previous.isIncomingRinging;
      final isNowConnecting =
          next.status is CallConnecting || next.status is CallConnected;
      final isIncoming = next.callInfo?.direction == CallDirection.incoming;
      final isOutgoing = next.callInfo?.direction == CallDirection.outgoing;
      final roomName = next.callInfo?.roomName;

      // Dismiss native CallKit ringtone when call transitions away from ringing
      // (user accepted/declined via in-app overlay, not via native UI)
      if (wasRinging && !next.isIncomingRinging) {
        final ringingRoomName = previous.callInfo?.roomName;
        if (ringingRoomName != null) {
          unawaited(CallPushBridge.dismissNativeCallUI(ringingRoomName));
          unawaited(CallPushBridge.clearPersistedMetadata());
        }
      }

      // Navigate for incoming calls when they transition to connecting
      if (wasRinging &&
          isNowConnecting &&
          isIncoming &&
          roomName != null &&
          !_hasNavigatedToCall) {
        _hasNavigatedToCall = true;
        ref.read(appRouterProvider).push('/call?room=$roomName');
      }

      // Navigate for outgoing calls when they start ringing
      final wasIdle =
          previous.status is CallIdle || previous.status is CallInitiating;
      final isNowRinging = next.status is CallRinging;
      if (wasIdle &&
          isNowRinging &&
          isOutgoing &&
          roomName != null &&
          !_hasNavigatedToCall) {
        _hasNavigatedToCall = true;
        ref.read(appRouterProvider).push('/call?room=$roomName');
      }

      // Navigate back when call ends or resets to idle
      if (_hasNavigatedToCall &&
          (next.status is CallIdle ||
              next.status is CallEnded ||
              next.status is CallFailed)) {
        _hasNavigatedToCall = false;
        // Small delay to show ended state before navigating back
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ref.read(appRouterProvider).go(AppRoutes.messages);
          }
        });
      }
    });

    final callState = ref.watch(callNotifierProvider);
    final bool showOverlay = callState.isIncomingRinging;
    // Hide nav bars during active calls (call screen is inside the shell)
    final bool isInCall =
        callState.status is! CallIdle &&
        callState.status is! CallEnded &&
        callState.callInfo != null;
    final bool isModalOpen = ref.watch(modalVisibleProvider);
    final bool hideNav = showOverlay || isInCall || isModalOpen;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool useTopNav = screenWidth >= 1024;

    if (useTopNav) {
      // Tablet/Desktop: top header bar (matches web's lg: layout)
      return Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                if (!hideNav) const TanderTopNavBar(),
                Expanded(child: widget.child),
              ],
            ),
            if (showOverlay)
              const Positioned.fill(child: IncomingCallOverlay()),
          ],
        ),
      );
    }

    // Phone: bottom dock nav bar
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      extendBody: true,
      body: Stack(
        children: [
          widget.child,
          if (showOverlay) const Positioned.fill(child: IncomingCallOverlay()),
        ],
      ),
      bottomNavigationBar: hideNav ? null : const TanderBottomNavBar(),
    );
  }
}
