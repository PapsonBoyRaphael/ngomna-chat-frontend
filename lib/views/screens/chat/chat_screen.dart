import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/chat_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/message_repository.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_app_bar.dart';
import 'package:ngomna_chat/views/widgets/chat/message_bubble.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_input.dart';
import 'package:ngomna_chat/controllers/chat_input_controller.dart'
    as controller;

class ChatScreen extends StatelessWidget {
  final String chatId;
  final User user;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        debugPrint('Clic détecté en dehors du menu attaché (ChatScreen)');
        Builder(
          builder: (context) {
            context
                .read<controller.ChatInputStateController>()
                .closeAttachMenu();
            return const SizedBox();
          },
        );
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                ChatViewModel(MessageRepository(), chatId)..loadMessages(),
          ),
          ChangeNotifierProvider(
            create: (_) => controller.ChatInputStateController(),
          ),
        ],
        child: _ChatScreenContent(user: user),
      ),
    );
  }
}

class _ChatScreenContent extends StatelessWidget {
  final User user;

  const _ChatScreenContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatAppBar(
        user: user,
        onBack: () => Navigator.pop(context),
        onCall: () {
          // TODO: Implémenter l'appel audio
        },
        onVideoCall: () {
          // TODO: Implémenter l'appel vidéo
        },
      ),
      body: Column(
        children: [
          Container(height: 1, color: const Color(0xFFE0E0E0)),
          _buildMessagesList(),
          Container(height: 1, color: const Color(0xFFE0E0E0)),
          ChatInput(
            onSendMessage: (text) {
              context.read<ChatViewModel>().sendMessage(text);
            },
            controller: controller.ChatInputStateController(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Expanded(
      child: Consumer<ChatViewModel>(
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

              return MessageBubble(message: message);
            },
          );
        },
      ),
    );
  }
}
