import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/services/device_id_service.dart';

/// Stamps the stable per-install device UUID on every authenticated request
/// as the `X-Tander-Device-Id` header.
///
/// Backend Phase 1 v2 endpoints require this header on every mutating call
/// (`POST /api/v2/calls/...`), plus the body's `deviceId` field must match
/// the header value. Without it the backend returns 400 `device-mismatch`.
///
/// Public auth endpoints (login, register, refresh-token, etc.) skip the
/// header because they pre-date the v2 contract and don't expect it.
final class DeviceIdInterceptor extends Interceptor {
  DeviceIdInterceptor({required DeviceIdService deviceIdService})
    : _deviceIdService = deviceIdService;

  final DeviceIdService _deviceIdService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_skipForPublicAuth(options.path)) {
      handler.next(options);
      return;
    }
    options.headers['X-Tander-Device-Id'] = _deviceIdService.getDeviceId();
    handler.next(options);
  }

  /// Public auth endpoints don't expect the header. Refresh-token is authed
  /// in spirit (carries old access token) but lives under /auth/ — include it.
  bool _skipForPublicAuth(String path) {
    if (!path.startsWith('/auth/')) return false;
    if (path.startsWith('/auth/refresh-token')) return false;
    return true;
  }
}
