import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';

class ChatRepository {
  // Mock data (sera remplacé par API plus tard)
  Future<List<Chat>> getChats() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Chat(
        id: '1',
        name: 'Mrs. Aichatou Bello',
        lastMessage: 'ok done ...',
        time: '1 hr',
        isOnline: true,
        isUnread: false,
        avatarUrl: AppAssets.avatar,
        type: ChatType.personal,
      ),
      Chat(
        id: '2',
        name: 'NGOMNA PRESENTATION',
        lastMessage: 'Mrs. Aichatou Bello',
        time: '2 hr',
        isOnline: true,
        isUnread: false,
        avatarUrl: AppAssets.group,
        type: ChatType.group,
      ),
      Chat(
        id: '3',
        name: 'Mrs. Sheina Tchuente',
        lastMessage: 'hahahahaha...',
        time: '12 hr',
        isOnline: false,
        isUnread: false,
        avatarUrl: AppAssets.avatar,
        type: ChatType.personal,
      ),
      Chat(
        id: '4',
        name: 'MINFI PROJECT',
        lastMessage: 'Mrs. Angu Telma',
        time: '2 hr',
        isOnline: true,
        isUnread: false,
        avatarUrl: AppAssets.group,
        type: ChatType.group,
      ),
      Chat(
        id: '5',
        name: 'Mr. Ngah Owona',
        lastMessage: 'good job',
        time: '6 hr',
        isOnline: false,
        isUnread: false,
        avatarUrl: AppAssets.avatar,
        type: ChatType.personal,
      ),
      Chat(
        id: '6',
        name: 'Mrs. Angu Telma',
        lastMessage: 'great',
        time: '5 hr',
        isOnline: false,
        isUnread: false,
        avatarUrl: AppAssets.avatar,
        type: ChatType.personal,
      ),
      Chat(
        id: '7',
        name: 'Broadcast',
        lastMessage: 'This is a broadcast message',
        time: 'Just now',
        isOnline: false,
        isUnread: false,
        avatarUrl: AppAssets.broadcast,
        type: ChatType.broadcast,
      ),
    ];
  }

  Future<List<Chat>> searchChats(String query) async {
    final chats = await getChats();
    return chats
        .where((chat) =>
            chat.name.toLowerCase().contains(query.toLowerCase()) ||
            chat.lastMessage.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<Chat>> filterChats(ChatFilter filter) async {
    final chats = await getChats();

    switch (filter) {
      case ChatFilter.all:
        return chats;
      case ChatFilter.unread:
        return chats.where((c) => c.isUnread).toList();
      case ChatFilter.groups:
        return chats.where((c) => c.type == ChatType.group).toList();
      default:
        return chats;
    }
  }
}

enum ChatFilter {
  all,
  unread,
  myService,
  allServices,
  groups,
  calls,
}
