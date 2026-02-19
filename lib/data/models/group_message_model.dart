import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class GroupMessage extends Message {
  final User sender; // Informations complètes de l'expéditeur

  GroupMessage({
    required super.id,
    super.temporaryId,
    required super.conversationId,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.createdAt,
    super.status,
    super.isMe,
    required this.sender,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['_id'] ?? json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'] ?? '',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at'] ?? json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      isMe: json['is_me'] ?? false,
      sender: User.fromJson(json['sender']),
    );
  }
}
