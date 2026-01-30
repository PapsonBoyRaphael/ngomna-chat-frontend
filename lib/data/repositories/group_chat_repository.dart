import 'package:ngomna_chat/data/models/group_message_model.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class GroupChatRepository {
  Future<List<GroupMessage>> getGroupMessages(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data avec différents expéditeurs
    return [
      GroupMessage(
        id: '1',
        conversationId: groupId,
        senderId: 'user2',
        receiverId: groupId, // Pour les groupes, receiverId = groupId
        content: "I'm looking for a designer",
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isMe: false,
        sender: User(
          id: 'user2',
          matricule: 'user2', // Utilisation de l'ID comme matricule par défaut
          nom: 'Mrs.', // Extraction du prénom
          prenom: 'Aichatou Bello', // Extraction du nom
          avatarUrl: 'assets/avatars/avatar.png',
          isOnline: true,
        ),
      ),
      GroupMessage(
        id: '2',
        conversationId: groupId,
        senderId: 'user3',
        receiverId: groupId,
        content: "UI/UX",
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
        isMe: false,
        sender: User(
          id: 'user3',
          matricule: 'user3', // Utilisation de l'ID comme matricule par défaut
          nom: 'Mr.', // Extraction du prénom
          prenom: 'John Doe', // Extraction du nom
          avatarUrl: 'assets/avatars/avatar2.png',
          isOnline: false,
        ),
      ),
      GroupMessage(
        id: '3',
        conversationId: groupId,
        senderId: 'me',
        receiverId: groupId,
        content: "You are looking in the right place\nI am a UI/UX designer",
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isMe: true,
        sender: User(
          id: 'me',
          matricule: 'me', // Utilisation de l'ID comme matricule par défaut
          nom: 'Me', // Extraction du prénom
          prenom: '', // Extraction du nom
          avatarUrl: 'assets/avatars/avatar.png',
          isOnline: true,
        ),
      ),
    ];
  }

  Future<GroupMessage> sendGroupMessage(String groupId, String text) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return GroupMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: groupId,
      senderId: 'me',
      receiverId: groupId, // Pour les groupes, receiverId = groupId
      content: text,
      createdAt: DateTime.now(),
      isMe: true,
      sender: User(
        id: 'me',
        matricule: 'me', // Utilisation de l'ID comme matricule par défaut
        nom: 'Me', // Extraction du prénom
        prenom: '', // Extraction du nom
        avatarUrl: 'assets/avatars/avatar.png',
        isOnline: true,
      ),
    );
  }
}
