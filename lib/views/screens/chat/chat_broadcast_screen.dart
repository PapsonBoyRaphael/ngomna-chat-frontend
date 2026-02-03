import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/broadcast_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/broadcast_repository.dart';
import 'package:ngomna_chat/views/widgets/chat/broadcast_app_bar.dart';
import 'package:ngomna_chat/views/widgets/chat/message_bubble.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_input.dart';
import 'package:ngomna_chat/views/widgets/chat/date_separator.dart';
import 'package:ngomna_chat/data/services/api_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'package:ngomna_chat/data/repositories/auth_repository.dart';
import 'package:ngomna_chat/controllers/chat_input_controller.dart'
    as controller;
import 'package:ngomna_chat/core/utils/date_formatter.dart';

class ChatBroadcastScreen extends StatelessWidget {
  final String broadcastId;
  final String broadcastName;

  const ChatBroadcastScreen({
    super.key,
    required this.broadcastId,
    this.broadcastName = 'Broadcast',
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BroadcastViewModel(
              BroadcastRepository(AuthRepository(
                  apiService: ApiService(), storageService: StorageService())),
              AuthRepository(
                  apiService: ApiService(), storageService: StorageService()),
              broadcastId)
            ..loadMessages(),
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
                  'Clic détecté en dehors du menu attaché (ChatBroadcastScreen)');
              context
                  .read<controller.ChatInputStateController>()
                  .closeAttachMenu();
            },
            child: _ChatBroadcastContent(broadcastName: broadcastName),
          );
        },
      ),
    );
  }
}

class _ChatBroadcastContent extends StatelessWidget {
  final String broadcastName;

  const _ChatBroadcastContent({required this.broadcastName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BroadcastAppBar(
        broadcastName: broadcastName,
        onBack: () => Navigator.pop(context),
        recipientCount: context
            .read<BroadcastViewModel>()
            .recipients
            .length, // Passage du nombre de destinataires
      ),
      body: Column(
        children: [
          Container(height: 1, color: const Color(0xFFE0E0E0)),
          _buildMessagesList(),
          Container(height: 1, color: const Color(0xFFE0E0E0)),
          ChatInput(
            onSendMessage: (text) {
              context.read<BroadcastViewModel>().sendMessage(text);
            },
            controller: controller.ChatInputStateController(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Expanded(
      child: Consumer<BroadcastViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(child: Text('Error: ${viewModel.error}'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: viewModel.messages.length, // Suppression du header
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
                  MessageBubble(message: message),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
