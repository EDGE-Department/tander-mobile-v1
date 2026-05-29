import 'package:tander_flutter_v3/core/contracts/calls_v2_contracts.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/services/device_id_service.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';
import 'package:uuid/uuid.dart';

/// REST datasource for the Phase 5 v2 call endpoints
/// (`/api/v2/calls/*`). The body's `deviceId` always matches the
/// `X-Tander-Device-Id` header set by [DeviceIdInterceptor]; the backend
/// enforces parity and rejects mismatches with 400 `device-mismatch`.
///
/// `idempotencyKey` is a fresh client-generated UUID per attempt — set
/// BOTH as the `Idempotency-Key` request header (read by the backend's
/// `ApiIdempotencyJwtInterceptor`) AND in the JSON body (validated by
/// the controller). Callers pass `null` to auto-generate; provide a
/// stable key when retrying the same logical action.
///
/// Action-token methods (`acceptAction`, `declineAction`, `dismissAction`)
/// are invoked from killed-app native handlers before Flutter boots; this
/// Dart wrapper exists for in-app paths that already have the opaque token.
final class CallsV2RemoteDatasource {
  CallsV2RemoteDatasource({
    required DioClient dioClient,
    required DeviceIdService deviceIdService,
  }) : _dioClient = dioClient,
       _deviceIdService = deviceIdService;

  final DioClient _dioClient;
  final DeviceIdService _deviceIdService;
  static const _uuid = Uuid();
  static const String _tag = 'CallsV2RemoteDatasource';

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle — JWT-authed
  // ─────────────────────────────────────────────────────────────────────

  /// Initiates an outgoing call to [calleeUserId]. Returns the Twilio room
  /// + access token to connect to.
  Future<StartCallResponseDto> startCall({
    required String calleeUserId,
    required String callType,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = StartCallRequestDto(
      calleeUserId: calleeUserId,
      callType: callType,
      deviceId: _deviceIdService.getDeviceId(),
      idempotencyKey: key,
    );
    AppLogger.debug(
      'startCall',
      operation: '$_tag.startCall',
      context: {'calleeUserId': calleeUserId, 'callType': callType},
    );
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2Start,
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
    return StartCallResponseDto.fromJson(_requireBody(response.data));
  }

  /// Callee accepts an incoming call (RINGING → CONNECTING).
  Future<AcceptResponseDto> accept(
    String callId, {
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = _deviceReq(idempotencyKey: key);
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2Accept(callId),
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
    return AcceptResponseDto.fromJson(_requireBody(response.data));
  }

  /// Callee declines an incoming call (RINGING → DECLINED).
  Future<TerminalResponseDto> decline(
    String callId, {
    String? reason,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = _deviceReq(reason: reason, idempotencyKey: key);
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2Decline(callId),
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
    return TerminalResponseDto.fromJson(_requireBody(response.data));
  }

  /// Caller cancels an outgoing ringing call (RINGING → CANCELLED).
  Future<TerminalResponseDto> cancel(
    String callId, {
    String? reason,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = _deviceReq(reason: reason, idempotencyKey: key);
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2Cancel(callId),
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
    return TerminalResponseDto.fromJson(_requireBody(response.data));
  }

  /// Either party hangs up a CONNECTING / ACTIVE / RECONNECTING call.
  Future<TerminalResponseDto> end(
    String callId, {
    String? reason,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = _deviceReq(reason: reason, idempotencyKey: key);
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2End(callId),
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
    return TerminalResponseDto.fromJson(_requireBody(response.data));
  }

  /// Dismisses the incoming-call UI on THIS device only — other devices
  /// keep ringing. Used when the user swipes away the notification.
  Future<void> dismissDevice(String callId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = _deviceReq(idempotencyKey: key);
    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2DismissDevice(callId),
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
  }

  /// Transfers an active call from one of the user's devices to another.
  Future<HandoffResponseDto> handoff({
    required String callId,
    required String fromDeviceId,
    required String toDeviceId,
    required String role,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = HandoffRequestDto(
      fromDeviceId: fromDeviceId,
      toDeviceId: toDeviceId,
      role: role,
      idempotencyKey: key,
    );
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2Handoff(callId),
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
    return HandoffResponseDto.fromJson(_requireBody(response.data));
  }

  // ─────────────────────────────────────────────────────────────────────
  // Read — JWT-authed
  // ─────────────────────────────────────────────────────────────────────

  /// Gets the authenticated user's currently-active call (RINGING /
  /// CONNECTING / ACTIVE / RECONNECTING) plus a rejoin token if eligible.
  /// Returns `null` envelope if no active call.
  Future<ActiveCallResponseDto> getActive() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.callsV2Active,
    );
    return ActiveCallResponseDto.fromJson(_requireBody(response.data));
  }

  /// Focused token refresh — for clients that already have local call
  /// context but need a fresh Twilio access token to rejoin after a network
  /// drop.
  Future<RejoinTokenResponseDto> getCallToken(String callId) async {
    final key = _uuid.v4();
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2Token(callId),
      data: const <String, Object?>{},
      headers: _idempotencyHeader(key),
    );
    return RejoinTokenResponseDto.fromJson(_requireBody(response.data));
  }

  // ─────────────────────────────────────────────────────────────────────
  // Action-token authed (NO JWT — opaque callActionToken)
  // ─────────────────────────────────────────────────────────────────────

  Future<AcceptResponseDto> acceptAction(
    String callId,
    String callActionToken, {
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = _actionReq(callActionToken, key);
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2AcceptAction(callId),
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
    return AcceptResponseDto.fromJson(_requireBody(response.data));
  }

  Future<TerminalResponseDto> declineAction(
    String callId,
    String callActionToken, {
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = _actionReq(callActionToken, key);
    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2DeclineAction(callId),
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
    return TerminalResponseDto.fromJson(_requireBody(response.data));
  }

  Future<void> dismissAction(
    String callId,
    String callActionToken, {
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final req = _actionReq(callActionToken, key);
    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.callsV2DismissAction(callId),
      data: req.toJson(),
      headers: _idempotencyHeader(key),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────

  /// Backend's idempotency interceptor reads the `Idempotency-Key`
  /// HEADER (`ApiIdempotencyJwtInterceptor`, header constant
  /// `IdempotencyConstants.HEADER`). Must match the body's
  /// idempotencyKey field for type-validation parity.
  Map<String, String> _idempotencyHeader(String key) => {
    'Idempotency-Key': key,
  };

  DeviceRequestDto _deviceReq({String? reason, String? idempotencyKey}) =>
      DeviceRequestDto(
        deviceId: _deviceIdService.getDeviceId(),
        idempotencyKey: idempotencyKey ?? _uuid.v4(),
        reason: reason,
      );

  ActionTokenRequestDto _actionReq(String token, String idempotencyKey) =>
      ActionTokenRequestDto(
        callActionToken: token,
        deviceId: _deviceIdService.getDeviceId(),
        idempotencyKey: idempotencyKey,
      );

  /// Unwraps backend's `ApiResponseAdvice` envelope `{success, data}` and
  /// returns the inner DTO map. Accepts an already-unwrapped body
  /// defensively (some endpoints skip the advice).
  Map<String, Object?> _requireBody(Map<String, Object?>? body) {
    if (body == null) {
      throw StateError('Empty response body from v2 call endpoint');
    }
    final inner = body['data'];
    if (inner is Map<String, Object?>) return inner;
    // Already-unwrapped path (defensive — controller could have returned
    // ResponseEntity directly with the DTO).
    return body;
  }
}
