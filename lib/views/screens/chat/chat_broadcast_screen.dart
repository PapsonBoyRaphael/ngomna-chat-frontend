import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/broadcast_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/broadcast_repository.dart';
import 'package:ngomna_chat/views/widgets/chat/broadcast_app_bar.dart';
import 'package:ngomna_chat/views/widgets/chat/message_bubble.dart';
import 'package:ngomna_chat/views/widgets/chat/date_separator.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_input.dart';

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
    return ChangeNotifierProvider(
      create: (_) => BroadcastViewModel(
        BroadcastRepository(),
        broadcastId,
      )..loadMessages(),
      child: _ChatBroadcastContent(broadcastName: broadcastName),
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
            itemCount: viewModel.messages.length + 1, // +1 pour le header
            itemBuilder: (context, index) {
              // Header avec info sur les destinataires
              if (index == 0) {
                return _buildBroadcastInfo(viewModel.recipients);
              }

              final message = viewModel.messages[index - 1];
              return MessageBubble(message: message);
            },
          );
        },
      ),
    );
  }

  Widget _buildBroadcastInfo(List<String> recipients) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFF57C00),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Broadcasting to ${recipients.length} contacts',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFF57C00),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
