import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

/// REST API operations for call lifecycle management.
///
/// These endpoints complement STOMP signaling by persisting call state
/// on the backend (room creation, acceptance, termination).
final class CallsRemoteDatasource {
  const CallsRemoteDatasource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static const String _tag = 'CallsRemoteDatasource';

  // -----------------------------------------------------------------------
  // Room creation
  // -----------------------------------------------------------------------

  /// Creates a call room on the backend and returns room metadata.
  ///
  /// [receiverId] must be a valid user ID (int). [callType] is sent as
  /// the backend-expected string (e.g. "AUDIO" or "VIDEO").
  Future<CallRoomResponse> createRoom({
    required int receiverId,
    required CallType callType,
  }) async {
    AppLogger.debug(
      'Creating call room',
      operation: '$_tag.createRoom',
      context: {
        'receiverId': receiverId,
        'callType': callType.backendValue,
      },
    );

    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.createCallRoom,
      data: {
        'receiverId': receiverId,
        'callType': callType.backendValue,
      },
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty response from createCallRoom endpoint');
    }

    return CallRoomResponse.fromJson(body);
  }

  // -----------------------------------------------------------------------
  // ICE servers
  // -----------------------------------------------------------------------

  /// Fetches TURN/STUN server credentials from the backend.
  ///
  /// Returns an empty list on failure — callers fall back to public STUN.
  Future<List<IceServerDto>> fetchIceServers() async {
    AppLogger.debug(
      'Fetching ICE servers',
      operation: '$_tag.fetchIceServers',
    );

    final response = await _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.iceServers,
    );

    final body = response.data;
    if (body == null) return [];

    final rawServers = body['iceServers'];
    if (rawServers is! List) return [];

    return rawServers
        .whereType<Map<String, Object?>>()
        .map(IceServerDto.fromJson)
        .toList();
  }

  // -----------------------------------------------------------------------
  // Call lifecycle REST endpoints
  // -----------------------------------------------------------------------

  /// Notifies the backend that the callee accepted the call.
  Future<void> acceptCall(String roomName) async {
    AppLogger.debug(
      'Accepting call via REST',
      operation: '$_tag.acceptCall',
      context: {'roomName': roomName},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.acceptCall,
      data: {'roomName': roomName},
    );
  }

  /// Notifies the backend that the callee declined the call.
  Future<void> declineCall(String roomName) async {
    AppLogger.debug(
      'Declining call via REST',
      operation: '$_tag.declineCall',
      context: {'roomName': roomName},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.declineCall,
      data: {'roomName': roomName},
    );
  }

  /// Notifies the backend that the connected call ended normally.
  Future<void> endCall(String roomName) async {
    AppLogger.debug(
      'Ending call via REST',
      operation: '$_tag.endCall',
      context: {'roomName': roomName},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.endCall,
      data: {'roomName': roomName},
    );
  }

  /// Notifies the backend that the caller cancelled before the callee answered.
  Future<void> cancelCall(String roomName) async {
    AppLogger.debug(
      'Cancelling call via REST',
      operation: '$_tag.cancelCall',
      context: {'roomName': roomName},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.cancelCall,
      data: {'roomName': roomName},
    );
  }
}
