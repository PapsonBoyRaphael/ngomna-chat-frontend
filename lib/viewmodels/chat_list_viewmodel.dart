import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/repositories/chat_list_repository.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'package:ngomna_chat/core/utils/date_formatter.dart';
import 'package:ngomna_chat/data/services/chat_stream_manager.dart';
import 'dart:async';

enum ChatFilter {
  all,
  unread,
  myService,
  allServices,
  groups,
  broadcasts,
  calls
}

class ChatListViewModel extends ChangeNotifier {
  List<Chat> _chats = [];
  List<Chat> _filteredChats = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  ChatFilter _currentFilter = ChatFilter.all;
  String _searchQuery = '';

  final ChatListRepository _chatListRepository;
  StreamSubscription<List<Chat>>? _chatsSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;
  Timer? _dateRefreshTimer;

  // Cache pour les badges non lus (par userId)
  final Map<String, Map<String, int>> _userUnreadCounts = {};
  int _totalUnreadMessages = 0;

  // Tracking des utilisateurs en train d'écrire par conversation
  final Map<String, Set<String>> _typingUsersByConversation = {};

  List<Chat> get chats => _filteredChats;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  ChatFilter get currentFilter => _currentFilter;
  int get totalUnreadMessages => _totalUnreadMessages;

  // Nombre de conversations avec messages non lus pour l'utilisateur courant
  int get unreadConversationsCount {
    return _chats.where((chat) => chat.unreadCount > 0).length;
  }

  // Récupérer les utilisateurs en train d'écrire dans une conversation
  bool isTypingInConversation(String conversationId) {
    final typingUsers = _typingUsersByConversation[conversationId] ?? {};
    return typingUsers.isNotEmpty;
  }

  /// Retourner un libellé de typing adapté au type de conversation
  String? getTypingLabel(Chat chat) {
    final typingUsers = _typingUsersByConversation[chat.id] ?? {};
    if (typingUsers.isEmpty) return null;

    if (chat.type == ChatType.group) {
      final names = typingUsers
          .map((userId) => _resolveUserName(chat, userId))
          .where((name) => name.isNotEmpty)
          .toList();

      if (names.isEmpty) {
        return 'Quelqu\'un écrit...';
      }

      if (names.length == 1) {
        return '${names.first} écrit...';
      }

      if (names.length == 2) {
        return '${names[0]} et ${names[1]} écrivent...';
      }

      return '${names[0]} et ${names.length - 1} autres écrivent...';
    }

    return 'en train d\'écrire...';
  }

  ChatListViewModel({
    required ChatListRepository chatListRepository,
  }) : _chatListRepository = chatListRepository {
    _initializeStreams();
    _startDateAutoRefresh();
  }

  /// Démarrer l'auto-refresh des dates (toutes les minutes)
  void _startDateAutoRefresh() {
    print('⏰ Démarrage auto-refresh des dates dans ChatListViewModel');

    // Ajouter ce ViewModel comme listener
    LiveDateFormatter.addListener(_onDateRefresh);

    // Démarrer le timer global
    LiveDateFormatter.startAutoRefresh();
  }

  /// Callback appelé quand les dates doivent se rafraîchir
  void _onDateRefresh() {
    print('🕐 ChatListViewModel: Rafraîchissement des dates');
    notifyListeners();
  }

  /// Initialiser les streams
  void _initializeStreams() {
    print('🔌 Initialisation des streams dans ChatListViewModel');

    // Écouter les mises à jour des conversations
    _chatsSubscription = _chatListRepository.chatsStream.listen((chats) {
      print('📨 Conversations mises à jour: ${chats.length}');
      _updateChatsFromRepository(chats);
    });

    // Écouter les événements typing pour toutes les conversations
    _typingSubscription = _chatListRepository
        .socketService.streamManager.typingStream
        .listen((event) {
      final storageService = StorageService();
      final currentUser = storageService.getUser();
      final currentId = currentUser?.id;
      final currentMatricule = currentUser?.matricule;

      // Ignorer ses propres événements
      if (event.userId == currentId || event.userId == currentMatricule) {
        return;
      }

      print(
          '⌨️ [ChatListViewModel] Typing event: conversationId=${event.conversationId}, userId=${event.userId}, isTyping=${event.isTyping}');

      // Initialiser le Set si nécessaire
      if (!_typingUsersByConversation.containsKey(event.conversationId)) {
        _typingUsersByConversation[event.conversationId] = {};
      }

      final typingUsers = _typingUsersByConversation[event.conversationId]!;

      if (event.isTyping) {
        typingUsers.add(event.userId);
        print(
            '✅ [ChatListViewModel] ${typingUsers.length} utilisateur(s) en train d\'écrire dans ${event.conversationId}');
      } else {
        typingUsers.remove(event.userId);
        print(
            '❌ [ChatListViewModel] ${typingUsers.length} utilisateur(s) en train d\'écrire dans ${event.conversationId}');
      }

      notifyListeners();
    });
  }

  /// Charger les conversations
  Future<void> loadConversations({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    if (forceRefresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }

    _error = null;
    notifyListeners();

    try {
      print('🔄 Chargement des conversations via repository...');

      // Charger via le repository (qui gère le cache et les appels serveur)
      final chats = await _chatListRepository.loadConversations(
          forceRefresh: forceRefresh);

      print('✅ Conversations chargées: ${chats.length}');
      _updateChatsFromRepository(chats);
    } catch (e) {
      _error = 'Erreur de chargement: ${e.toString()}';
      print('❌ Erreur loadConversations: $e');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Mettre à jour les conversations depuis le repository
  void _updateChatsFromRepository(List<Chat> chats) {
    // Trier par dernier message (plus récent en premier)
    chats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    _chats = chats;
    _calculateUnreadCounts();
    _applyFilter(_currentFilter);
    _applySearch(_searchQuery);
    print('✅ ${_chats.length} conversations mises à jour depuis repository');
    for (var i = 0; i < chats.length && i < 3; i++) {
      print(
          '   - [$i] ${chats[i].displayName}: lastMessage="${chats[i].lastMessage?.content}", lastMessageAt=${chats[i].lastMessageAt.toIso8601String()}');
    }
    print('🔔 notifyListeners() appelé - UI devrait se mettre à jour');
    notifyListeners();
  }

  /// Calculer les totaux des messages non lus
  void _calculateUnreadCounts() {
    _totalUnreadMessages = 0;
    _userUnreadCounts.clear();

    // Récupérer l'utilisateur actuel
    final storageService = StorageService();
    final currentUser = storageService.getUser();
    final currentUserId = currentUser?.matricule ?? currentUser?.id ?? '';

    for (final chat in _chats) {
      final userUnread = chat
          .unreadCount; // Utiliser le getter qui calcule pour l'utilisateur actuel
      _totalUnreadMessages += userUnread;

      // Stocker par conversation et utilisateur
      if (!_userUnreadCounts.containsKey(chat.id)) {
        _userUnreadCounts[chat.id] = {};
      }
      _userUnreadCounts[chat.id]![currentUserId] = userUnread;
    }
  }

  String _resolveUserName(Chat chat, String userId) {
    final meta = chat.userMetadata.firstWhere(
      (m) => m.userId == userId,
      orElse: () => ParticipantMetadata(
        userId: '',
        unreadCount: 0,
        isMuted: false,
        isPinned: false,
        notificationSettings: NotificationSettings(
          enabled: true,
          sound: true,
          vibration: true,
        ),
        nom: '',
        prenom: '',
        metadataId: '',
      ),
    );

    return meta.prenom.trim();
  }

  /// Appliquer un filtre
  Future<void> setFilter(ChatFilter filter) async {
    _currentFilter = filter;
    _applyFilter(filter);
    notifyListeners();
  }

  void _applyFilter(ChatFilter filter) {
    switch (filter) {
      case ChatFilter.all:
        _filteredChats = List.from(_chats);
        break;
      case ChatFilter.unread:
        // Filtrer les conversations avec des messages non lus pour l'utilisateur actuel
        _filteredChats = _chats.where((chat) {
          return chat.unreadCount > 0;
        }).toList();
        break;
      case ChatFilter.groups:
        _filteredChats =
            _chats.where((chat) => chat.type == ChatType.group).toList();
        break;
      case ChatFilter.broadcasts:
        _filteredChats =
            _chats.where((chat) => chat.type == ChatType.broadcast).toList();
        break;
      case ChatFilter.calls:
        _filteredChats =
            _chats.where((chat) => chat.type == ChatType.channel).toList();
        break;
      case ChatFilter.myService:
        // TODO: Implémenter basé sur le ministère
        _filteredChats = List.from(_chats);
        break;
      case ChatFilter.allServices:
        // TODO: Implémenter basé sur les services
        _filteredChats = List.from(_chats);
        break;
    }
  }

  /// Rechercher des conversations
  void searchChats(String query) {
    _searchQuery = query;
    _applySearch(query);
    notifyListeners();
  }

  void _applySearch(String query) {
    if (query.isEmpty) {
      _filteredChats = List.from(_chats);
    } else {
      _filteredChats = _chats.where((chat) {
        final displayName = chat.displayName.toLowerCase();
        final searchLower = query.toLowerCase();
        return displayName.contains(searchLower);
      }).toList();
    }
  }

  /// Obtenir une conversation par ID
  Chat? getChatById(String chatId) {
    return _chats.firstWhere((chat) => chat.id == chatId,
        orElse: () => Chat.empty());
  }

  /// Marquer une conversation comme lue
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      // Récupérer l'utilisateur actuel
      final storageService = StorageService();
      final currentUser = storageService.getUser();
      final currentUserId = currentUser?.matricule ?? currentUser?.id ?? '';

      await _chatListRepository.markChatAsRead(conversationId, currentUserId);
      print('✅ Conversation $conversationId marquée comme lue');
    } catch (e) {
      print('❌ Erreur markConversationAsRead: $e');
    }
  }

  /// Effacer les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Définir une erreur
  void setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  /// Nettoyer les ressources
  @override
  void dispose() {
    print('🧹 Nettoyage ChatListViewModel');

    // Arrêter l'auto-refresh des dates
    LiveDateFormatter.removeListener(_onDateRefresh);

    _chatsSubscription?.cancel();
    _typingSubscription?.cancel();
    _dateRefreshTimer?.cancel();
    _chats.clear();
    _filteredChats.clear();
    _userUnreadCounts.clear();
    _typingUsersByConversation.clear();
    super.dispose();
  }
}
