import 'package:ngomna_chat/data/models/message_model.dart';
import 'auth_repository.dart';

class BroadcastRepository {
  final AuthRepository authRepository;

  BroadcastRepository(this.authRepository);

  Future<List<Message>> getBroadcastMessages(String broadcastId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Les broadcasts n'ont que des messages sortants
    final user = await authRepository.getCurrentUser();
    return [
      Message(
        id: '1',
        conversationId: broadcastId,
        senderId: user?.matricule ?? 'me',
        content: "You are looking in the right place\nI am a UI/UX designer",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.delivered,
        isMe: true,
      ),
      Message(
        id: '2',
        conversationId: broadcastId,
        senderId: user?.matricule ?? 'me',
        content: "I will call you to discuss",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MessageStatus.read,
        isMe: true,
      ),
    ];
  }

  Future<Message> sendBroadcastMessage(String broadcastId, String text) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final user = await authRepository.getCurrentUser();

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: broadcastId,
      senderId: user?.matricule ?? 'me',
      content: text,
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
