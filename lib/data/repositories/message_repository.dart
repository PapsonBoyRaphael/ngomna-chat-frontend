import 'package:ngomna_chat/data/models/message_model.dart';

class MessageRepository {
  // Mock data pour les messages
  Future<List<Message>> getMessages(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Message(
        id: '1',
        chatId: chatId,
        senderId: 'user2',
        text: "I'm looking for a designer",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
        isMe: false,
      ),
      Message(
        id: '2',
        chatId: chatId,
        senderId: 'user2',
        text: "UI/UX",
        timestamp:
            DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
        status: MessageStatus.read,
        isMe: false,
      ),
      Message(
        id: '3',
        chatId: chatId,
        senderId: 'me',
        text: "You are looking in the right place\nI am a UI/UX designer",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MessageStatus.read,
        isMe: true,
      ),
      // Ajoutez d'autres messages...
    ];
  }

  Future<Message> sendMessage(String chatId, String text) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isMe: true,
    );
  }
}
