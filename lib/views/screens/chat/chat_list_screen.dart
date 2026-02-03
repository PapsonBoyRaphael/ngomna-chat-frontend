import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/chat_list_viewmodel.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_tile.dart';
import 'package:ngomna_chat/views/widgets/chat/category_chip.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_list_top_bar.dart';
import 'package:ngomna_chat/views/widgets/common/bottom_nav.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const _ChatListContent();
  }
}

class _ChatListContent extends StatefulWidget {
  const _ChatListContent();

  @override
  State<_ChatListContent> createState() => __ChatListContentState();
}

class __ChatListContentState extends State<_ChatListContent> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ChatListViewModel>(context, listen: false);

      // Charger les conversations initiales
      viewModel.loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 15, left: 5, right: 5),
          child: Column(
            children: [
              ChatListTopBar(
                onNewChat: () =>
                    Navigator.pushNamed(context, AppRoutes.newChat),
                onSearch: (query) {
                  context.read<ChatListViewModel>().searchChats(query);
                },
              ),
              _buildFilters(),
              _buildChatList(),
              const BottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer<ChatListViewModel>(
      builder: (context, viewModel, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ChatFilter.values.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CategoryChip(
                    label: _getFilterLabel(filter),
                    isSelected: viewModel.currentFilter == filter,
                    onTap: () => viewModel.setFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatList() {
    return Expanded(
      child: Consumer<ChatListViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des conversations...'),
                ],
              ),
            );
          }

          if (viewModel.error != null && viewModel.chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${viewModel.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.loadConversations(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (viewModel.chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Commencez une nouvelle conversation',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await viewModel.loadConversations(forceRefresh: true);
            },
            child: ListView.separated(
              itemCount: viewModel.chats.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  thickness: 1.5,
                  color: Color(0xFFBDBDBD),
                ),
              ),
              itemBuilder: (context, index) {
                final chat = viewModel.chats[index];
                return ChatTile(
                  chat: chat,
                  onTap: () => _navigateToChat(context, chat),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToChat(BuildContext context, Chat chat) {
    // Marquer la conversation comme lue
    final viewModel = Provider.of<ChatListViewModel>(context, listen: false);
    viewModel.markConversationAsRead(chat.id);

    switch (chat.type) {
      case ChatType.broadcast:
        Navigator.pushNamed(
          context,
          AppRoutes.chatBroadcast,
          arguments: {
            'broadcastId': chat.id,
            'broadcastName': chat.name,
            'conversationData': chat.toJson(),
          },
        );
        break;
      case ChatType.group:
        Navigator.pushNamed(
          context,
          AppRoutes.chatGroup,
          arguments: {
            'groupId': chat.id,
            'groupName': chat.name,
            'groupAvatar': chat.avatarUrl,
            'conversationData': chat.toJson(),
          },
        );
        break;
      case ChatType.channel:
        // TODO: Navigate to channel screen
        Navigator.pushNamed(
          context,
          AppRoutes.chat, // Placeholder
          arguments: {
            'chatId': chat.id,
            'conversationData': chat.toJson(),
          },
        );
        break;
      case ChatType.personal:
        // Extraire les infos du participant
        final otherParticipant =
            chat.userMetadata.isNotEmpty ? chat.userMetadata.first : null;

        Navigator.pushNamed(
          context,
          AppRoutes.chat,
          arguments: {
            'chatId': chat.id,
            'conversationId': chat.id,
            'user': otherParticipant != null
                ? User(
                    id: otherParticipant.userId,
                    matricule: otherParticipant.metadataId,
                    nom: otherParticipant.name,
                    prenom: '',
                    avatarUrl: otherParticipant.avatar,
                  )
                : User(
                    id: '',
                    matricule: '',
                    nom: '',
                    prenom: '',
                  ),
            'conversationData': chat.toJson(),
          },
        );
        break;
    }
  }

  String _getFilterLabel(ChatFilter filter) {
    switch (filter) {
      case ChatFilter.all:
        return 'All';
      case ChatFilter.unread:
        return 'Unread';
      case ChatFilter.myService:
        return 'My Service';
      case ChatFilter.allServices:
        return 'All Services';
      case ChatFilter.groups:
        return 'Groups';
      case ChatFilter.broadcasts:
        return 'Broadcasts';
      case ChatFilter.calls:
        return 'Calls';
    }
  }
}
