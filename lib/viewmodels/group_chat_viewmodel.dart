import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/group_message_model.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/repositories/group_chat_repository.dart';
import 'package:ngomna_chat/data/services/chat_stream_manager.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';

class GroupChatViewModel extends ChangeNotifier {
  final GroupChatRepository _repository;
  final String groupId;
  Chat? _chat;

  List<GroupMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  final Set<String> _typingUsers = {};

  // Subscription pour les mises à jour en temps réel
  StreamSubscription<List<GroupMessage>>? _messagesSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;

  List<GroupMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  /// Données de la conversation (avec présence)
  Chat? get chat => _chat;

  /// Nombre d'utilisateurs en ligne dans le groupe
  int get onlineCount => _chat?.presenceStats?.onlineCount ?? 0;

  /// Nombre total de participants
  int get totalParticipants => _chat?.participants.length ?? 0;

  /// ID du créateur du groupe
  String? get createdById => _chat?.createdBy;

  /// Nom du créateur du groupe
  String get creatorName {
    if (_chat == null) return 'Quelqu\'un';

    // Chercher le créateur dans les participants metadata
    final creatorId = _chat!.createdBy;
    final creatorMetadata =
        _chat!.userMetadata.cast<ParticipantMetadata?>().firstWhere(
              (meta) =>
                  meta?.userId == creatorId || meta?.metadataId == creatorId,
              orElse: () => null,
            );

    if (creatorMetadata != null) {
      // Utiliser seulement le prénom si disponible et valide
      // Sinon utiliser nom + prenom
      if (creatorMetadata.prenomDisplay.isNotEmpty &&
          creatorMetadata.prenomDisplay.length < 50) {
        return creatorMetadata.prenomDisplay.trim();
      }

      final fullName = creatorMetadata.name.trim();
      if (fullName.isNotEmpty && fullName.length < 100) {
        return fullName;
      }
    }

    return 'Le créateur';
  }

  /// Date de création du groupe
  DateTime? get createdAt => _chat?.createdAt;

  GroupChatViewModel(
      this._repository, this.groupId, Map<String, dynamic>? conversationData)
      : _chat =
            conversationData != null ? Chat.fromJson(conversationData) : null;

  /// Initialiser le ViewModel (appelé après construction)
  Future<void> init() async {
    print('🚀 [GroupChatViewModel] init() pour groupe $groupId');

    // Charger les messages initiaux
    await loadMessages();

    // 🟢 NOUVEAU: Écouter les mises à jour en temps réel
    _messagesSubscription = _repository.watchGroupMessages(groupId).listen(
      (messages) {
        print(
            '📨 [GroupChatViewModel] Mises à jour temps réel: ${messages.length} messages');
        _messages = messages;
        notifyListeners(); // ← Notifie l'UI de rafraîchir
      },
      onError: (error) {
        print('❌ [GroupChatViewModel] Erreur dans le stream: $error');
        _error = 'Erreur de synchronisation';
        notifyListeners();
      },
    );

    // Écouter les événements typing temps réel
    _typingSubscription =
        _repository.socketService.streamManager.typingStream.listen((event) {
      if (event.conversationId != groupId) return;

      final storageService = StorageService();
      final currentUser = storageService.getUser();
      final currentId = currentUser?.id;
      final currentMatricule = currentUser?.matricule;

      // Ignorer ses propres événements
      if (event.userId == currentId || event.userId == currentMatricule) {
        return;
      }

      print(
          '⌨️ [GroupChatViewModel] Typing event: userId=${event.userId}, isTyping=${event.isTyping}');

      if (event.isTyping) {
        _typingUsers.add(event.userId);
        print('✅ [GroupChatViewModel] Typing users: $_typingUsers');
      } else {
        _typingUsers.remove(event.userId);
        print('❌ [GroupChatViewModel] Typing users: $_typingUsers');
      }

      notifyListeners();
    });
  }

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.getGroupMessages(groupId);

      // Vérifier si on doit charger depuis le serveur
      final totalMessagesInMetadata = _chat?.metadata.stats.totalMessages ?? 0;
      final cachedMessagesCount = _messages.length;

      print(
          '📊 [GroupChatViewModel] Comparaison: cache=$cachedMessagesCount, metadata.stats.totalMessages=$totalMessagesInMetadata');

      if (cachedMessagesCount != totalMessagesInMetadata) {
        print(
            '🌐 [GroupChatViewModel] Chargement depuis le serveur (différence détectée)');
        // TODO: Implémenter le chargement depuis le serveur pour groupe
        // await _repository.getGroupMessagesFromServer(groupId);
      } else {
        print(
            '✅ [GroupChatViewModel] Cache à jour, pas de chargement serveur nécessaire');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ [GroupChatViewModel] Erreur loadMessages: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _isSending = true;
    notifyListeners();

    try {
      final sentMessage = await _repository.sendGroupMessage(groupId, text);
      _messages.add(sentMessage);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ [GroupChatViewModel] Erreur sendMessage: $e');
    }

    _isSending = false;
    notifyListeners();
  }

  /// Obtenir les utilisateurs en train de taper
  List<String> getTypingUsers(String conversationId) {
    return _typingUsers.toList();
  }

  /// Démarrer/rafraîchir le typing
  Future<void> startTyping(String conversationId,
      {String status = 'start'}) async {
    try {
      await _repository.socketService
          .startTyping(conversationId, status: status);
    } catch (e) {
      print('❌ [GroupChatViewModel] Erreur startTyping: $e');
    }
  }

  /// Arrêter le typing
  Future<void> stopTyping(String conversationId) async {
    try {
      await _repository.socketService.stopTyping(conversationId);
    } catch (e) {
      print('❌ [GroupChatViewModel] Erreur stopTyping: $e');
    }
  }

  @override
  void dispose() {
    print('🧹 [GroupChatViewModel] dispose() - fermeture des subscriptions');
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    super.dispose();
  }

  /// Mettre à jour le chat avec les nouvelles données (pour les changements de présence)
  void updateChat(Chat updatedChat) {
    if (updatedChat.id == groupId) {
      print(
          '🔄 [GroupChatViewModel] Chat mis à jour: présence=${updatedChat.presenceStats?.onlineCount} en ligne');
      _chat = updatedChat;
      notifyListeners(); // ← Notifie l'UI pour rafraîchir onlineCount, etc.
    }
  }
}
