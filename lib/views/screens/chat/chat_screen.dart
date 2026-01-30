import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/message_viewmodel.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_app_bar.dart';
import 'package:ngomna_chat/views/widgets/chat/message_bubble.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_input.dart';
import 'package:ngomna_chat/controllers/chat_input_controller.dart'
    as controller;
import 'package:ngomna_chat/core/utils/date_formatter.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final User user;
  final Map<String, dynamic>? conversationData;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.user,
    this.conversationData,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late MessageViewModel _messageViewModel;
  late SocketService _socketService;

  // Pour le typing indicator
  Timer? _typingTimer;
  bool _isTyping = false;
  final TextEditingController _textController = TextEditingController();

  // Pour le scroll automatique
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
      _socketService = Provider.of<SocketService>(context, listen: false);

      // Charger les messages
      _messageViewModel.loadMessages(widget.conversationId);

      // S'abonner aux nouveaux messages pour scroll automatique
      _setupMessageListener();

      // Marquer la conversation comme lue
      _markConversationAsRead();
    });
  }

  void _setupMessageListener() {
    // Écouter les nouveaux messages pour scroll automatique
    // Note: On utilise déjà le stream dans le MessageViewModel
    // Ici on peut ajouter une logique spécifique à l'UI
  }

  void _markConversationAsRead() {
    // Marquer tous les messages comme lus
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _messageViewModel.markAllAsRead(widget.conversationId);

      // Informer le serveur via Socket.IO
      // (déjà fait dans markAllAsRead via MessageRepository)
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();

    // Arrêter de taper si on était en train
    if (_isTyping) {
      _messageViewModel.stopTyping(widget.conversationId, _getCurrentUserId());
    }

    super.dispose();
  }

  String _getCurrentUserId() {
    // TODO: Récupérer l'ID de l'utilisateur courant depuis AuthViewModel
    // Pour l'instant, retourner un ID par défaut
    return 'current_user_id';
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    _messageViewModel
        .sendTextMessage(
      conversationId: widget.conversationId,
      content: text.trim(),
      senderId: _getCurrentUserId(),
    )
        .then((message) {
      if (message != null) {
        // Scroll vers le bas après envoi
        _scrollToBottom();

        // Arrêter le typing indicator
        _stopTyping();
      }
    });

    // Effacer le champ de texte
    _textController.clear();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      // Commencer à taper
      _startTyping();
    } else if (text.isEmpty && _isTyping) {
      // Arrêter de taper
      _stopTyping();
    }

    // Reset le timer de typing
    _resetTypingTimer();
  }

  void _startTyping() {
    if (!_isTyping) {
      _isTyping = true;
      _messageViewModel.startTyping(widget.conversationId, _getCurrentUserId());
    }
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _messageViewModel.stopTyping(widget.conversationId, _getCurrentUserId());
    }
  }

  void _resetTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping && _textController.text.isEmpty) {
        _stopTyping();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onFileSelected(
      String filePath, String fileName, int fileSize, String mimeType) {
    // Uploader le fichier
    _messageViewModel
        .uploadFile(
      conversationId: widget.conversationId,
      filePath: filePath,
      fileName: fileName,
    )
        .then((result) {
      if (result != null) {
        // Envoyer le message avec le fichier
        _messageViewModel.sendFileMessage(
          conversationId: widget.conversationId,
          content: fileName,
          senderId: _getCurrentUserId(),
          fileId: result['fileId'] as String? ?? '',
          fileName: fileName,
          fileSize: fileSize,
          mimeType: mimeType,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageViewModel =
        Provider.of<MessageViewModel>(context, listen: true);
    final typingUsers = messageViewModel.getTypingUsers(widget.conversationId);

    // Observer les messages pour scroll automatique
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messages = messageViewModel.getMessages(widget.conversationId);
      if (messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => controller.ChatInputStateController(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final controllerInstance =
              Provider.of<controller.ChatInputStateController>(context,
                  listen: false);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (controllerInstance.showAttachMenu) {
                controllerInstance.closeAttachMenu();
              }
            },
            child: _ChatScreenContent(
              user: widget.user,
              conversationId: widget.conversationId,
              onSendMessage: _sendMessage,
              onTextChanged: _onTextChanged,
              textController: _textController,
              scrollController: _scrollController,
              typingUsers: typingUsers,
              onFileSelected: _onFileSelected,
            ),
          );
        },
      ),
    );
  }
}

class _ChatScreenContent extends StatelessWidget {
  final User user;
  final String conversationId;
  final Function(String) onSendMessage;
  final Function(String) onTextChanged;
  final TextEditingController textController;
  final ScrollController scrollController;
  final Set<String> typingUsers;
  final Function(String, String, int, String) onFileSelected;

  const _ChatScreenContent({
    required this.user,
    required this.conversationId,
    required this.onSendMessage,
    required this.onTextChanged,
    required this.textController,
    required this.scrollController,
    required this.typingUsers,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    final messageViewModel =
        Provider.of<MessageViewModel>(context, listen: true);
    final state = messageViewModel.getConversationState(conversationId);
    final messages = messageViewModel.getMessages(conversationId);

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

          // Typing indicator
          if (typingUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${typingUsers.length} ${typingUsers.length == 1 ? 'personne' : 'personnes'} est en train d\'écrire...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _buildMessagesList(
              context: context,
              state: state,
              messages: messages,
              scrollController: scrollController,
            ),
          ),

          Container(height: 1, color: const Color(0xFFE0E0E0)),

          // Chat input
          ChatInput(
            onSendMessage: onSendMessage,
            onTextChanged: onTextChanged,
            textController: textController,
            onFileSelected: () => onFileSelected('', '', 0, ''),
            controller: context.read<controller.ChatInputStateController>(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList({
    required BuildContext context,
    required ConversationState? state,
    required List<Message> messages,
    required ScrollController scrollController,
  }) {
    // États de chargement/erreur
    if (state != null && state.isLoading && messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des messages...'),
          ],
        ),
      );
    }

    if (state != null && state.hasError && messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Erreur: ${state.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final viewModel =
                      Provider.of<MessageViewModel>(context, listen: false);
                  viewModel.loadMessages(conversationId, forceRefresh: true);
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun message',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Envoyez le premier message !',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Liste des messages
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];

        // Afficher un séparateur de date si nécessaire
        final showDateSeparator = index == 0 ||
            messages[index - 1].timestamp.day != message.timestamp.day;

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.timestamp),

            MessageBubble(
              message: message,
              onTap: () {
                // TODO: Gérer les actions sur le message (répondre, etc.)
              },
              onLongPress: () {
                // TODO: Afficher le menu contextuel
              },
            ),

            // Espacement entre les messages
            if (index < messages.length - 1 &&
                messages[index + 1].senderId != message.senderId)
              const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime? date) {
    if (date == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDate(date),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDateSeparator(date);
  }
}
