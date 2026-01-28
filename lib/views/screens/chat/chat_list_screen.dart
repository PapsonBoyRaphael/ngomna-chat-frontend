import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/chat_list_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/chat_repository.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_tile.dart';
import 'package:ngomna_chat/views/widgets/chat/category_chip.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_list_top_bar.dart';
import 'package:ngomna_chat/views/widgets/common/bottom_nav.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/core/constants/app_fonts.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatListViewModel(ChatRepository())..loadChats(),
      child: const _ChatListContent(),
    );
  }
}

class _ChatListContent extends StatelessWidget {
  const _ChatListContent();

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
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(child: Text('Error: ${viewModel.error}'));
          }

          return ListView.separated(
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
          );
        },
      ),
    );
  }

  void _navigateToChat(BuildContext context, Chat chat) {
    switch (chat.type) {
      case ChatType.broadcast:
        Navigator.pushNamed(
          context,
          AppRoutes.chatBroadcast,
          arguments: {
            'broadcastId': chat.id,
            'broadcastName': chat.name,
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
            'groupAvatar': chat.avatarUrl ??
                'default_avatar_url', // Ajoutez une valeur par défaut si nécessaire
          },
        );
        break;
      case ChatType.personal:
        Navigator.pushNamed(
          context,
          AppRoutes.chat,
          arguments: {
            'chatId': chat.id,
            'user': User(
              id: chat.id,
              name: chat.name,
              avatarUrl: chat.avatarUrl,
            ),
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
        return 'My service';
      case ChatFilter.allServices:
        return 'All services';
      case ChatFilter.groups:
        return 'Groups';
      case ChatFilter.calls:
        return 'Calls';
    }
  }
}
