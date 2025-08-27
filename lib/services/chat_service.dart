import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Uuid _uuid = Uuid();

  // Create or get existing chat room
  static Future<String> createOrGetChatRoom({
    required String otherUserId,
    required UserModel otherUser,
    required UserModel currentUser,
  }) async {
    try {
      String chatRoomId = _generateChatRoomId(currentUser.id, otherUserId);

      DocumentSnapshot chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) {
        // Create new chat room
        ChatRoomModel newChatRoom = ChatRoomModel(
          id: chatRoomId,
          type: ChatRoomType.private,
          name: otherUser.displayName,
          participants: [currentUser.id, otherUserId],
          participantsOnlineStatus: {
            currentUser.id: currentUser.isOnline,
            otherUserId: otherUser.isOnline,
          },
          lastMessage: '',
          lastMessageSenderId: '',
          lastMessageSenderName: '',
          lastMessageTime: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: currentUser.id,
        );

        await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .set(newChatRoom.toMap());
      }

      return chatRoomId;
    } catch (e) {
      throw Exception('Failed to create/get chat room: $e');
    }
  }

  // Send message
  static Future<void> sendMessage({
    required String chatRoomId,
    required String content,
    required MessageType type,
    String? imageUrl,
    String? fileName,
    String? fileUrl,
  }) async {
    try {
      String currentUserId = AuthService.currentUserId;
      if (currentUserId.isEmpty) {
        throw Exception('User not logged in');
      }

      UserModel? currentUser = await AuthService.getUserData(currentUserId);
      if (currentUser == null) {
        throw Exception('Current user data not found');
      }

      String messageId = _uuid.v4();

      MessageModel message = MessageModel(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: currentUserId,
        senderName: currentUser.displayName,
        senderPhotoURL: currentUser.photoURL,
        content: content,
        type: type,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        fileName: fileName,
        fileUrl: fileUrl,
      );

      // Add message to Firestore
      await _firestore
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update message status to sent
      await _firestore
          .collection('messages')
          .doc(messageId)
          .update({'status': MessageStatus.sent.toString().split('.').last});

      // Update chat room with last message info
      await _updateChatRoomLastMessage(
        chatRoomId: chatRoomId,
        lastMessage: _getDisplayContent(message),
        senderId: currentUserId,
        senderName: currentUser.displayName,
        timestamp: message.timestamp,
      );

      // Send push notification to other participants
      await _sendMessageNotification(chatRoomId, message, currentUser);

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages stream for a chat room
  static Stream<List<MessageModel>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromDocumentSnapshot(doc))
              .toList();
        });
  }

  // Load more messages (pagination)
  static Future<List<MessageModel>> loadMoreMessages({
    required String chatRoomId,
    required DateTime lastMessageTime,
    int limit = 20,
  }) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('messages')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('timestamp', descending: true)
          .startAfter([Timestamp.fromDate(lastMessageTime)])
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => MessageModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load more messages: $e');
    }
  }

  // Get chat rooms stream for current user
  static Stream<List<ChatRoomModel>> getChatRoomsStream() {
    String currentUserId = AuthService.currentUserId;
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatRoomModel.fromDocumentSnapshot(doc))
              .toList();
        });
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead({
    required String chatRoomId,
    required List<String> messageIds,
  }) async {
    try {
      String currentUserId = AuthService.currentUserId;
      if (currentUserId.isEmpty) return;

      WriteBatch batch = _firestore.batch();

      // Update message status to read
      for (String messageId in messageIds) {
        DocumentReference messageRef = _firestore
            .collection('messages')
            .doc(messageId);

        batch.update(messageRef, {
          'status': MessageStatus.read.toString().split('.').last,
          'readBy': FieldValue.arrayUnion([currentUserId]),
        });
      }

      // Update unread count in chat room
      DocumentReference chatRoomRef = _firestore
          .collection('chatRooms')
          .doc(chatRoomId);

      batch.update(chatRoomRef, {
        'unreadCounts.$currentUserId': 0,
      });

      await batch.commit();
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }

  // Update typing status
  static Future<void> updateTypingStatus({
    required String chatRoomId,
    required bool isTyping,
  }) async {
    try {
      String currentUserId = AuthService.currentUserId;
      if (currentUserId.isEmpty) return;

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('typing')
          .doc(currentUserId)
          .set({
            'isTyping': isTyping,
            'timestamp': Timestamp.now(),
          });

      // Auto-remove typing status after 3 seconds
      if (isTyping) {
        Future.delayed(const Duration(seconds: 3), () {
          updateTypingStatus(chatRoomId: chatRoomId, isTyping: false);
        });
      }
    } catch (e) {
      print('Failed to update typing status: $e');
    }
  }

  // Get typing status stream
  static Stream<List<String>> getTypingStatusStream(String chatRoomId) {
    String currentUserId = AuthService.currentUserId;
    
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
          List<String> typingUsers = [];
          DateTime now = DateTime.now();
          
          for (var doc in snapshot.docs) {
            if (doc.id != currentUserId) {
              Map<String, dynamic> data = doc.data();
              bool isTyping = data['isTyping'] ?? false;
              Timestamp timestamp = data['timestamp'];
              
              // Remove typing status if it's older than 5 seconds
              if (isTyping && now.difference(timestamp.toDate()).inSeconds < 5) {
                typingUsers.add(doc.id);
              }
            }
          }
          
          return typingUsers;
        });
  }

  // Delete message
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Update message
  static Future<void> updateMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      await _firestore
          .collection('messages')
          .doc(messageId)
          .update({
            'content': newContent,
            'metadata.edited': true,
            'metadata.editedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  // Search messages
  static Future<List<MessageModel>> searchMessages({
    required String chatRoomId,
    required String searchQuery,
    int limit = 20,
  }) async {
    try {
      // Note: This is a simple search. For production, consider using
      // Algolia or another search service for better text search capabilities
      QuerySnapshot query = await _firestore
          .collection('messages')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('content', isGreaterThanOrEqualTo: searchQuery)
          .where('content', isLessThan: '${searchQuery}z')
          .orderBy('content')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => MessageModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // Helper methods
  static String _generateChatRoomId(String userId1, String userId2) {
    List<String> sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  static Future<void> _updateChatRoomLastMessage({
    required String chatRoomId,
    required String lastMessage,
    required String senderId,
    required String senderName,
    required DateTime timestamp,
  }) async {
    try {
      DocumentSnapshot chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (chatRoomDoc.exists) {
        ChatRoomModel chatRoom = ChatRoomModel.fromDocumentSnapshot(chatRoomDoc);
        
        // Update unread counts for other participants
        Map<String, int> newUnreadCounts = Map.from(chatRoom.unreadCounts);
        for (String participantId in chatRoom.participants) {
          if (participantId != senderId) {
            newUnreadCounts[participantId] = (newUnreadCounts[participantId] ?? 0) + 1;
          }
        }

        await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .update({
              'lastMessage': lastMessage,
              'lastMessageSenderId': senderId,
              'lastMessageSenderName': senderName,
              'lastMessageTime': Timestamp.fromDate(timestamp),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
              'unreadCounts': newUnreadCounts,
            });
      }
    } catch (e) {
      print('Failed to update chat room last message: $e');
    }
  }

  static String _getDisplayContent(MessageModel message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📸 Photo';
      case MessageType.file:
        return '📄 ${message.fileName ?? 'File'}';
      default:
        return message.content;
    }
  }

  static Future<void> _sendMessageNotification(
    String chatRoomId,
    MessageModel message,
    UserModel sender,
  ) async {
    try {
      // Get chat room to find other participants
      DocumentSnapshot chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (chatRoomDoc.exists) {
        ChatRoomModel chatRoom = ChatRoomModel.fromDocumentSnapshot(chatRoomDoc);
        
        // Get other participants' FCM tokens
        List<String> otherParticipants = chatRoom.participants
            .where((id) => id != sender.id)
            .toList();

        for (String participantId in otherParticipants) {
          UserModel? participant = await AuthService.getUserData(participantId);
          if (participant?.fcmToken != null) {
            await NotificationService.sendMessageNotification(
              token: participant!.fcmToken!,
              senderName: sender.displayName,
              messageContent: _getDisplayContent(message),
              chatRoomId: chatRoomId,
            );
          }
        }
      }
    } catch (e) {
      print('Failed to send message notification: $e');
    }
  }
}
