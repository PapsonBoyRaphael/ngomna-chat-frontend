import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: chat.isUnread ? const Color(0xFFE8F5E9) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 14),
            _buildContent(),
            _buildTime(),
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
          Text(
            chat.lastMessage?.content ?? 'No message',
            style: TextStyle(
              fontSize: 16,
              color: chat.isUnread
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF7A7A7A),
              fontWeight: FontWeight.w400,
              fontFamily: 'Roboto',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTime() {
    return Text(
      DateFormatter.formatMessageDate(chat.lastMessageAt),
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF4CAF50),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
