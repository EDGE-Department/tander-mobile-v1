import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';

void main() {
  group('CallType.fromBackend', () {
    test('maps VIDEO (any case) to video', () {
      expect(CallType.fromBackend('VIDEO'), CallType.video);
      expect(CallType.fromBackend('video'), CallType.video);
      expect(CallType.fromBackend('Video'), CallType.video);
    });

    test('maps everything else to audio', () {
      // Backend sends "voice" for audio; unknown values default to audio too.
      expect(CallType.fromBackend('AUDIO'), CallType.audio);
      expect(CallType.fromBackend('voice'), CallType.audio);
      expect(CallType.fromBackend(''), CallType.audio);
      expect(CallType.fromBackend('garbage'), CallType.audio);
    });
  });

  group('IceServerDto.fromJson', () {
    test('wraps a single String url into a list', () {
      final dto = IceServerDto.fromJson(const {'urls': 'stun:host:3478'});
      expect(dto.urls, ['stun:host:3478']);
    });

    test('keeps a list of urls, filtering non-strings', () {
      final dto = IceServerDto.fromJson(const {
        'urls': ['turn:a', 1, 'turn:b'],
        'username': 'u',
        'credential': 'c',
      });
      expect(dto.urls, ['turn:a', 'turn:b']);
      expect(dto.username, 'u');
      expect(dto.credential, 'c');
    });

    test('falls back to an empty list when urls is absent or wrong type', () {
      expect(IceServerDto.fromJson(const {}).urls, isEmpty);
      expect(IceServerDto.fromJson(const {'urls': 42}).urls, isEmpty);
    });
  });

  group('WebrtcSignalMessage.fromJson (and _parseOptionalInt)', () {
    test('parses targetUserId from int, numeric String, and rejects junk', () {
      expect(
        WebrtcSignalMessage.fromJson(const {
          'type': 'offer',
          'targetUserId': 7,
        }).targetUserId,
        7,
      );
      expect(
        WebrtcSignalMessage.fromJson(const {
          'type': 'offer',
          'targetUserId': '8',
        }).targetUserId,
        8,
      );
      expect(
        WebrtcSignalMessage.fromJson(const {
          'type': 'offer',
          'targetUserId': 'abc',
        }).targetUserId,
        isNull,
      );
      expect(
        WebrtcSignalMessage.fromJson(const {'type': 'offer'}).targetUserId,
        isNull,
      );
    });

    test('parses a nested ICE candidate, including sdpMLineIndex', () {
      final msg = WebrtcSignalMessage.fromJson(const {
        'roomName': 'room-1',
        'type': 'ice',
        'candidate': {
          'candidate': 'candidate:1 udp',
          'sdpMid': 'audio',
          'sdpMLineIndex': '0',
        },
      });

      expect(msg.roomName, 'room-1');
      expect(msg.candidate, isNotNull);
      expect(msg.candidate!.candidate, 'candidate:1 udp');
      expect(msg.candidate!.sdpMid, 'audio');
      expect(msg.candidate!.sdpMLineIndex, 0);
    });

    test('leaves candidate null when absent', () {
      final msg = WebrtcSignalMessage.fromJson(const {'type': 'hangup'});
      expect(msg.candidate, isNull);
      expect(msg.type, 'hangup');
    });
  });
}
