import 'package:tander_flutter_v3/core/contracts/calls_v2_contracts.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

/// Mints a short-lived Azure Web PubSub access token for the authenticated
/// user. Backend embeds the token in the returned `url` as
/// `?access_token=...` so [WpsClient] can pass it straight to
/// `WebSocketChannel.connect`.
///
/// TTL is 15 min for call-capable devices, 30 min for read-only — Backend
/// decides based on the `Device.supportsVideo` flag.
///
/// 401 here means session is revoked. [WpsClient] uses that to transition
/// to the `revoked` state and stop reconnecting; the existing
/// [TokenRefreshInterceptor] handles refresh on normal API calls.
final class RealtimeNegotiateDatasource {
  const RealtimeNegotiateDatasource({required DioClient dioClient})
    : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<NegotiateResponseDto> negotiate() async {
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.realtimeNegotiate,
      data: const <String, Object?>{},
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty body from /api/realtime/negotiate');
    }
    // Backend wraps every JSON 2xx response in `{success: true, data: ...}`
    // via `ApiResponseAdvice`. Accept both shapes defensively — the
    // /actuator + Springdoc endpoints are not wrapped.
    final inner = body['data'];
    return NegotiateResponseDto.fromJson(
      inner is Map<String, Object?> ? inner : body,
    );
  }
}
