import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/app/router/app_router.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';
import 'package:tander_flutter_v3/app/widgets/top_nav_bar.dart';
import 'package:tander_flutter_v3/features/auth/data/datasources/notification_handler.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/push_providers.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_listener.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_manager.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/states/call_state.dart';
import 'package:tander_flutter_v3/features/calls/presentation/widgets/incoming_call_overlay.dart';
import 'package:tander_flutter_v3/features/calls/services/call_push_bridge.dart';
import 'package:tander_flutter_v3/features/calls/services/cold_start_acceptor.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// Root scaffold for the authenticated app matching the web's layout:
/// - **Phone** (width < 1024): bottom dock nav bar
/// - **Tablet/Desktop** (width >= 1024): top header nav bar
///
/// Also wires:
/// - Push notification initialization
/// - CallKit native event listening (accept/decline from notification)
/// - Cold-start call consumption
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _hasNavigatedToCall = false;
  bool _hasPushInitialized = false;
  bool _hasCallKitInitialized = false;
  StreamSubscription<CallEvent?>? _callKitEventSub;
  /// Suppress spurious end/decline events fired by our own endCall()
  /// when dismissing the native notification after accept.
  bool _suppressNextCallKitEnd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasPushInitialized) {
        _hasPushInitialized = true;
        _initializePushNotifications();
      }
      if (!_hasCallKitInitialized) {
        _hasCallKitInitialized = true;
        _initializeCallKit();
        _consumeColdStartCall();
      }
    });
  }

  @override
  void dispose() {
    _callKitEventSub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Push notifications
  // ---------------------------------------------------------------------------

  Future<void> _initializePushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final pushService = ref.read(pushNotificationServiceProvider);
      await pushService.initialize();

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

      debugPrint('[AppShell] Push notification service initialized');
    } catch (error) {
      debugPrint('[AppShell] Push init failed: $error');
    }
  }

  /// Handle incoming call push while app is in foreground.
  ///
  /// Shows native CallKit UI for ringtone (no bundled ringtone asset exists).
  /// The native UI is dismissed when call state leaves ringing (see the
  /// ref.listen block in build() which calls dismissNativeCallUI).
  void _handleForegroundCallPush(RemoteMessage message) {
    final roomId = message.data['roomId'] as String? ??
        message.data['roomName'] as String? ??
        '';
    final callerName = message.data['callerName'] as String? ??
        message.data['displayName'] as String? ??
        'Unknown Caller';
    final callType = message.data['callType'] as String? ?? 'audio';
    final callerPhoto = message.data['callerPhoto'] as String? ??
        message.data['profilePhoto'] as String?;
    final callerUserId =
        (message.data['callerId'] ?? message.data['userId'] ?? '').toString();

    if (roomId.isEmpty) return;

    debugPrint(
        '[AppShell] Foreground call push: room=$roomId caller=$callerName');

    // Show native call UI for ringtone + lock screen
    unawaited(CallPushBridge.showNativeCallUI(
      roomId: roomId,
      callerName: callerName,
      callType: callType,
      callerPhoto: callerPhoto,
    ));

    // Persist metadata for cold-start recovery
    unawaited(CallPushBridge.persistCallMetadata(
      roomId: roomId,
      callerName: callerName,
      callType: callType,
      callerPhoto: callerPhoto,
      callerUserId: callerUserId,
    ));
  }

  /// Handle call cancelled push while app is in foreground.
  void _handleCallCancelledPush(RemoteMessage message) {
    final roomId = message.data['roomId'] as String? ??
        message.data['roomName'] as String? ??
        '';

    if (roomId.isNotEmpty) {
      unawaited(CallPushBridge.dismissNativeCallUI(roomId));
    }
    unawaited(CallPushBridge.clearPersistedMetadata());
  }

  // ---------------------------------------------------------------------------
  // CallKit native event handling
  // ---------------------------------------------------------------------------

  void _initializeCallKit() {
    _callKitEventSub = FlutterCallkitIncoming.onEvent.listen(
      _onCallKitEvent,
      onError: (Object error) {
        debugPrint('[AppShell] CallKit event stream error: $error');
      },
    );
    debugPrint('[AppShell] CallKit event listener initialized');
  }

  void _onCallKitEvent(CallEvent? event) {
    if (event == null) return;

    final callId = _extractCallIdFromEvent(event);
    debugPrint('[AppShell] CallKit event: ${event.event} callId=$callId');

    // Suppress spurious end/decline events fired by our own endCall()
    // when we dismiss the native notification after accepting.
    if (_suppressNextCallKitEnd &&
        (event.event == Event.actionCallDecline ||
         event.event == Event.actionCallEnded)) {
      _suppressNextCallKitEnd = false;
      debugPrint('[AppShell] Suppressed CallKit end event after accept dismiss');
      return;
    }

    switch (event.event) {
      case Event.actionCallAccept:
        _handleCallKitAccept(callId);

      case Event.actionCallDecline:
        _handleCallKitDecline(callId);

      case Event.actionCallEnded:
      case Event.actionCallTimeout:
        _handleCallKitEnded(callId);

      default:
        break;
    }
  }

  void _handleCallKitAccept(String? callId) {
    if (callId == null) return;

    // Immediately dismiss native CallKit UI + stop ringtone.
    // On Android the notification persists until explicitly ended.
    // Suppress the actionCallEnded event that endCall() fires.
    _suppressNextCallKitEnd = true;
    unawaited(FlutterCallkitIncoming.endCall(callId));
    unawaited(CallPushBridge.clearPersistedMetadata());

    final callState = ref.read(callNotifierProvider);

    // If the in-app call state is already ringing (STOMP triggered),
    // accept through the normal call manager flow
    if (callState.isIncomingRinging) {
      debugPrint('[AppShell] CallKit accept — using in-app call manager');
      ref.read(callManagerProvider).acceptCall();
      return;
    }

    // Otherwise, this is a background/killed accept — the call was set up
    // via push notification. We need to reconstruct call state from persisted
    // metadata and trigger the accept flow.
    debugPrint('[AppShell] CallKit accept — reconstructing from metadata');
    _acceptFromPushMetadata(callId);
  }

  Future<void> _acceptFromPushMetadata(String callId) async {
    final metadata = await CallPushBridge.readPersistedMetadata();
    if (metadata == null) {
      debugPrint('[AppShell] No persisted metadata for CallKit accept');
      return;
    }

    if (metadata.isStale) {
      debugPrint('[AppShell] Stale call metadata — ignoring accept');
      await CallPushBridge.clearPersistedMetadata();
      return;
    }

    // Set up call state from push metadata
    final notifier = ref.read(callNotifierProvider.notifier);
    final callInfo = metadata.toCallInfo();

    notifier.setCallInfo(callInfo);
    notifier.setStatus(const CallRinging());

    // Accept through the normal flow
    unawaited(ref.read(callManagerProvider).acceptCall());
    await CallPushBridge.clearPersistedMetadata();
  }

  void _handleCallKitDecline(String? callId) {
    if (callId == null) return;

    final callState = ref.read(callNotifierProvider);
    if (callState.isIncomingRinging) {
      ref.read(callManagerProvider).declineCall();
    }

    // Dismiss native UI and clean up
    unawaited(CallPushBridge.dismissNativeCallUI(callId));
    unawaited(CallPushBridge.clearPersistedMetadata());
  }

  void _handleCallKitEnded(String? callId) {
    if (callId == null) return;

    final callState = ref.read(callNotifierProvider);
    if (callState.isIncomingRinging) {
      final notifier = ref.read(callNotifierProvider.notifier);
      notifier.endCall(CallEndReason.noAnswer);

      // Reset to idle after display
      Future<void>.delayed(const Duration(seconds: 3), () {
        try {
          ref.read(callNotifierProvider.notifier).resetToIdle();
        } catch (_) {
          // Provider may have been disposed
        }
      });
    }

    unawaited(CallPushBridge.clearPersistedMetadata());
  }

  /// Extract callId from CallKit event body.
  String? _extractCallIdFromEvent(CallEvent event) {
    final body = event.body;
    if (body is Map) {
      return body['id'] as String? ?? body['callId'] as String?;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Cold-start call consumption
  // ---------------------------------------------------------------------------

  void _consumeColdStartCall() {
    if (!ColdStartAcceptor.hasPending) return;

    final pending = ColdStartAcceptor.consumePending();
    if (pending == null) return;

    debugPrint('[AppShell] Consuming cold-start call: room=${pending.roomId}');

    // Set call info + ringing state, then accept through the normal
    // call manager flow which sets up WebRTC, STOMP signals, and media.
    final notifier = ref.read(callNotifierProvider.notifier);
    final callInfo = pending.toCallInfo();

    notifier.setCallInfo(callInfo);
    notifier.setStatus(const CallRinging());

    // Accept through the normal flow (sets up WebRTC peer + signaling)
    ref.read(callManagerProvider).acceptCall();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(callListenerProvider);

    // Auto-navigate to call screen when incoming call transitions to connecting
    ref.listen<CallState>(callNotifierProvider, (previous, next) {
      if (previous == null) return;
      final wasRinging = previous.isIncomingRinging;
      final isNowConnecting =
          next.status is CallConnecting || next.status is CallConnected;
      final isIncoming = next.callInfo?.direction == CallDirection.incoming;
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

      if (wasRinging &&
          isNowConnecting &&
          isIncoming &&
          roomName != null &&
          !_hasNavigatedToCall) {
        _hasNavigatedToCall = true;
        context.push(AppRoutes.call(roomName));
      }

      // Reset flag when call ends
      if (next.status is CallIdle || next.status is CallEnded) {
        _hasNavigatedToCall = false;
      }
    });

    final callState = ref.watch(callNotifierProvider);
    final bool showOverlay = callState.isIncomingRinging;
    // Hide nav bars during active calls (call screen is inside the shell)
    final bool isInCall = callState.status is! CallIdle &&
        callState.status is! CallEnded &&
        callState.callInfo != null;
    final bool hideNav = showOverlay || isInCall;
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
          if (showOverlay)
            const Positioned.fill(child: IncomingCallOverlay()),
        ],
      ),
      bottomNavigationBar: hideNav ? null : const TanderBottomNavBar(),
    );
  }
}
