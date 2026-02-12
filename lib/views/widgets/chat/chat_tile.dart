import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'package:ngomna_chat/core/constants/app_fonts.dart';
import 'package:ngomna_chat/core/utils/date_formatter.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  Icon _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(
          MaterialCommunityIcons.clock_outline,
          size: 14,
          color: Colors.grey,
        );
      case MessageStatus.sent:
        return const Icon(
          MaterialCommunityIcons.check,
          size: 18,
          color: Colors.grey,
        );
      case MessageStatus.delivered:
        return const Icon(
          MaterialCommunityIcons.check_all,
          size: 18,
          color: Colors.grey,
        );
      case MessageStatus.read:
        return const Icon(
          MaterialCommunityIcons.check_all,
          size: 18,
          color: Color.fromARGB(255, 36, 148, 239),
        );
      case MessageStatus.failed:
        return const Icon(
          MaterialCommunityIcons.alert_circle_outline,
          size: 18,
          color: Colors.red,
        );
      default:
        return const Icon(
          MaterialCommunityIcons.help_circle_outline,
          size: 18,
          color: Colors.grey,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        '🎨 [ChatTile] Build - ${chat.displayName}: lastMessage="${chat.lastMessage?.content}"');
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 14),
            _buildContent(),
            const SizedBox(width: 5),
            _buildTimeAndBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFFEDEDED),
          child: chat.type == ChatType.broadcast
              ? Image.asset(
                  (chat.avatarUrl != null && chat.avatarUrl!.isNotEmpty)
                      ? chat.avatarUrl!
                      : 'assets/avatars/group.png',
                  width: 40,
                  height: 40,
                )
              : null,
          backgroundImage: chat.type != ChatType.broadcast
              ? AssetImage(
                  (chat.avatarUrl != null && chat.avatarUrl!.isNotEmpty)
                      ? chat.avatarUrl!
                      : 'assets/avatars/default_avatar.png',
                )
              : null,
        ),
        if (chat.isOnline)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chat.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: chat.displayName == chat.displayName.toUpperCase()
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: const Color(0xFF1F1F1F),
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (chat.lastMessage != null &&
                  _isCurrentUserMessage(chat.lastMessage!)) ...[
                _getStatusIcon(chat.lastMessage!.status),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  (chat.lastMessage?.content ?? '').replaceAll('\n', ' '),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF7A7A7A),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Roboto',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTime() {
    return Text(
      LiveDateFormatter.formatForChatList(chat.lastMessageAt),
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF4CAF50),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTimeAndBadge() {
    // Utiliser le getter unreadCount qui retourne seulement le count de l'utilisateur actuel
    final totalUnread = chat.unreadCount;

    print(
        '🔍 [ChatTile._buildTimeAndBadge] ${chat.displayName}: totalUnread=$totalUnread');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ⏰ Heure
        Text(
          LiveDateFormatter.formatForChatList(chat.lastMessageAt),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        // 🔴 Badge avec nombre de messages non lus
        if (totalUnread > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              totalUnread > 99 ? '99+' : '$totalUnread',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  bool _isCurrentUserMessage(LastMessage message) {
    final StorageService storageService = StorageService();
    final currentUser = storageService.getUser();
    if (currentUser == null) return false;

    return message.senderId == currentUser.matricule ||
        message.senderId == currentUser.id;
  }
}
