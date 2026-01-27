import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/group_chat_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/group_chat_repository.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_app_bar.dart';
import 'package:ngomna_chat/views/widgets/chat/message_bubble_with_avatar.dart';
import 'package:ngomna_chat/views/widgets/chat/date_separator.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_input.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class ChatGroupScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String groupAvatar;

  const ChatGroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupChatViewModel(
        GroupChatRepository(),
        groupId,
      )..loadMessages(),
      child: _ChatGroupContent(
        groupName: groupName,
        groupAvatar: groupAvatar,
      ),
    );
  }
}

class _ChatGroupContent extends StatelessWidget {
  final String groupName;
  final String groupAvatar;

  const _ChatGroupContent({
    required this.groupName,
    required this.groupAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatAppBar(
        user: User(
          id: 'group',
          name: groupName,
          avatarUrl: groupAvatar,
          isOnline: true, // Les groupes sont toujours "actifs"
        ),
        onBack: () => Navigator.pop(context),
        onCall: () {
          // TODO: Appel de groupe
        },
        onVideoCall: () {
          // TODO: Appel vidéo de groupe
        },
      ),
      body: Column(
        children: [
          Container(height: 1, color: const Color(0xFFE0E0E0)),
          _buildMessagesList(),
          Container(height: 1, color: const Color(0xFFE0E0E0)),
          ChatInput(
            onSendMessage: (text) {
              context.read<GroupChatViewModel>().sendMessage(text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Expanded(
      child: Consumer<GroupChatViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(child: Text('Error: ${viewModel.error}'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: viewModel.messages.length,
            itemBuilder: (context, index) {
              final message = viewModel.messages[index];

              return MessageBubbleWithAvatar(
                message: message,
                senderName: !message.isMe ? message.sender.name : null,
                avatarUrl: !message.isMe ? message.sender.avatarUrl : null,
              );
            },
          );
        },
      ),
    );
  }
}
