import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:ngomna_chat/data/models/message_model.dart';

class MessageBubbleWithAvatar extends StatelessWidget {
  final Message message;
  final String? senderName; // Nom de l'expéditeur pour les groupes
  final String? avatarUrl;

  const MessageBubbleWithAvatar({
    super.key,
    required this.message,
    this.senderName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      color: Color(0xFF1F1F1F),
    );

    const senderStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF4CAF50),
    );

    final timeStyle = TextStyle(
      fontSize: 12,
      color: Colors.grey[600],
    );

    return Row(
      mainAxisAlignment:
          message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!message.isMe && avatarUrl != null) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage(avatarUrl!),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.isMe
                  ? const Color.fromARGB(255, 173, 255, 184)
                  : const Color.fromARGB(255, 232, 232, 232),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                bottomRight: Radius.circular(message.isMe ? 4 : 16),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      if (!message.isMe && senderName != null) ...[
                        TextSpan(
                          text: '$senderName\n',
                          style: senderStyle,
                        ),
                      ],
                      TextSpan(text: message.text, style: textStyle),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: SizedBox(
                          width: message.isMe ? 65 : 42,
                          height: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(message.getFormattedTime(), style: timeStyle),
                      if (message.isMe) ...[
                        const SizedBox(width: 4),
                        _getStatusIcon(message.status),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
    }
  }
}
