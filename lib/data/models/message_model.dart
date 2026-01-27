enum MessageStatus { sending, sent, delivered, read }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isMe;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isMe = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      isMe: json['is_me'] ?? false,
    );
  }

  Message copyWith({MessageStatus? status}) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      timestamp: timestamp,
      status: status ?? this.status,
      isMe: isMe,
    );
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
