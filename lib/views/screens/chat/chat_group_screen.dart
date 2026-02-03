import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/group_chat_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/group_chat_repository.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_app_bar.dart';
import 'package:ngomna_chat/views/widgets/chat/message_bubble_with_avatar.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_input.dart';
import 'package:ngomna_chat/views/widgets/chat/date_separator.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/controllers/chat_input_controller.dart'
    as controller;
import 'package:ngomna_chat/core/utils/date_formatter.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GroupChatViewModel(
            GroupChatRepository(),
            groupId,
          )..loadMessages(),
        ),
        ChangeNotifierProvider(
          create: (_) => controller.ChatInputStateController(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              debugPrint(
                  'Clic détecté en dehors du menu attaché (ChatGroupScreen)');
              context
                  .read<controller.ChatInputStateController>()
                  .closeAttachMenu();
            },
            child: _ChatGroupContent(
              groupName: groupName,
              groupAvatar: groupAvatar,
            ),
          );
        },
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
          matricule: 'group', // Utilisation de l'ID comme matricule par défaut
          nom: groupName.split(' ').first, // Extraction du prénom
          prenom: groupName.split(' ').last, // Extraction du nom
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
            controller: controller.ChatInputStateController(),
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

              final showDateSeparator = index == 0 ||
                  viewModel.messages[index - 1].timestamp.day !=
                      message.timestamp.day;

              return Column(
                children: [
                  if (showDateSeparator)
                    DateSeparator(
                      text:
                          DateFormatter.formatDateSeparator(message.timestamp),
                    ),
                  MessageBubbleWithAvatar(
                    message: message,
                    senderName: !message.isMe ? message.sender.fullName : null,
                    avatarUrl: !message.isMe ? message.sender.avatarUrl : null,
                    key: ValueKey(message.id),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
