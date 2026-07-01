import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tander_flutter_v3/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';

// ---------------------------------------------------------------------------
// In-memory FlutterSecureStorage — no platform channels needed in tests.
// ---------------------------------------------------------------------------

class _FakeFlutterSecureStorage extends FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.clear();
}

// ---------------------------------------------------------------------------
// Sequential HTTP adapter — serves responses from a FIFO queue.
//
// DioAdapter's route-matching iterates all registered mocks and returns the
// LAST match, which breaks tests that register multiple mocks for the same
// endpoint (e.g. GET /api/data → 401, then GET /api/data → 200). This
// adapter avoids that by serving each response exactly once, in order.
// ---------------------------------------------------------------------------

class _SequentialAdapter implements HttpClientAdapter {
  final _queue = <Future<ResponseBody> Function(RequestOptions)>[];

  /// Enqueue a successful JSON response.
  void addResponse(int statusCode, Map<String, dynamic> data) {
    _queue.add(
      (_) async => ResponseBody.fromString(
        jsonEncode(data),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  /// Enqueue a DioException (simulates a server error / 4xx / 5xx).
  void addError(DioException Function(RequestOptions) make) {
    _queue.add((opts) async => throw make(opts));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) {
    if (_queue.isEmpty) {
      throw AssertionError(
        'No more responses queued for ${options.method} ${options.path}',
      );
    }
    return _queue.removeAt(0)(options);
  }

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _baseUrl = 'https://test.example.com';
const _dataPath = '/api/data';
const _refreshPath = '/auth/refresh-token';

/// Builds a Dio + SecureStorage pair backed by _SequentialAdapter.
({Dio dio, _SequentialAdapter adapter, SecureStorage storage}) _buildSetup() {
  final storage = SecureStorage(_FakeFlutterSecureStorage());
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final adapter = _SequentialAdapter();
  dio.httpClientAdapter = adapter;
  return (dio: dio, adapter: adapter, storage: storage);
}

/// Attaches a [TokenRefreshInterceptor] to [dio] and returns it.
TokenRefreshInterceptor _attachInterceptor({
  required Dio dio,
  required SecureStorage storage,
  required void Function() onExpired,
}) {
  final interceptor = TokenRefreshInterceptor(
    dio: dio,
    secureStorage: storage,
    onSessionExpired: onExpired,
  );
  dio.interceptors.add(interceptor);
  return interceptor;
}

/// A 401 DioException using the actual [RequestOptions] from the adapter.
DioException _unauthorized(RequestOptions opts) => DioException(
  requestOptions: opts,
  type: DioExceptionType.badResponse,
  response: Response<Object?>(requestOptions: opts, statusCode: 401),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Rotating refresh token ──────────────────────────────────────────────

  group('TokenRefreshInterceptor — rotating refresh token', () {
    test(
      'persists new refresh token from response body after a successful refresh',
      () async {
        final (:dio, :adapter, :storage) = _buildSetup();

        // Store the current session tokens.
        await storage.saveRefreshToken('old-refresh-token');
        await storage.saveAccessToken('current-access-token');

        // Queue responses in order:
        // 1. Original request fails with 401.
        adapter.addError(_unauthorized);
        // 2. Refresh endpoint returns a new (rotated) refresh token.
        adapter.addResponse(200, {
          'data': {'refreshToken': 'rotated-refresh-token'},
        });
        // 3. Retry of original request succeeds.
        adapter.addResponse(200, {'ok': true});

        _attachInterceptor(dio: dio, storage: storage, onExpired: () {});

        await dio.get<Object?>(_dataPath);

        final stored = await storage.readRefreshToken();
        expect(
          stored.valueOrNull,
          'rotated-refresh-token',
          reason: 'rotated refresh token from response body must be persisted',
        );
      },
    );

    test(
      'leaves existing refresh token unchanged when backend omits it',
      () async {
        final (:dio, :adapter, :storage) = _buildSetup();

        await storage.saveRefreshToken('stable-refresh-token');
        await storage.saveAccessToken('current-access-token');

        // 1. Original request fails with 401.
        adapter.addError(_unauthorized);
        // 2. Refresh response body has no refreshToken field.
        adapter.addResponse(200, {'data': <String, dynamic>{}});
        // 3. Retry succeeds.
        adapter.addResponse(200, <String, dynamic>{});

        _attachInterceptor(dio: dio, storage: storage, onExpired: () {});

        await dio.get<Object?>(_dataPath);

        final stored = await storage.readRefreshToken();
        expect(
          stored.valueOrNull,
          'stable-refresh-token',
          reason: 'original refresh token must be kept when backend sends none',
        );
      },
    );
  });

  // ── Session-expired notification guard ─────────────────────────────────

  group('TokenRefreshInterceptor — session-expired notification', () {
    test(
      'calls onSessionExpired exactly once when no refresh token is available',
      () async {
        final (:dio, :adapter, :storage) = _buildSetup();
        // Intentionally leave the refresh token absent.

        var callCount = 0;
        _attachInterceptor(
          dio: dio,
          storage: storage,
          onExpired: () => callCount++,
        );

        // 401 with no refresh token → session expired immediately.
        adapter.addError(_unauthorized);

        try {
          await dio.get<Object?>(_dataPath);
        } on DioException {
          // Expected — the session is dead.
        }

        expect(callCount, 1, reason: 'onSessionExpired must fire exactly once');
      },
    );

    test(
      'does NOT call onSessionExpired for auth endpoints (401 passes through)',
      () async {
        final (:dio, :adapter, :storage) = _buildSetup();

        var callCount = 0;
        _attachInterceptor(
          dio: dio,
          storage: storage,
          onExpired: () => callCount++,
        );

        adapter.addError(
          (opts) => DioException(
            requestOptions: opts,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(requestOptions: opts, statusCode: 401),
          ),
        );

        try {
          await dio.post<Object?>('/auth/login');
        } on DioException {
          // Expected — bad credentials, not a refresh scenario.
        }

        expect(
          callCount,
          0,
          reason: 'auth endpoints must never trigger session-expired',
        );
      },
    );
  });
}
