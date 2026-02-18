import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:ngomna_chat/viewmodels/group_chat_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/group_chat_repository.dart';
import 'package:ngomna_chat/data/repositories/chat_list_repository.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_app_bar.dart';
import 'package:ngomna_chat/views/widgets/chat/message_bubble_with_avatar.dart';
import 'package:ngomna_chat/views/widgets/chat/chat_input.dart';
import 'package:ngomna_chat/views/widgets/chat/date_separator.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/controllers/chat_input_controller.dart'
    as controller;
import 'package:ngomna_chat/core/utils/date_formatter.dart';

class ChatGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupAvatar;
  final Map<String, dynamic>? conversationData;

  const ChatGroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
    this.conversationData,
  });

  @override
  State<ChatGroupScreen> createState() => _ChatGroupScreenState();
}

class _ChatGroupScreenState extends State<ChatGroupScreen> {
  late GroupChatViewModel _viewModel;
  late StreamSubscription? _chatUpdatesSubscription;

  // 🟢 Timer pour rafraîchir les dates/heures automatiquement
  Timer? _dateRefreshTimer;

  // Typing indicator
  Timer? _typingTimer;
  bool _isTyping = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Créer le ViewModel avec le repository du provider
    final repository = context.read<GroupChatRepository>();
    _viewModel = GroupChatViewModel(
      repository,
      widget.groupId,
      widget.conversationData,
    );

    // 🟢 IMPORTANT: Appeler init() pour écouter les changements en temps réel
    _viewModel.init();

    // 🟢 NOUVEAU: Écouter les mises à jour du chat (présence, etc.) depuis ChatListRepository
    final chatListRepository = context.read<ChatListRepository>();
    _chatUpdatesSubscription = chatListRepository.chatsUpdated.listen((chats) {
      // Chercher le chat actuel dans la liste mise à jour
      Chat? updatedChat;
      for (final chat in chats) {
        if (chat.id == widget.groupId) {
          updatedChat = chat;
          break;
        }
      }

      if (updatedChat != null) {
        print('📡 [ChatGroupScreen] Chat mis à jour reçu, notifiant ViewModel');
        _viewModel.updateChat(updatedChat);
      }
    });

    // 🟢 NOUVEAU: Démarrer le timer de rafraîchissement des dates (toutes les minutes)
    _startDateRefreshTimer();
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

  @override
  void dispose() {
    print('🧹 [ChatGroupScreen] dispose()');
    _chatUpdatesSubscription?.cancel();
    _dateRefreshTimer
        ?.cancel(); // 🟢 Annuler le timer de rafraîchissement des dates
    _typingTimer?.cancel();
    if (_isTyping) {
      _viewModel.stopTyping(widget.groupId);
    }
    _textController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _startTyping();
    } else if (text.isNotEmpty && _isTyping) {
      _refreshTyping();
    } else if (text.isEmpty && _isTyping) {
      _stopTyping();
    }

    _resetTypingTimer();
  }

  void _startTyping() {
    if (!_isTyping) {
      _isTyping = true;
      _viewModel.startTyping(widget.groupId, status: 'start');
    }
  }

  void _refreshTyping() {
    if (_isTyping) {
      _viewModel.startTyping(widget.groupId, status: 'refresh');
    }
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _viewModel.stopTyping(widget.groupId);
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GroupChatViewModel>.value(value: _viewModel),
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
              groupName: widget.groupName,
              groupAvatar: widget.groupAvatar,
              textController: _textController,
              onTextChanged: _onTextChanged,
              onSendMessage: (text) {
                _viewModel.sendMessage(text);
                _stopTyping();
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChatGroupContent extends StatelessWidget {
  final String groupName;
  final String? groupAvatar;
  final TextEditingController textController;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onSendMessage;

  const _ChatGroupContent({
    required this.groupName,
    this.groupAvatar,
    required this.textController,
    required this.onTextChanged,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupChatViewModel>(
      builder: (context, viewModel, child) {
        // Récupérer les informations de présence du groupe
        final onlineCount = viewModel.onlineCount;
        final totalParticipants = viewModel.totalParticipants;
        final typingUsers = viewModel.getTypingUsers(viewModel.groupId);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: ChatAppBar(
            user: User(
              id: 'group',
              matricule: 'group',
              nom: groupName.split(' ').first,
              prenom: groupName.split(' ').length > 1
                  ? groupName.split(' ').sublist(1).join(' ')
                  : '',
              avatarUrl: (groupAvatar != null && groupAvatar!.isNotEmpty)
                  ? groupAvatar
                  : 'assets/avatars/group.png',
              isOnline: onlineCount > 0, // Au moins un membre en ligne
            ),
            isGroup: true,
            onlineCount: onlineCount,
            totalParticipants: totalParticipants,
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

              // Typing indicator
              if (typingUsers.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        ),
                      ),
                    ],
                  ),
                ),

              _buildMessagesList(),
              Container(height: 1, color: const Color(0xFFE0E0E0)),
              ChatInput(
                onSendMessage: onSendMessage,
                onTextChanged: onTextChanged,
                textController: textController,
                controller: controller.ChatInputStateController(),
              ),
            ],
          ),
        );
      },
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

          // +1 pour le message de création du groupe
          final itemCount = viewModel.messages.length + 1;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Premier élément: message de création du groupe
              if (index == 0) {
                return _buildGroupCreationSeparator(viewModel);
              }

              // Les messages commencent à l'index 1
              final messageIndex = index - 1;
              final message = viewModel.messages[messageIndex];

              final showDateSeparator = messageIndex == 0 ||
                  viewModel.messages[messageIndex - 1].timestamp.day !=
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

  /// Construit le séparateur indiquant la création du groupe
  Widget _buildGroupCreationSeparator(GroupChatViewModel viewModel) {
    final creatorName = viewModel.creatorName;
    final createdAt = viewModel.createdAt;

    String dateText = '';
    if (createdAt != null) {
      final formattedDate = DateFormatter.formatDateSeparator(createdAt);
      // Éviter "le Aujourd'hui", utiliser juste "Aujourd'hui"
      if (formattedDate == 'Aujourd\'hui') {
        dateText = ' $formattedDate';
      } else {
        dateText = ' le $formattedDate';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.group_add,
                size: 16,
                color: Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$creatorName a créé ce groupe$dateText',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757575),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
