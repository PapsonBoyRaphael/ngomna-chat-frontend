import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class GroupMessage extends Message {
  final User sender; // Informations complètes de l'expéditeur

  GroupMessage({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.text,
    required super.timestamp,
    super.status,
    super.isMe,
    required this.sender,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
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
      sender: User.fromJson(json['sender']),
    );
  }
}
