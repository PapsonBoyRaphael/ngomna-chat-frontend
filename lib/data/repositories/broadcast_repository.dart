import 'package:ngomna_chat/data/models/message_model.dart';

class BroadcastRepository {
  Future<List<Message>> getBroadcastMessages(String broadcastId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Les broadcasts n'ont que des messages sortants
    return [
      Message(
        id: '1',
        chatId: broadcastId,
        senderId: 'me',
        text: "You are looking in the right place\nI am a UI/UX designer",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.delivered,
        isMe: true,
      ),
      Message(
        id: '2',
        chatId: broadcastId,
        senderId: 'me',
        text: "I will call you to discuss",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MessageStatus.read,
        isMe: true,
      ),
    ];
  }

  Future<Message> sendBroadcastMessage(String broadcastId, String text) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: broadcastId,
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      isMe: true,
    );
  }

  // Récupérer la liste des destinataires du broadcast
  Future<List<String>> getBroadcastRecipients(String broadcastId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      'Mrs. Aichatou Bello',
      'Mr. Ngah Owona',
      'Mrs. Angu Telma',
      // etc...
    ];
  }
}
