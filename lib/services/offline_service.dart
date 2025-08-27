import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';

class OfflineService {
  static const String _messagesKey = 'offline_messages';
  static const String _chatRoomsKey = 'cached_chat_rooms';
  static const String _contactsKey = 'cached_contacts';
  static const String _pendingMessagesKey = 'pending_messages';

  // Check network connectivity
  static Future<bool> isConnected() async {
    try {
      List<ConnectivityResult> results = await Connectivity().checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  // Listen to connectivity changes
  static Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map((results) {
      return results.any((result) => result != ConnectivityResult.none);
    });
  }

  // Cache messages locally
  static Future<void> cacheMessages(String chatRoomId, List<MessageModel> messages) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      Map<String, dynamic> cachedData = {};
      String? existingData = prefs.getString(_messagesKey);
      if (existingData != null) {
        cachedData = jsonDecode(existingData);
      }

      // Convert messages to JSON
      List<Map<String, dynamic>> messageList = messages.map((msg) => msg.toMap()).toList();
      cachedData[chatRoomId] = messageList;

      await prefs.setString(_messagesKey, jsonEncode(cachedData));
    } catch (e) {
      print('Failed to cache messages: $e');
    }
  }

  // Get cached messages
  static Future<List<MessageModel>> getCachedMessages(String chatRoomId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_messagesKey);
      
      if (cachedData == null) return [];

      Map<String, dynamic> allCachedMessages = jsonDecode(cachedData);
      List<dynamic>? messageList = allCachedMessages[chatRoomId];
      
      if (messageList == null) return [];

      return messageList
          .map((msgJson) => MessageModel.fromMap(msgJson))
          .toList();
    } catch (e) {
      print('Failed to get cached messages: $e');
      return [];
    }
  }

  // Cache chat rooms
  static Future<void> cacheChatRooms(List<ChatRoomModel> chatRooms) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      List<Map<String, dynamic>> chatRoomList = chatRooms.map((room) => room.toMap()).toList();
      await prefs.setString(_chatRoomsKey, jsonEncode(chatRoomList));
    } catch (e) {
      print('Failed to cache chat rooms: $e');
    }
  }

  // Get cached chat rooms
  static Future<List<ChatRoomModel>> getCachedChatRooms() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_chatRoomsKey);
      
      if (cachedData == null) return [];

      List<dynamic> chatRoomList = jsonDecode(cachedData);
      return chatRoomList
          .map((roomJson) => ChatRoomModel.fromMap(roomJson))
          .toList();
    } catch (e) {
      print('Failed to get cached chat rooms: $e');
      return [];
    }
  }

  // Cache contacts
  static Future<void> cacheContacts(List<UserModel> contacts) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      List<Map<String, dynamic>> contactList = contacts.map((contact) => contact.toMap()).toList();
      await prefs.setString(_contactsKey, jsonEncode(contactList));
    } catch (e) {
      print('Failed to cache contacts: $e');
    }
  }

  // Get cached contacts
  static Future<List<UserModel>> getCachedContacts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_contactsKey);
      
      if (cachedData == null) return [];

      List<dynamic> contactList = jsonDecode(cachedData);
      return contactList
          .map((contactJson) => UserModel.fromMap(contactJson))
          .toList();
    } catch (e) {
      print('Failed to get cached contacts: $e');
      return [];
    }
  }

  // Store pending messages (to be sent when online)
  static Future<void> addPendingMessage(MessageModel message) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      List<Map<String, dynamic>> pendingMessages = [];
      String? existingData = prefs.getString(_pendingMessagesKey);
      if (existingData != null) {
        List<dynamic> existing = jsonDecode(existingData);
        pendingMessages = existing.cast<Map<String, dynamic>>();
      }

      pendingMessages.add(message.toMap());
      await prefs.setString(_pendingMessagesKey, jsonEncode(pendingMessages));
    } catch (e) {
      print('Failed to add pending message: $e');
    }
  }

  // Get pending messages
  static Future<List<MessageModel>> getPendingMessages() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_pendingMessagesKey);
      
      if (cachedData == null) return [];

      List<dynamic> messageList = jsonDecode(cachedData);
      return messageList
          .map((msgJson) => MessageModel.fromMap(msgJson))
          .toList();
    } catch (e) {
      print('Failed to get pending messages: $e');
      return [];
    }
  }

  // Remove pending message
  static Future<void> removePendingMessage(String messageId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_pendingMessagesKey);
      
      if (cachedData == null) return;

      List<dynamic> messageList = jsonDecode(cachedData);
      messageList.removeWhere((msgJson) => msgJson['id'] == messageId);
      
      await prefs.setString(_pendingMessagesKey, jsonEncode(messageList));
    } catch (e) {
      print('Failed to remove pending message: $e');
    }
  }

  // Clear all pending messages
  static Future<void> clearPendingMessages() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingMessagesKey);
    } catch (e) {
      print('Failed to clear pending messages: $e');
    }
  }

  // Clear all cached data
  static Future<void> clearAllCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_messagesKey);
      await prefs.remove(_chatRoomsKey);
      await prefs.remove(_contactsKey);
      await prefs.remove(_pendingMessagesKey);
    } catch (e) {
      print('Failed to clear cache: $e');
    }
  }

  // Get cache size (approximate)
  static Future<String> getCacheSize() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      int totalSize = 0;
      
      String? messages = prefs.getString(_messagesKey);
      String? chatRooms = prefs.getString(_chatRoomsKey);
      String? contacts = prefs.getString(_contactsKey);
      String? pending = prefs.getString(_pendingMessagesKey);
      
      if (messages != null) totalSize += messages.length;
      if (chatRooms != null) totalSize += chatRooms.length;
      if (contacts != null) totalSize += contacts.length;
      if (pending != null) totalSize += pending.length;

      // Convert bytes to readable format
      if (totalSize < 1024) {
        return '$totalSize B';
      } else if (totalSize < 1024 * 1024) {
        return '${(totalSize / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      print('Failed to calculate cache size: $e');
      return 'Unknown';
    }
  }

  // Sync pending messages when online
  static Future<void> syncPendingMessages() async {
    try {
      bool connected = await isConnected();
      if (!connected) return;

      List<MessageModel> pendingMessages = await getPendingMessages();
      
      // TODO: Implement actual syncing with ChatService
      // For now, just clear pending messages
      if (pendingMessages.isNotEmpty) {
        await clearPendingMessages();
        print('Synced ${pendingMessages.length} pending messages');
      }
    } catch (e) {
      print('Failed to sync pending messages: $e');
    }
  }

  // App settings
  static Future<void> setContactSyncEnabled(bool enabled) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('contact_sync_enabled', enabled);
    } catch (e) {
      print('Failed to set contact sync setting: $e');
    }
  }

  static Future<bool> isContactSyncEnabled() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('contact_sync_enabled') ?? true;
    } catch (e) {
      print('Failed to get contact sync setting: $e');
      return true;
    }
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
    } catch (e) {
      print('Failed to set notifications setting: $e');
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notifications_enabled') ?? true;
    } catch (e) {
      print('Failed to get notifications setting: $e');
      return true;
    }
  }

  static Future<void> setLastContactSync(DateTime timestamp) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_contact_sync', timestamp.toIso8601String());
    } catch (e) {
      print('Failed to set last contact sync: $e');
    }
  }

  static Future<DateTime?> getLastContactSync() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? timestamp = prefs.getString('last_contact_sync');
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      print('Failed to get last contact sync: $e');
      return null;
    }
  }
}
