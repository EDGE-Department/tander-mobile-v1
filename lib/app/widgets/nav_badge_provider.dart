/// Riverpod provider that polls for unread message count (every 30 s)
/// and pending connection count (every 60 s) to drive nav bar badges.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/connection/presentation/notifiers/connection_notifier.dart';
import 'package:tander_flutter_v3/features/connection/presentation/states/connection_state.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/notifiers/conversations_notifier.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/states/conversations_state.dart';

// ── Badge counts model ─────────────────────────────────────────────────

@immutable
class NavBadgeCounts {
  const NavBadgeCounts({
    this.unreadMessageCount = 0,
    this.pendingConnectionCount = 0,
  });

  final int unreadMessageCount;
  final int pendingConnectionCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavBadgeCounts &&
          runtimeType == other.runtimeType &&
          unreadMessageCount == other.unreadMessageCount &&
          pendingConnectionCount == other.pendingConnectionCount;

  @override
  int get hashCode =>
      unreadMessageCount.hashCode ^ pendingConnectionCount.hashCode;
}

// ── Polling intervals ──────────────────────────────────────────────────

const Duration _messagesPollInterval = Duration(seconds: 30);
const Duration _connectionsPollInterval = Duration(seconds: 60);

// ── Provider ───────────────────────────────────────────────────────────

/// Provides live badge counts by polling conversations and connections.
///
/// Derives counts from the existing conversation and connection notifiers
/// rather than making separate API calls.
final navBadgeProvider = NotifierProvider<NavBadgeNotifier, NavBadgeCounts>(
  NavBadgeNotifier.new,
);

// ── Notifier ───────────────────────────────────────────────────────────

final class NavBadgeNotifier extends Notifier<NavBadgeCounts> {
  Timer? _messagesTimer;
  Timer? _connectionsTimer;

  static const String _tag = 'NavBadgeNotifier';

  @override
  NavBadgeCounts build() {
    ref.onDispose(_disposeTimers);

    // Start polling after first frame.
    Future.microtask(_startPolling);

    // Derive initial counts from existing state.
    return _computeCounts();
  }

  void _startPolling() {
    _messagesTimer = Timer.periodic(_messagesPollInterval, (_) {
      _refreshMessages();
    });

    _connectionsTimer = Timer.periodic(_connectionsPollInterval, (_) {
      _refreshConnections();
    });
  }

  void _refreshMessages() {
    ref.read(conversationsNotifierProvider.notifier).refreshSilently();
    _emitCounts();
  }

  void _refreshConnections() {
    ref.read(connectionNotifierProvider.notifier).loadAll();
    _emitCounts();
  }

  /// Recomputes and emits the current badge counts.
  void _emitCounts() {
    final updatedCounts = _computeCounts();
    if (updatedCounts != state) {
      state = updatedCounts;
      AppLogger.debug(
        'Badge counts updated: messages=${updatedCounts.unreadMessageCount}, '
        'connections=${updatedCounts.pendingConnectionCount}',
        operation: _tag,
      );
    }
  }

  NavBadgeCounts _computeCounts() {
    final conversationsState = ref.read(conversationsNotifierProvider);
    final connectionState = ref.read(connectionNotifierProvider);

    final int unreadMessages = switch (conversationsState) {
      ConversationsLoaded(:final conversations) =>
        conversations
            .where((conv) => conv.unreadCount > 0 && !conv.isMuted)
            .length,
      _ => 0,
    };

    final int pendingConnections = switch (connectionState) {
      ConnectionLoaded(:final incomingRequests) =>
        incomingRequests.items.length,
      _ => 0,
    };

    return NavBadgeCounts(
      unreadMessageCount: unreadMessages,
      pendingConnectionCount: pendingConnections,
    );
  }

  /// Force-refresh badge counts (call after a state mutation).
  void recalculate() {
    _emitCounts();
  }

  void _disposeTimers() {
    _messagesTimer?.cancel();
    _messagesTimer = null;
    _connectionsTimer?.cancel();
    _connectionsTimer = null;
  }
}
