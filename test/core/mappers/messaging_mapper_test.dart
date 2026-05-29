import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/core/contracts/messaging_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/mappers/messaging_mapper.dart';

void main() {
  group('MessagingMapper.mapMessageDto', () {
    MessageDto dto({
      String kind = 'TEXT',
      String? body = 'hi',
      String? mediaUrl,
      String? deliveredAt,
      String? readAt,
    }) => MessageDto(
      id: 'm1',
      conversationId: 'c1',
      senderUserId: 'u2',
      kind: kind,
      sentAt: '2026-05-28T10:00:00Z',
      body: body,
      mediaUrl: mediaUrl,
      deliveredAt: deliveredAt,
      readAt: readAt,
    );

    test('infers delivery state in read > delivered > sent order', () {
      expect(
        MessagingMapper.mapMessageDto(
          dto(readAt: '2026-05-28T10:05:00Z', deliveredAt: '2026-05-28T10:01:00Z'),
        ).deliveryState,
        MessageDeliveryState.read,
      );
      expect(
        MessagingMapper.mapMessageDto(dto(deliveredAt: '2026-05-28T10:01:00Z'))
            .deliveryState,
        MessageDeliveryState.delivered,
      );
      expect(
        MessagingMapper.mapMessageDto(dto()).deliveryState,
        MessageDeliveryState.sent,
      );
    });

    test('builds media only when mediaUrl present AND kind is IMAGE/VOICE', () {
      final image = MessagingMapper.mapMessageDto(
        dto(kind: 'IMAGE', mediaUrl: 'https://cdn/x.jpg'),
      );
      expect(image.media, isNotNull);
      expect(image.media!.type, MessageMediaType.image);

      // mediaUrl present but kind TEXT → no media.
      expect(
        MessagingMapper.mapMessageDto(
          dto(kind: 'TEXT', mediaUrl: 'https://cdn/x.jpg'),
        ).media,
        isNull,
      );
      // kind IMAGE but no mediaUrl → no media.
      expect(MessagingMapper.mapMessageDto(dto(kind: 'IMAGE')).media, isNull);
    });

    test('parses sentAt deterministically and roomId mirrors conversationId', () {
      final item = MessagingMapper.mapMessageDto(dto());
      expect(item.sentAt, DateTime.utc(2026, 5, 28, 10));
      expect(item.roomId, 'c1');
      expect(item.conversationId, 'c1');
    });

    test('senderUsername is always null on the REST path', () {
      // Pinned: mapMessageDto hardcodes null; mapStompPayload uses '' instead.
      expect(MessagingMapper.mapMessageDto(dto()).senderUsername, isNull);
    });
  });

  group('MessagingMapper.mapStompPayload', () {
    MessageItem? map(Map<String, Object?> payload) =>
        MessagingMapper.mapStompPayload(
          payload,
          conversationId: 'c1',
          roomId: 'r1',
        );

    test('returns null when messageId is missing', () {
      expect(map(const {'text': 'hi'}), isNull);
    });

    test('stringifies a numeric messageId and sets conversation/room ids', () {
      final item = map(const {'messageId': 99, 'text': 'hi'})!;
      expect(item.messageId, '99');
      expect(item.conversationId, 'c1');
      expect(item.roomId, 'r1');
    });

    test('resolves body from text, then content, else null', () {
      expect(map(const {'messageId': '1', 'text': 'A'})!.body, 'A');
      expect(map(const {'messageId': '1', 'content': 'B'})!.body, 'B');
      expect(map(const {'messageId': '1'})!.body, isNull);
    });

    test('parses an int timestamp as epoch millis', () {
      final item = map(const {'messageId': '1', 'timestamp': 1748426400000})!;
      expect(item.sentAt, DateTime.fromMillisecondsSinceEpoch(1748426400000));
    });

    test('VOICE messageType without a mediaUrl yields no media object', () {
      // Pinned: mediaType is computed as voice, but `media` is gated on
      // hasMedia, so no URL → media stays null.
      expect(
        map(const {'messageId': '1', 'messageType': 'VOICE'})!.media,
        isNull,
      );
    });

    test('builds voice/image media when a mediaUrl is present', () {
      final voice = map(const {
        'messageId': '1',
        'messageType': 'VOICE',
        'mediaUrl': 'https://cdn/v.m4a',
        'mediaDurationSeconds': 12,
      })!;
      expect(voice.media!.type, MessageMediaType.voice);
      expect(voice.media!.durationSeconds, 12);

      final image = map(const {
        'messageId': '1',
        'messageType': 'IMAGE',
        'mediaUrl': 'https://cdn/p.jpg',
      })!;
      expect(image.media!.type, MessageMediaType.image);
    });

    test('senderUsername falls back to empty string (not null)', () {
      expect(map(const {'messageId': '1'})!.senderUsername, '');
    });
  });

  group('MessagingMapper.mapConversationDto', () {
    ConversationDto convo({
      List<ConversationPhotoDto>? photos,
      String? firstName = 'Ana',
      ConversationOtherUserDto? otherUser = _unset,
      String? connectionId,
      String? lastMessageAt = '2026-05-28T09:00:00Z',
      String? lastMessageBody = 'hello',
    }) => ConversationDto(
      id: 'conv-1',
      otherUserId: 'u2',
      connectionId: connectionId,
      otherUser: identical(otherUser, _unset)
          ? ConversationOtherUserDto(id: 'u2', firstName: firstName, photos: photos)
          : otherUser,
      lastMessageAt: lastMessageAt,
      lastMessageBody: lastMessageBody,
    );

    test('roomId uses connectionId when present, else conversation id', () {
      expect(
        MessagingMapper.mapConversationDto(
          convo(connectionId: 'cn-9'),
          currentUserId: 'me',
        ).roomId,
        'cn-9',
      );
      expect(
        MessagingMapper.mapConversationDto(convo(), currentUserId: 'me').roomId,
        'conv-1',
      );
    });

    test('null photos → null profile url; empty photos → empty string', () {
      // Pinned subtlety: the orElse builds ConversationPhotoDto(url: '').
      expect(
        MessagingMapper.mapConversationDto(
          convo(photos: null),
          currentUserId: 'me',
        ).participant.profilePhotoUrl,
        isNull,
      );
      expect(
        MessagingMapper.mapConversationDto(
          convo(photos: const []),
          currentUserId: 'me',
        ).participant.profilePhotoUrl,
        '',
      );
    });

    test('prefers the primary photo over the first', () {
      final item = MessagingMapper.mapConversationDto(
        convo(photos: const [
          ConversationPhotoDto(url: 'https://cdn/first.jpg'),
          ConversationPhotoDto(url: 'https://cdn/primary.jpg', primary: true),
        ]),
        currentUserId: 'me',
      );
      expect(item.participant.profilePhotoUrl, 'https://cdn/primary.jpg');
    });

    test("username falls back to 'User' when otherUser or firstName is null", () {
      expect(
        MessagingMapper.mapConversationDto(
          convo(firstName: null),
          currentUserId: 'me',
        ).participant.username,
        'User',
      );
      expect(
        MessagingMapper.mapConversationDto(
          convo(otherUser: null),
          currentUserId: 'me',
        ).participant.username,
        'User',
      );
    });

    test('lastMessage preview uses placeholder id/sender and null when absent', () {
      // Pinned: when present, messageId is '0' and senderId is '' (the contract).
      final present = MessagingMapper.mapConversationDto(
        convo(),
        currentUserId: 'me',
      ).lastMessage!;
      expect(present.messageId, '0');
      expect(present.senderId, '');
      expect(present.body, 'hello');

      // Missing body → null preview.
      expect(
        MessagingMapper.mapConversationDto(
          convo(lastMessageBody: null),
          currentUserId: 'me',
        ).lastMessage,
        isNull,
      );
    });
  });
}

/// Sentinel so the `convo` helper can distinguish "otherUser not passed"
/// (build a default) from "otherUser explicitly null".
const _unset = ConversationOtherUserDto(id: '__unset__');
