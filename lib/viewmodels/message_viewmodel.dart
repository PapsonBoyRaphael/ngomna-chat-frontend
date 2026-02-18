import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/repositories/message_repository.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/chat_stream_manager.dart';
import 'package:ngomna_chat/viewmodels/auth_viewmodel.dart';

class MessageViewModel extends ChangeNotifier {
  final MessageRepository _messageRepository;
  final SocketService _socketService;
  final String _conversationId;
  final AuthViewModel _authViewModel;
  Chat? _chat; // ✨ Maintenant mutable pour recevoir les mises à jour

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  final Set<String> _typingUsers = {};

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Données de la conversation (avec présence)
  Chat? get chat => _chat;

  MessageViewModel({
    required MessageRepository messageRepository,
    required String conversationId,
    required AuthViewModel authViewModel,
    Chat? chat,
  })  : _messageRepository = messageRepository,
        _socketService = messageRepository
            .socketService, // On accède au socketService via messageRepository
        _conversationId = conversationId,
        _authViewModel = authViewModel,
        _chat = chat;

  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;

  /// Initialiser le ViewModel (appelé après construction)
  Future<void> init() async {
    // Charger les messages initiaux
    await loadMessages();

    // Écouter les mises à jour en temps réel
    _messagesSubscription =
        _messageRepository.watchMessages(_conversationId).listen((messages) {
      for (var i = 0; i < messages.length; i++) {}

      _messages = messages;

      // Déterminer isMe pour tous les messages
      final currentUser = _authViewModel.currentUser;
      final currentMatricule = currentUser?.matricule;

      if (currentMatricule != null) {
        _messages = _messages
            .map((msg) => msg.copyWith(isMe: msg.senderId == currentMatricule))
            .toList();
        for (var i = 0; i < _messages.length; i++) {}
      } else {
        print(
            '⚠️ [MessageViewModel.init stream] currentMatricule est NULL, pas de re-normalisation');
      }

      notifyListeners();
    });

    // Écouter les événements typing temps réel
    _typingSubscription =
        _socketService.streamManager.typingStream.listen((event) {
      if (event.conversationId != _conversationId) return;

      final currentUser = _authViewModel.currentUser;
      final currentId = currentUser?.id;
      final currentMatricule = currentUser?.matricule;

      // Ignorer ses propres événements
      if (event.userId == currentId || event.userId == currentMatricule) {
        return;
      }

      if (event.isTyping) {
        _typingUsers.add(event.userId);
      } else {
        _typingUsers.remove(event.userId);
      }

      notifyListeners();
    });
  }

  /// Charger les messages
  Future<void> loadMessages({bool forceRefresh = false}) async {
    print('🚀 [MessageViewModel] loadMessages pour $_conversationId');

    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Charger depuis le cache local d'abord
      final messages = await _messageRepository.getMessages(
        _conversationId,
        forceRefresh: false, // Toujours charger depuis le cache d'abord
      );

      print(
          '📦 [MessageViewModel.loadMessages] ${messages.length} messages reçus du cache');

      _messages = messages;
      _error = null;

      // Déterminer isMe en comparant senderId avec le matricule actuel
      final currentUser = _authViewModel.currentUser;
      final currentMatricule = currentUser?.matricule;

      if (currentMatricule != null) {
        _messages = _messages
            .map((msg) => msg.copyWith(isMe: msg.senderId == currentMatricule))
            .toList();
      } else {
        print(
            '⚠️ [MessageViewModel.loadMessages] currentMatricule est NULL, pas de re-normalisation');
      }

      notifyListeners();

      // Vérifier si on doit charger depuis le serveur
      final totalMessagesInMetadata = _chat?.metadata.stats.totalMessages ?? 0;
      final cachedMessagesCount = messages.length;

      print(
          '📊 [MessageViewModel] Comparaison: cache=$cachedMessagesCount, metadata.stats.totalMessages=$totalMessagesInMetadata');

      if (cachedMessagesCount != totalMessagesInMetadata || forceRefresh) {
        print(
            '🌐 [MessageViewModel] Chargement depuis le serveur (différence détectée ou forceRefresh)');
        await _messageRepository.getMessages(
          _conversationId,
          forceRefresh: true,
        );
      } else {
        print(
            '✅ [MessageViewModel] Cache à jour, pas de chargement serveur nécessaire');
      }

      print('✅ [MessageViewModel] ${_messages.length} messages chargés');
    } catch (e) {
      print('❌ [MessageViewModel] Erreur: $e');
      _error = 'Erreur de chargement';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marquer tous les messages comme lus
  Future<void> markAllAsRead(String conversationId) async {
    try {
      // Les messages sont marqués comme lus automatiquement quand ils sont reçus
      // via MessageRepository._handleNewMessage() qui appelle markMessageRead()
      // pour chaque message non-lu reçu de l'utilisateur actuel.
      print(
          '📖 [MessageViewModel] Les messages sont marqués lus automatiquement');
    } catch (e) {
      print('❌ [MessageViewModel] Erreur markAllAsRead: $e');
    }
  }

  /// Démarrer/rafraîchir le typing
  Future<void> startTyping(
    String conversationId,
    String userId, {
    String status = 'start',
  }) async {
    try {
      await _socketService.startTyping(conversationId, status: status);
    } catch (e) {
      print('❌ [MessageViewModel] Erreur startTyping: $e');
    }
  }

  /// Arrêter le typing
  Future<void> stopTyping(String conversationId, String userId) async {
    try {
      await _socketService.stopTyping(conversationId);
    } catch (e) {
      print('❌ [MessageViewModel] Erreur stopTyping: $e');
    }
  }

  /// Envoyer un message texte
  Future<Message> sendTextMessage({
    required String conversationId,
    required String content,
    required String senderId,
  }) async {
    try {
      return await _messageRepository.sendMessage(
        conversationId: conversationId,
        content: content,
        senderId: senderId,
      );
    } catch (e) {
      print('❌ [MessageViewModel] Erreur sendTextMessage: $e');
      rethrow;
    }
  }

  /// Uploader un fichier (implémentation temporaire)
  Future<Map<String, dynamic>?> uploadFile({
    required String conversationId,
    required String filePath,
    required String fileName,
  }) async {
    // TODO: Implémenter l'upload de fichier
    print('📎 [MessageViewModel] Upload file: $fileName');
    return {'fileId': 'temp_${DateTime.now().millisecondsSinceEpoch}'};
  }

  /// Envoyer un message avec fichier
  Future<Message> sendFileMessage({
    required String conversationId,
    required String content,
    required String senderId,
    required String fileId,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) async {
    try {
      return await _messageRepository.sendMessage(
        conversationId: conversationId,
        content: content,
        senderId: senderId,
        type: MessageType.file,
        fileId: fileId,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
      );
    } catch (e) {
      print('❌ [MessageViewModel] Erreur sendFileMessage: $e');
      rethrow;
    }
  }

  /// Obtenir les utilisateurs en train de taper
  List<String> getTypingUsers(String conversationId) {
    if (conversationId != _conversationId) return [];
    return _typingUsers.toList();
  }

  /// Obtenir les messages (alias pour messages getter)
  List<Message> getMessages(String conversationId) {
    return _messages;
  }

  /// Obtenir l'état de la conversation
  ConversationState getConversationState(String conversationId) {
    // Cette classe n'existe pas encore, on va la créer
    return ConversationState(
      conversationId: conversationId,
      messages: _messages,
      isLoading: _isLoading,
      error: _error,
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    super.dispose();
  }

  /// Mettre à jour le chat avec les nouvelles données (pour les changements de présence)
  void updateChat(Chat updatedChat) {
    if (updatedChat.id == _conversationId) {
      print(
          '🔄 [MessageViewModel] Chat mis à jour: isOnline=${updatedChat.isOnline}');
      _chat = updatedChat;
      notifyListeners(); // ← Notifie l'UI pour rafraîchir la présence
    }
  }
}

/// État d'une conversation
class ConversationState {
  final String conversationId;
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  ConversationState({
    required this.conversationId,
    required this.messages,
    required this.isLoading,
    this.error,
  });

  bool get hasError => error != null && error!.isNotEmpty;
  String get errorMessage => error ?? 'Une erreur inconnue s\'est produite';
}
