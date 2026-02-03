import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/repositories/message_repository.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/viewmodels/auth_viewmodel.dart';

class MessageViewModel extends ChangeNotifier {
  final MessageRepository _messageRepository;
  final SocketService _socketService;
  final String _conversationId;
  final AuthViewModel _authViewModel;

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MessageViewModel({
    required MessageRepository messageRepository,
    required String conversationId,
    required AuthViewModel authViewModel,
  })  : _messageRepository = messageRepository,
        _socketService = messageRepository
            .socketService, // On accède au socketService via messageRepository
        _conversationId = conversationId,
        _authViewModel = authViewModel;

  StreamSubscription<List<Message>>? _messagesSubscription;

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
  }

  Timer? _pollingTimer;

  /// Charger les messages
  Future<void> loadMessages({bool forceRefresh = false}) async {
    print('🚀 [MessageViewModel] loadMessages pour $_conversationId');

    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final messages = await _messageRepository.getMessages(
        _conversationId,
        forceRefresh: forceRefresh,
      );

      print(
          '📦 [MessageViewModel.loadMessages] ${messages.length} messages reçus du repository');
      for (var i = 0; i < messages.length; i++) {}

      _messages = messages;
      _error = null;

      // Déterminer isMe en comparant senderId avec le matricule actuel
      final currentUser = _authViewModel.currentUser;
      final currentMatricule = currentUser?.matricule;

      if (currentMatricule != null) {
        _messages = _messages
            .map((msg) => msg.copyWith(isMe: msg.senderId == currentMatricule))
            .toList();
        for (var i = 0; i < _messages.length; i++) {}
      } else {
        print(
            '⚠️ [MessageViewModel.loadMessages] currentMatricule est NULL, pas de re-normalisation');
      }
      // Si currentMatricule est null, garder isMe tel quel

      notifyListeners();

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
      // Marquer tous les messages comme lus dans le cache local
      final messages = _messages;
      for (final message in messages) {
        if (message.status != MessageStatus.read) {
          // TODO: Mettre à jour le statut local
        }
      }

      // Informer le serveur via Socket.IO
      await _socketService.markMessageRead(
          '', conversationId); // TODO: Implémenter markAllAsRead côté serveur
    } catch (e) {
      print('❌ [MessageViewModel] Erreur markAllAsRead: $e');
    }
  }

  /// Démarrer le typing
  Future<void> startTyping(String conversationId, String userId) async {
    try {
      await _socketService.startTyping(conversationId);
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
    // Cette méthode devrait retourner la liste des utilisateurs en train de taper
    // Pour l'instant, on retourne une liste vide
    return [];
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
    super.dispose();
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
