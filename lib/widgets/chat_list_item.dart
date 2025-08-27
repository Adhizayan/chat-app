import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/contact_service.dart';
import '../screens/chat_screen.dart';

class ChatListItem extends StatelessWidget {
  final ChatRoomModel chatRoom;

  const ChatListItem({
    super.key,
    required this.chatRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUserId = authProvider.currentUser?.id ?? '';
        final otherParticipantId = chatRoom.getOtherParticipantId(currentUserId);
        final unreadCount = chatRoom.getUnreadCount(currentUserId);
        final isOnline = chatRoom.participantsOnlineStatus[otherParticipantId] ?? false;

        return FutureBuilder<UserModel?>(
          future: AuthService.getUserData(otherParticipantId),
          builder: (context, snapshot) {
            final otherUser = snapshot.data;
            final displayName = otherUser != null 
                ? ContactService.getDisplayName(otherUser)
                : chatRoom.name;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              elevation: 0,
              color: Colors.transparent,
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatRoom: chatRoom,
                        otherUser: otherUser,
                      ),
                    ),
                  );
                },
                leading: _buildAvatar(context, otherUser, isOnline),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTimestamp(chatRoom.lastMessageTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: unreadCount > 0 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    if (chatRoom.lastMessageSenderId == currentUserId) ...[
                      Icon(
                        Icons.done_all,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        chatRoom.lastMessage.isNotEmpty 
                            ? chatRoom.lastMessage 
                            : 'No messages yet',
                        style: TextStyle(
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          color: unreadCount > 0 
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, UserModel? user, bool isOnline) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primary,
          backgroundImage: user?.photoURL != null 
              ? NetworkImage(user!.photoURL!) 
              : null,
          child: user?.photoURL == null
              ? Text(
                  _getInitials(user?.displayName ?? chatRoom.name),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Same day - show time
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEE').format(timestamp);
    } else if (difference.inDays < 365) {
      // This year - show month and day
      return DateFormat('MMM dd').format(timestamp);
    } else {
      // Older than a year
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }
}
