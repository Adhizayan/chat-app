import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/chat_room_model.dart';
import 'package:chat_app/utils/app_utils.dart';

void main() {
  group('Chat App Models Tests', () {
    test('UserModel creation and serialization', () {
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        phoneNumber: '+1234567890',
        photoURL: null,
        isOnline: true,
        lastSeen: DateTime.now(),
        deviceTokens: ['token1', 'token2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.isOnline, true);
      expect(user.deviceTokens.length, 2);

      // Test serialization
      final json = user.toJson();
      expect(json['id'], 'test-id');
      expect(json['email'], 'test@example.com');
      expect(json['displayName'], 'Test User');

      // Test deserialization
      final userFromJson = UserModel.fromJson(json);
      expect(userFromJson.id, user.id);
      expect(userFromJson.email, user.email);
      expect(userFromJson.displayName, user.displayName);
    });

    test('MessageModel creation and serialization', () {
      final message = MessageModel(
        id: 'msg-id',
        chatRoomId: 'chat-room-id',
        senderId: 'sender-id',
        content: 'Hello, world!',
        type: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
        editedAt: null,
        replyToMessageId: null,
        attachmentUrl: null,
        attachmentType: null,
        reactions: {},
      );

      expect(message.id, 'msg-id');
      expect(message.content, 'Hello, world!');
      expect(message.type, MessageType.text);
      expect(message.isRead, false);

      // Test serialization
      final json = message.toJson();
      expect(json['id'], 'msg-id');
      expect(json['content'], 'Hello, world!');
      expect(json['type'], 'text');

      // Test deserialization
      final messageFromJson = MessageModel.fromJson(json);
      expect(messageFromJson.id, message.id);
      expect(messageFromJson.content, message.content);
      expect(messageFromJson.type, message.type);
    });

    test('ChatRoomModel creation and methods', () {
      final chatRoom = ChatRoomModel(
        id: 'chat-room-id',
        name: 'Test Chat',
        participants: ['user1', 'user2'],
        participantsOnlineStatus: {
          'user1': true,
          'user2': false,
        },
        lastMessage: null,
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {'user1': 0, 'user2': 3},
        isGroup: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(chatRoom.id, 'chat-room-id');
      expect(chatRoom.participants.length, 2);
      expect(chatRoom.isGroup, false);

      // Test getOtherParticipantId method
      final otherParticipant = chatRoom.getOtherParticipantId('user1');
      expect(otherParticipant, 'user2');

      // Test serialization
      final json = chatRoom.toJson();
      expect(json['id'], 'chat-room-id');
      expect(json['participants'], ['user1', 'user2']);
      expect(json['isGroup'], false);
    });
  });

  group('App Utils Tests', () {
    test('Date formatting', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));

      // Test formatRelativeTime
      final todayFormatted = AppUtils.formatRelativeTime(now);
      final yesterdayFormatted = AppUtils.formatRelativeTime(yesterday);
      final lastWeekFormatted = AppUtils.formatRelativeTime(lastWeek);

      expect(todayFormatted, isNotEmpty);
      expect(yesterdayFormatted, contains('yesterday'));
      expect(lastWeekFormatted, isNotEmpty);
    });

    test('Phone number formatting', () {
      const phoneNumber = '+1234567890';
      final formatted = AppUtils.formatPhoneForDisplay(phoneNumber);
      
      expect(formatted, isNotEmpty);
      expect(formatted, contains('234'));
    });

    test('Email validation', () {
      expect(AppUtils.isValidEmail('test@example.com'), true);
      expect(AppUtils.isValidEmail('invalid-email'), false);
      expect(AppUtils.isValidEmail(''), false);
    });
  });
}
