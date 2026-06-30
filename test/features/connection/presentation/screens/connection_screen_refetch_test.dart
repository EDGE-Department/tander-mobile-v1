/// Verifies that [ConnectionScreen.initState] fires [loadAll] on mount,
/// ensuring stale "Couldn't load…" errors never persist on re-navigation.
///
/// Because [ConnectionNotifier] is `final` (cannot be subclassed or
/// implementable outside its library), this test overrides at the repository
/// layer and uses [fetchIncomingRequests] call count as a proxy for
/// [loadAll] invocations. All providers that [ConnectionNotifier.build()]
/// requires are overridden so the test runs without real native plugins.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/connection/domain/repositories/connection_repository.dart';
import 'package:tander_flutter_v3/features/connection/presentation/providers/connection_providers.dart';
import 'package:tander_flutter_v3/features/connection/presentation/screens/connection_screen.dart';

// ── Fake repository ───────────────────────────────────────────────────────

/// Records [fetchIncomingRequests] calls as a proxy for [loadAll] invocations.
class _FakeRepository implements ConnectionRepository {
  int fetchCallCount = 0;

  static PaginatedResult<ConnectionSummary> _empty() =>
      const PaginatedResult<ConnectionSummary>(
        items: [],
        totalCount: 0,
        totalPages: 1,
        currentPage: 0,
        pageSize: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      );

  @override
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchIncomingRequests() async {
    fetchCallCount++;
    return Success(_empty());
  }

  @override
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchSentRequests() async =>
      Success(_empty());

  @override
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchConnections() async =>
      Success(_empty());

  @override
  Future<Result<void>> acceptRequest({required String matchId}) async =>
      const Success(null);

  @override
  Future<Result<void>> declineRequest({required String matchId}) async =>
      const Success(null);

  @override
  Future<Result<void>> cancelRequest({required String matchId}) async =>
      const Success(null);

  @override
  Future<Result<void>> removeConnection({required String matchId}) async =>
      const Success(null);

  @override
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchBlockedUsers() async =>
      Success(_empty());

  @override
  Future<Result<void>> blockUser({required String connectionId}) async =>
      const Success(null);

  @override
  Future<Result<void>> unmatchUser({required String connectionId}) async =>
      const Success(null);
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  testWidgets(
    'ConnectionScreen.initState triggers loadAll once via post-frame callback',
    (tester) async {
      final fakeRepo = _FakeRepository();

      // A minimal SessionManager with no session — the notifier checks
      // session?.userId before subscribing to STOMP, so null session means
      // no real-time subscription is attempted.
      final minimalSessionManager = SessionManager(
        secureStorage: const SecureStorage(FlutterSecureStorage()),
        dioClient: DioClient.withDio(Dio()),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionManagerProvider.overrideWithValue(minimalSessionManager),
            connectionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(home: ConnectionScreen()),
        ),
      );

      // pumpWidget runs the full first frame including microtasks and
      // post-frame callbacks. Both the notifier's build() microtask AND the
      // screen's initState post-frame callback fire within pumpWidget.
      // Each loadAll invocation calls fetchIncomingRequests once.
      //
      // Expected count: 2
      //   1 — notifier build() → Future.microtask(loadAll)
      //   1 — screen initState → addPostFrameCallback → loadAll
      await tester.pump(); // ensure all async work is flushed

      expect(
        fakeRepo.fetchCallCount,
        2,
        reason:
            'ConnectionScreen.initState must invoke loadAll via '
            'addPostFrameCallback in addition to the notifier build() auto-fetch. '
            'Expected 2 calls (build + initState); got ${fakeRepo.fetchCallCount}.',
      );
    },
  );
}
