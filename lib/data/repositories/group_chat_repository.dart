import 'package:ngomna_chat/data/models/group_message_model.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class GroupChatRepository {
  Future<List<GroupMessage>> getGroupMessages(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data avec différents expéditeurs
    return [
      GroupMessage(
        id: '1',
        chatId: groupId,
        senderId: 'user2',
        text: "I'm looking for a designer",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isMe: false,
        sender: User(
          id: 'user2',
          name: 'Mrs. Aichatou Bello',
          avatarUrl: 'assets/avatars/avatar.png',
          isOnline: true,
        ),
      ),
      GroupMessage(
        id: '2',
        chatId: groupId,
        senderId: 'user3',
        text: "UI/UX",
        timestamp:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
        isMe: false,
        sender: User(
          id: 'user3',
          name: 'Mr. Ngah Owona',
          avatarUrl: 'assets/avatars/avatar.png',
          isOnline: false,
        ),
      ),
      GroupMessage(
        id: '3',
        chatId: groupId,
        senderId: 'me',
        text: "You are looking in the right place\nI am a UI/UX designer",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isMe: true,
        sender: User(
          id: 'me',
          name: 'Me',
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
      chatId: groupId,
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      sender: User(
        id: 'me',
        name: 'Me',
        avatarUrl: 'assets/avatars/avatar.png',
        isOnline: true,
      ),
    );
  }
}
