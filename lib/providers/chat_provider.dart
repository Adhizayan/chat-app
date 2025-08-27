import 'package:flutter/foundation.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/contact_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatRoomModel> _chatRooms = [];
  List<UserModel> _contacts = [];
  bool _isLoading = false;
  String? _error;

  List<ChatRoomModel> get chatRooms => _chatRooms;
  List<UserModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize chat provider
  void initialize() {
    _loadChatRooms();
    _loadContacts();
  }

  // Load chat rooms
  void _loadChatRooms() {
    ChatService.getChatRoomsStream().listen(
      (chatRooms) {
        _chatRooms = chatRooms;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load chat rooms: $error';
        notifyListeners();
      },
    );
  }

  // Load contacts
  Future<void> _loadContacts() async {
    try {
      _isLoading = true;
      notifyListeners();

      List<UserModel> contacts = await ContactService.findContactUsers();
      _contacts = contacts;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load contacts: $e';
      notifyListeners();
    }
  }

  // Refresh contacts
  Future<void> refreshContacts() async {
    await _loadContacts();
  }

  // Create or get chat room
  Future<String?> createOrGetChatRoom({
    required String otherUserId,
    required UserModel otherUser,
    required UserModel currentUser,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String chatRoomId = await ChatService.createOrGetChatRoom(
        otherUserId: otherUserId,
        otherUser: otherUser,
        currentUser: currentUser,
      );

      _isLoading = false;
      notifyListeners();

      return chatRoomId;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create chat room: $e';
      notifyListeners();
      return null;
    }
  }

  // Send message
  Future<bool> sendMessage({
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? fileName,
    String? fileUrl,
  }) async {
    try {
      await ChatService.sendMessage(
        chatRoomId: chatRoomId,
        content: content,
        type: type,
        imageUrl: imageUrl,
        fileName: fileName,
        fileUrl: fileUrl,
      );

      return true;
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required List<String> messageIds,
  }) async {
    try {
      await ChatService.markMessagesAsRead(
        chatRoomId: chatRoomId,
        messageIds: messageIds,
      );
    } catch (e) {
      _error = 'Failed to mark messages as read: $e';
      notifyListeners();
    }
  }

  // Update typing status
  Future<void> updateTypingStatus({
    required String chatRoomId,
    required bool isTyping,
  }) async {
    try {
      await ChatService.updateTypingStatus(
        chatRoomId: chatRoomId,
        isTyping: isTyping,
      );
    } catch (e) {
      // Don't show error for typing status failures
      print('Failed to update typing status: $e');
    }
  }

  // Search messages
  Future<List<MessageModel>> searchMessages({
    required String chatRoomId,
    required String searchQuery,
  }) async {
    try {
      return await ChatService.searchMessages(
        chatRoomId: chatRoomId,
        searchQuery: searchQuery,
      );
    } catch (e) {
      _error = 'Failed to search messages: $e';
      notifyListeners();
      return [];
    }
  }

  // Get chat room by ID
  ChatRoomModel? getChatRoomById(String chatRoomId) {
    try {
      return _chatRooms.firstWhere((room) => room.id == chatRoomId);
    } catch (e) {
      return null;
    }
  }

  // Get contact by ID
  UserModel? getContactById(String userId) {
    try {
      return _contacts.firstWhere((contact) => contact.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Get unread count for all chats
  int getTotalUnreadCount(String currentUserId) {
    int totalUnread = 0;
    for (ChatRoomModel room in _chatRooms) {
      totalUnread += room.getUnreadCount(currentUserId);
    }
    return totalUnread;
  }

  // Get recent chats (limit to 10)
  List<ChatRoomModel> getRecentChats() {
    List<ChatRoomModel> sortedRooms = List.from(_chatRooms);
    sortedRooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return sortedRooms.take(10).toList();
  }

  // Filter chat rooms by search query
  List<ChatRoomModel> filterChatRooms(String query) {
    if (query.isEmpty) return _chatRooms;

    return _chatRooms.where((room) {
      return room.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Filter contacts by search query
  List<UserModel> filterContacts(String query) {
    if (query.isEmpty) return _contacts;

    return _contacts.where((contact) {
      String displayName = ContactService.getDisplayName(contact);
      return displayName.toLowerCase().contains(query.toLowerCase()) ||
          contact.email.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    super.dispose();
  }
}
