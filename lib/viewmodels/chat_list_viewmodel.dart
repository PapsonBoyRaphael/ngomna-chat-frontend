import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';
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

  final SocketService socketService = SocketService();
  final HiveService hiveService = HiveService();

  // Cache pour les badges non lus (par userId)
  final Map<String, Map<String, int>> _userUnreadCounts = {};
  int _totalUnreadMessages = 0;

  StreamSubscription? _newMessageSubscription;

  List<Chat> get chats => _filteredChats;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  ChatFilter get currentFilter => _currentFilter;
  int get totalUnreadMessages => _totalUnreadMessages;

  // Nombre de conversations avec messages non lus pour l'utilisateur courant
  int get unreadConversationsCount {
    final currentUserId = 'current_user_id_placeholder';
    return _chats.where((chat) {
      final userCount = chat.unreadCounts[currentUserId] ?? 0;
      return userCount > 0;
    }).length;
  }

  ChatListViewModel() {
    _initializeSocketListeners();
  }

  /// Initialiser les écouteurs Socket.IO
  void _initializeSocketListeners() {
    print('🔌 Initialisation des écouteurs Socket.IO dans ChatListViewModel');

    // Annuler les abonnements précédents
    _newMessageSubscription?.cancel();

    // Écouter les nouveaux messages
    _newMessageSubscription = socketService.messageStream.listen((message) {
      print('📨 Nouveau message reçu');
      _handleNewMessage(message.toJson());
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
      print('🔄 Chargement des conversations...');

      // Essayer de charger depuis Hive d'abord
      final cachedChats = await hiveService.getAllChats();

      if (cachedChats.isNotEmpty && !forceRefresh) {
        print(
            '💾 Utilisation du cache Hive: ${cachedChats.length} conversations');
        _updateChatsFromHive(cachedChats);
        return;
      }

      // Sinon, demander au serveur
      print('🌐 Demande des conversations au serveur...');
      socketService.requestConversations();

      // Attendre que les données soient sauvegardées dans Hive
      await Future.delayed(const Duration(seconds: 2));

      // Recharger depuis Hive
      final freshChats = await hiveService.getAllChats();
      if (freshChats.isNotEmpty) {
        print('✅ Conversations chargées depuis serveur: ${freshChats.length}');
        _updateChatsFromHive(freshChats);
      } else {
        print('⚠️ Aucune conversation reçue du serveur');
        _error = 'Aucune conversation disponible';
      }
    } catch (e) {
      _error = 'Erreur de chargement: ${e.toString()}';
      print('❌ Erreur loadConversations: $e');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Mettre à jour les chats depuis Hive
  void _updateChatsFromHive(List<Chat> chats) {
    // Trier par dernier message (plus récent en premier)
    chats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    _chats = chats;
    _calculateUnreadCounts();
    _applyFilter(_currentFilter);
    _applySearch(_searchQuery);
    print('✅ ${_chats.length} conversations mises à jour depuis Hive');
    notifyListeners();
  }

  /// Mettre à jour les conversations
  void updateConversations(Map<String, dynamic> data) {
    try {
      print('🔄 Mise à jour des conversations');

      // Vérifier la structure des données
      bool hasValidData = false;

      if (data['conversations'] is List &&
          (data['conversations'] as List).isNotEmpty) {
        hasValidData = true;
        print(
            '✅ Format 1: conversations array avec ${(data['conversations'] as List).length} éléments');
      } else if (data['categorized'] is Map) {
        final categorized = data['categorized'] as Map<String, dynamic>;
        int total = 0;
        categorized.forEach((key, value) {
          if (value is List) total += value.length;
        });
        if (total > 0) {
          hasValidData = true;
          print('✅ Format 2: categorized avec $total conversations');
        }
      } else if (data['type'] == 'single' && data['data'] != null) {
        hasValidData = true;
        print('✅ Format 3: conversation unique');
      }

      if (!hasValidData) {
        print('⚠️ Données sans conversations valides');
        _error = 'Aucune conversation disponible';
        notifyListeners();
        return;
      }

      // Réinitialiser l'état
      _error = null;
      _isLoading = false;
      _isRefreshing = false;

      // Extraire les conversations
      final List<Chat> newChats = _extractConversationsFromData(data);

      // Mettre à jour
      _chats = newChats;

      // Calculer les totaux
      _calculateUnreadCounts();

      // Appliquer filtres
      _applyFilter(_currentFilter);
      _applySearch(_searchQuery);

      print('✅ ${_chats.length} conversations chargées');
      notifyListeners();
    } catch (e) {
      _error = 'Erreur traitement données: ${e.toString()}';
      print('❌ Erreur updateConversations: $e');
      notifyListeners();
    }
  }

  /// Extraire les conversations
  List<Chat> _extractConversationsFromData(Map<String, dynamic> data) {
    final List<Chat> conversations = [];

    print(
        '🔍 ChatListViewModel - Structure des données: ${data.keys.toList()}');
    print(
        '🔍 ChatListViewModel - Type de conversations: ${data['conversations']?.runtimeType}');

    // Format 1: array direct
    if (data['conversations'] is List) {
      final conversationsData = data['conversations'] as List<dynamic>;

      for (final convData in conversationsData) {
        try {
          final chat = Chat.fromJson(convData); // ✅ Utilise le nouveau fromJson
          conversations.add(chat);
        } catch (e) {
          print('⚠️ Erreur conversion conversation: $e - Data: $convData');
        }
      }
    }
    // Format 2: categorized
    else if (data['categorized'] is Map<String, dynamic>) {
      final categorized = data['categorized'] as Map<String, dynamic>;

      for (final category in categorized.values) {
        if (category is List) {
          for (final convData in category) {
            try {
              final chat = Chat.fromJson(convData);
              conversations.add(chat);
            } catch (e) {
              print('⚠️ Erreur conversion conversation catégorisée: $e');
            }
          }
        }
      }
    }
    // Format 3: single
    else if (data['type'] == 'single' && data['data'] != null) {
      try {
        final chat = Chat.fromJson(data['data']);
        conversations.add(chat);
      } catch (e) {
        print('⚠️ Erreur conversion conversation unique: $e');
      }
    }
    // Format 4: Map direct (clé = ID conversation, valeur = données conversation)
    else if (data.isNotEmpty && data.values.first is Map<String, dynamic>) {
      print(
          '🔄 ChatListViewModel - Tentative de traitement comme Map de conversations');
      for (final convData in data.values) {
        if (convData is Map<String, dynamic>) {
          try {
            final chat = Chat.fromJson(convData);
            conversations.add(chat);
            print('✅ ChatListViewModel - Conversation extraite: ${chat.name}');
          } catch (e) {
            print(
                '⚠️ ChatListViewModel - Erreur conversion conversation Map: $e');
          }
        }
      }
    }

    // Trier par dernier message
    conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    return conversations;
  }

  /// Calculer les totaux de messages non lus
  void _calculateUnreadCounts() {
    _totalUnreadMessages = 0;
    _userUnreadCounts.clear();

    // TODO: Remplacer par le userId de l'utilisateur connecté
    final currentUserId = 'current_user_id_placeholder';

    for (final chat in _chats) {
      final userUnread = chat.unreadCounts[currentUserId] ?? 0;
      _totalUnreadMessages += userUnread;

      // Stocker par conversation et utilisateur
      if (!_userUnreadCounts.containsKey(chat.id)) {
        _userUnreadCounts[chat.id] = {};
      }
      _userUnreadCounts[chat.id]![currentUserId] = userUnread;
    }
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
        // TODO: Filtrer par userId connecté
        final currentUserId = 'current_user_id_placeholder';
        _filteredChats = _chats.where((chat) {
          return (chat.unreadCounts[currentUserId] ?? 0) > 0;
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
        // TODO: Implémenter filtrage par service
        _filteredChats = List.from(_chats);
        break;
    }
  }

  /// Rechercher dans les conversations
  Future<void> searchChats(String query) async {
    _searchQuery = query;
    _applySearch(query);
    notifyListeners();
  }

  void _applySearch(String query) {
    if (query.isEmpty) {
      _applyFilter(_currentFilter);
      return;
    }

    final searchLower = query.toLowerCase();
    _filteredChats = _chats.where((chat) {
      // Recherche dans le nom d'affichage
      if (chat.displayName.toLowerCase().contains(searchLower)) {
        return true;
      }

      // Recherche dans le dernier message
      if (chat.lastMessage?.content.toLowerCase().contains(searchLower) ??
          false) {
        return true;
      }

      // Recherche dans les participants
      for (final participant in chat.userMetadata) {
        if (participant.name.toLowerCase().contains(searchLower)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  /// Gérer un nouveau message
  void _handleNewMessage(Map<String, dynamic> messageData) {
    try {
      final conversationId = messageData['conversationId']?.toString();
      final senderId = messageData['senderId']?.toString();

      if (conversationId == null || conversationId.isEmpty) return;

      // Trouver la conversation
      final index = _chats.indexWhere((chat) => chat.id == conversationId);

      if (index != -1) {
        // Mettre à jour la conversation existante
        final chat = _chats[index];

        // Créer un nouveau LastMessage
        final lastMessage = LastMessage(
          content: messageData['content']?.toString() ?? 'Nouveau message',
          type: messageData['type']?.toString() ?? 'TEXT',
          senderId: senderId ?? '',
          senderName: messageData['senderName']?.toString(),
          timestamp: DateTime.now(),
        );

        // Mettre à jour les unread counts
        final newUnreadCounts = Map<String, int>.from(chat.unreadCounts);
        // Incrémenter pour tous les participants sauf l'expéditeur
        for (final participant in chat.participants) {
          if (participant != senderId) {
            newUnreadCounts[participant] =
                (newUnreadCounts[participant] ?? 0) + 1;
          }
        }

        // Mettre à jour la conversation
        final updatedChat = chat.copyWith(
          lastMessage: lastMessage,
          lastMessageAt: DateTime.now(),
          unreadCounts: newUnreadCounts,
        );

        _chats[index] = updatedChat;

        // Déplacer en haut de la liste
        _chats.removeAt(index);
        _chats.insert(0, updatedChat);

        // Recalculer les totaux
        _calculateUnreadCounts();

        // Re-appliquer les filtres
        _applyFilter(_currentFilter);
        _applySearch(_searchQuery);

        notifyListeners();

        print('✅ Message ajouté à "${chat.displayName}"');
      } else {
        print('🆕 Nouvelle conversation détectée, rechargement...');
        loadConversations();
      }
    } catch (e) {
      print('❌ Erreur traitement nouveau message: $e');
    }
  }

  /// Marquer une conversation comme lue
  void markConversationAsRead(String conversationId) {
    final index = _chats.indexWhere((chat) => chat.id == conversationId);

    if (index != -1) {
      final chat = _chats[index];
      // TODO: Remplacer par le userId connecté
      final currentUserId = 'current_user_id_placeholder';

      if (chat.unreadCounts[currentUserId] != null &&
          chat.unreadCounts[currentUserId]! > 0) {
        // Mettre à jour localement
        final newUnreadCounts = Map<String, int>.from(chat.unreadCounts);
        final previousUnread = newUnreadCounts[currentUserId] ?? 0;
        newUnreadCounts[currentUserId] = 0;

        final updatedChat = chat.copyWith(unreadCounts: newUnreadCounts);
        _chats[index] = updatedChat;

        // Mettre à jour le cache
        if (_userUnreadCounts.containsKey(conversationId)) {
          _userUnreadCounts[conversationId]![currentUserId] = 0;
        }

        // Mettre à jour le total
        _totalUnreadMessages -= previousUnread;

        // Re-appliquer les filtres
        _applyFilter(_currentFilter);
        _applySearch(_searchQuery);

        notifyListeners();

        print('✅ Conversation "${chat.displayName}" marquée comme lue');

        // TODO: Notifier le serveur via socket
        // socketService.markConversationAsRead(conversationId, currentUserId);
      }
    }
  }

  /// Obtenir les conversations non lues pour un utilisateur
  List<Chat> getUnreadChatsForUser(String userId) {
    return _chats.where((chat) {
      return (chat.unreadCounts[userId] ?? 0) > 0;
    }).toList();
  }

  int getUnreadCountForConversation(String conversationId, String userId) {
    final chat = _chats.firstWhere((c) => c.id == conversationId,
        orElse: () => Chat.empty());
    return chat.unreadCounts[userId] ?? 0;
  }

  /// Obtenir une conversation par ID
  Chat? getChatById(String chatId) {
    return _chats.firstWhere((chat) => chat.id == chatId,
        orElse: () => Chat.empty());
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
    _newMessageSubscription?.cancel();
    _chats.clear();
    _filteredChats.clear();
    _userUnreadCounts.clear();
    super.dispose();
  }
}
