import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatRoomType {
  private,
  group,
}

class ChatRoomModel {
  final String id;
  final ChatRoomType type;
  final String name;
  final String? description;
  final String? photoURL;
  final List<String> participants;
  final Map<String, bool> participantsOnlineStatus;
  final String lastMessage;
  final String lastMessageSenderId;
  final String lastMessageSenderName;
  final DateTime lastMessageTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, int> unreadCounts;
  final Map<String, dynamic>? metadata;

  ChatRoomModel({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    this.photoURL,
    required this.participants,
    this.participantsOnlineStatus = const {},
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageSenderName,
    required this.lastMessageTime,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.unreadCounts = const {},
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'description': description,
      'photoURL': photoURL,
      'participants': participants,
      'participantsOnlineStatus': participantsOnlineStatus,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderName': lastMessageSenderName,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'unreadCounts': unreadCounts,
      'metadata': metadata,
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'] ?? '',
      type: ChatRoomType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => ChatRoomType.private,
      ),
      name: map['name'] ?? '',
      description: map['description'],
      photoURL: map['photoURL'],
      participants: List<String>.from(map['participants'] ?? []),
      participantsOnlineStatus: Map<String, bool>.from(map['participantsOnlineStatus'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageSenderName: map['lastMessageSenderName'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      metadata: map['metadata'],
    );
  }

  factory ChatRoomModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel.fromMap(data);
  }

  ChatRoomModel copyWith({
    String? id,
    ChatRoomType? type,
    String? name,
    String? description,
    String? photoURL,
    List<String>? participants,
    Map<String, bool>? participantsOnlineStatus,
    String? lastMessage,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    DateTime? lastMessageTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, int>? unreadCounts,
    Map<String, dynamic>? metadata,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      photoURL: photoURL ?? this.photoURL,
      participants: participants ?? this.participants,
      participantsOnlineStatus: participantsOnlineStatus ?? this.participantsOnlineStatus,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSenderName: lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      metadata: metadata ?? this.metadata,
    );
  }

  String getChatRoomId(String userId1, String userId2) {
    List<String> sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }
}
