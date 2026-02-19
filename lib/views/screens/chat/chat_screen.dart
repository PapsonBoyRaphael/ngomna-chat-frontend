import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/message_viewmodel.dart';
import 'package:ngomna_chat/viewmodels/auth_viewmodel.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_app_bar.dart';
import 'package:ngomna_chat/views/widgets/chat/message_bubble.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_input.dart';
import 'package:ngomna_chat/views/widgets/chat/date_separator.dart';
import 'package:ngomna_chat/controllers/chat_input_controller.dart'
    as controller;
import 'package:ngomna_chat/core/utils/date_formatter.dart';
import 'package:ngomna_chat/data/repositories/message_repository.dart';
import 'package:ngomna_chat/data/repositories/chat_list_repository.dart';
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
  late AuthViewModel _authViewModel;
  Chat? chat;

  // Pour écouter les mises à jour du chat (présence, etc.)
  StreamSubscription? _chatUpdatesSubscription;

  // Pour le typing indicator
  Timer? _typingTimer;
  bool _isTyping = false;
  final TextEditingController _textController = TextEditingController();

  // Pour le scroll automatique
  final ScrollController _scrollController = ScrollController();

  // 🟢 Timer pour rafraîchir les dates/heures automatiquement
  Timer? _dateRefreshTimer;

  @override
  void initState() {
    super.initState();

    // Parser les données de conversation si disponibles
    if (widget.conversationData != null) {
      chat = Chat.fromJson(widget.conversationData!);
    }

    final messageRepository =
        Provider.of<MessageRepository>(context, listen: false);
    _authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _socketService = Provider.of<SocketService>(context, listen: false);

    _messageViewModel = MessageViewModel(
      messageRepository: messageRepository,
      conversationId: widget.conversationId,
      authViewModel: _authViewModel,
      chat: chat, // Passer les données de la conversation
    );

    print(
        '🔌 [ChatScreen] Socket connecté: ${_socketService.isConnected}, authentifié: ${_socketService.isAuthenticated}');

    // Initialiser le ViewModel (charge les messages et s'abonne aux streams)
    _messageViewModel.init();

    // S'abonner aux nouveaux messages pour scroll automatique
    _setupMessageListener();

    // 🟢 NOUVEAU: Écouter les mises à jour du chat (présence, etc.) depuis ChatListRepository
    _setupChatUpdatesListener();

    // 🟢 NOUVEAU: Démarrer le timer de rafraîchissement des dates (toutes les minutes)
    _startDateRefreshTimer();

    // Marquer la conversation comme lue
    _markConversationAsRead();
  }

  void _setupMessageListener() {
    // Écouter les nouveaux messages pour scroll automatique
    // Note: On utilise déjà le stream dans le MessageViewModel
    // Ici on peut ajouter une logique spécifique à l'UI
  }

  /// 🟢 Crée un User avec la présence à jour depuis le chat
  User _getUserWithUpdatedPresence() {
    // Si on n'a pas de chat, retourner le user original
    if (chat == null) return widget.user;

    final currentUser = _authViewModel.currentUser;
    final currentUserMatricule = currentUser?.matricule;

    // Pour une conversation personnelle, prendre l'autre participant
    // (celui qui n'est pas l'utilisateur actuel)
    ParticipantMetadata? otherUserMetadata;

    for (final metadata in chat!.userMetadata) {
      // Chercher le participant qui n'est pas l'utilisateur actuel
      if (metadata.userId != currentUserMatricule &&
          metadata.userId != currentUser?.id) {
        otherUserMetadata = metadata;
        break;
      }
    }

    // Si pas trouvé (rare), prendre le premier
    otherUserMetadata ??=
        chat!.userMetadata.isNotEmpty ? chat!.userMetadata.first : null;

    if (otherUserMetadata == null) return widget.user;

    // Debug: afficher les données de présence utilisées
    final presence = otherUserMetadata.presence;
    if (presence != null) {
      print('🔍 [ChatScreen._getUserWithUpdatedPresence] Présence trouvée:');
      print('   - userId: ${otherUserMetadata.userId}');
      print('   - isOnline: ${presence.isOnline}');
      print('   - lastActivity: ${presence.lastActivity}');
      print('   - lastActivity.isUtc: ${presence.lastActivity.isUtc}');
      print(
          '   - Format pour ChatAppBar: ${presence.isOnline ? "En ligne" : "Vu il y a ${DateTime.now().difference(presence.lastActivity).inMinutes} min"}');
    } else {
      print(
          '🔍 [ChatScreen._getUserWithUpdatedPresence] Aucune présence trouvée');
      print('   - userId: ${otherUserMetadata.userId}');
      print('   - widget.user.lastSeen: ${widget.user.lastSeen}');
    }

    // Retourner le user avec la présence à jour
    final updatedUser = User(
      id: widget.user.id,
      matricule: widget.user.matricule,
      nom: widget.user.nom,
      prenom: widget.user.prenom,
      ministere: widget.user.ministere,
      sexe: widget.user.sexe,
      avatarUrl: widget.user.avatarUrl,
      isOnline: otherUserMetadata.presence?.isOnline ?? widget.user.isOnline,
      lastSeen:
          otherUserMetadata.presence?.lastActivity ?? widget.user.lastSeen,
      createdAt: widget.user.createdAt,
      updatedAt: widget.user.updatedAt,
    );

    print('🔍 [ChatScreen._getUserWithUpdatedPresence] User créé:');
    print('   - isOnline: ${updatedUser.isOnline}');
    print('   - lastSeen: ${updatedUser.lastSeen}');

    return updatedUser;
  }

  /// 🟢 Démarre le timer pour rafraîchir les dates/heures toutes les minutes
  void _startDateRefreshTimer() {
    _dateRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Forcer la reconstruction du widget pour mettre à jour les dates relatives
      if (mounted) {
        setState(() {
          // Le setState() va forcer la reconstruction, les dates seront recalculées
        });
      }
    });
  }

  void _setupChatUpdatesListener() {
    final chatListRepository = context.read<ChatListRepository>();
    _chatUpdatesSubscription = chatListRepository.chatsUpdated.listen((chats) {
      // Chercher le chat actuel dans la liste mise à jour
      Chat? updatedChat;
      for (final c in chats) {
        if (c.id == widget.conversationId) {
          updatedChat = c;
          break;
        }
      }

      if (updatedChat != null) {
        print(
            '📡 [ChatScreen] Chat mis à jour reçu pour ${widget.conversationId}');

        // Vérifier les données de présence
        final userMetadata = updatedChat.userMetadata.firstWhere(
          (m) => m.userId != _authViewModel.currentUser?.matricule,
          orElse: () => updatedChat!.userMetadata.first,
        );

        if (userMetadata.presence != null) {
          print(
              '   👤 Présence: ${userMetadata.presence!.isOnline ? "🟢 EN LIGNE" : "🔴 HORS LIGNE"}');
          print('   🕐 lastActivity: ${userMetadata.presence!.lastActivity}');
        }

        setState(() {
          chat = updatedChat;
        });
        _messageViewModel.updateChat(updatedChat);
        print('✅ [ChatScreen] setState() appelé, widget va se reconstruire');
      }
    });
  }

  void _markConversationAsRead() {
    // ✅ CORRECTION: Marquer individuellement les messages comme lus au moment de l'affichage
    // (Au lieu de tous les marquer d'un coup dès l'arrivée dans le chat)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messages = _messageViewModel.getMessages(widget.conversationId);
      final messageRepository = _messageViewModel.messageRepository;

      for (final message in messages) {
        // Marquer READ seulement si: c'est pas un message de moi ET status < READ
        if (!message.isMe && message.status.index < MessageStatus.read.index) {
          print(
              '👁️ [ChatScreen] Marquage message comme READ au moment de l\'affichage: ${message.id}');
          await messageRepository.markMessageRead(
              message.id, widget.conversationId);
        }
      }
    });
  }

  @override
  void dispose() {
    _messageViewModel.dispose();
    _chatUpdatesSubscription?.cancel(); // ✨ Annuler la subscription
    _typingTimer?.cancel();
    _dateRefreshTimer
        ?.cancel(); // 🟢 Annuler le timer de rafraîchissement des dates
    _textController.dispose();
    _scrollController.dispose();

    // Arrêter de taper si on était en train
    if (_isTyping) {
      _messageViewModel.stopTyping(widget.conversationId, _getCurrentUserId());
    }

    super.dispose();
  }

  String _getCurrentUserId() {
    // Récupérer le matricule de l'utilisateur courant depuis AuthViewModel
    final currentUser = _authViewModel.currentUser;
    final matricule = currentUser?.matricule ?? 'unknown';
    print('👤 [ChatScreen._getCurrentUserId] Matricule: $matricule');
    return matricule;
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
      // Scroll vers le bas après envoi
      _scrollToBottom();

      // Arrêter le typing indicator
      _stopTyping();
    });

    // Effacer le champ de texte
    _textController.clear();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      // Commencer à taper
      _startTyping();
    } else if (text.isNotEmpty && _isTyping) {
      // Rafraîchir le typing
      _refreshTyping();
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
      _messageViewModel.startTyping(widget.conversationId, _getCurrentUserId(),
          status: 'start');
    }
  }

  void _refreshTyping() {
    if (_isTyping) {
      _messageViewModel.startTyping(widget.conversationId, _getCurrentUserId(),
          status: 'refresh');
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
      if (_isTyping) {
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MessageViewModel>.value(
            value: _messageViewModel),
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
              user:
                  _getUserWithUpdatedPresence(), // 🟢 Passer le user avec la présence à jour
              conversationId: widget.conversationId,
              chat: chat,
              onSendMessage: _sendMessage,
              onTextChanged: _onTextChanged,
              textController: _textController,
              scrollController: _scrollController,
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
  final Chat? chat;
  final Function(String) onSendMessage;
  final Function(String) onTextChanged;
  final TextEditingController textController;
  final ScrollController scrollController;
  final Function(String, String, int, String) onFileSelected;

  const _ChatScreenContent({
    required this.user,
    required this.conversationId,
    required this.chat,
    required this.onSendMessage,
    required this.onTextChanged,
    required this.textController,
    required this.scrollController,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    final messageViewModel =
        Provider.of<MessageViewModel>(context, listen: true);
    final typingUsers = messageViewModel.getTypingUsers(conversationId);

    // Observer les messages pour scroll automatique
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messages = messageViewModel.getMessages(conversationId);
      if (messages.isNotEmpty) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });

    final state = messageViewModel.getConversationState(conversationId);
    final messages = messageViewModel.getMessages(conversationId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatAppBar(
        user: user, // 🟢 Utilise le user avec présence passé en paramètre
        customTitle: chat?.displayName,
        customAvatar: chat?.avatarUrl,
        isOnlineOverride: chat?.isOnline,
        typingUsers: typingUsers,
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
                  viewModel.loadMessages(forceRefresh: true);
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
    return DateSeparator(text: _formatDate(date));
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDateSeparator(date);
  }
}
