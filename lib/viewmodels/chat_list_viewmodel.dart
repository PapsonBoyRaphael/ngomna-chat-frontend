import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'dart:async';

enum ChatFilter {
  all,
  unread,
  myService,
  allServices,
  groups,
  calls,
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

  // Cache pour les badges non lus
  final Map<String, int> _unreadCounts = {};
  int _totalUnreadMessages = 0;

  StreamSubscription? _conversationsSubscription;

  List<Chat> get chats => _filteredChats;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  ChatFilter get currentFilter => _currentFilter;
  int get totalUnreadMessages => _totalUnreadMessages;
  int get unreadConversationsCount =>
      _chats.where((chat) => chat.unreadCount > 0).length;

  ChatListViewModel();

  /// Charger les conversations depuis le backend
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
      // Annuler l'abonnement précédent s'il existe
      _conversationsSubscription?.cancel();

      // Écouter directement les données via le Stream
      print('🔍 Tentative d\'abonnement au conversationsStream...');
      _conversationsSubscription = socketService.conversationsStream.listen(
        (data) {
          print(
              '📩 Données brutes reçues dans ChatListViewModel : ${data.toString()}');
          updateConversations(data);
        },
        onError: (error) {
          print('❌ Erreur lors de l\'écoute des conversations : $error');
          _error = 'Erreur de réception des données';
          notifyListeners();
        },
      );
      print(
          '🔍 Abonnement actif dans ChatListViewModel avant réception des données');
    } catch (e) {
      _error = 'Erreur de chargement: ${e.toString()}';
      print('❌ Erreur loadConversations: $e');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Mettre à jour les conversations avec les données du backend
  void updateConversations(Map<String, dynamic> data) {
    try {
      print(
          '🔄 Mise à jour des conversations dans ChatListViewModel avec ${data.length} éléments');

      // Réinitialiser l'état
      _error = null;
      _isLoading = false;
      _isRefreshing = false;

      // Extraire les conversations depuis les données
      final List<Chat> newChats = _extractConversationsFromData(data);

      // Mettre à jour les chats
      _chats = newChats;

      // Calculer le total des messages non lus
      _calculateUnreadCounts();

      // Appliquer les filtres actuels
      _applyFilter(_currentFilter);
      _applySearch(_searchQuery);

      print(
          '✅ ${_chats.length} conversations chargées, $_totalUnreadMessages messages non lus');
      notifyListeners();
    } catch (e) {
      _error = 'Erreur traitement données: ${e.toString()}';
      print('❌ Erreur updateConversations: $e');
      notifyListeners();
    }
  }

  /// Extraire les conversations des données backend
  List<Chat> _extractConversationsFromData(Map<String, dynamic> data) {
    final List<Chat> conversations = [];

    // Format 1: conversationsLoaded (array direct)
    if (data['conversations'] is List) {
      final conversationsData = data['conversations'] as List<dynamic>;

      for (final convData in conversationsData) {
        try {
          final chat = _convertBackendConversationToChat(convData);
          if (chat != null) {
            conversations.add(chat);
          }
        } catch (e) {
          print('⚠️ Erreur conversion conversation: $e');
        }
      }
    }
    // Format 2: categorized conversations
    else if (data['categorized'] is Map<String, dynamic>) {
      final categorized = data['categorized'] as Map<String, dynamic>;

      // Parcourir toutes les catégories
      for (final category in categorized.values) {
        if (category is List) {
          for (final convData in category) {
            try {
              final chat = _convertBackendConversationToChat(convData);
              if (chat != null) {
                conversations.add(chat);
              }
            } catch (e) {
              print('⚠️ Erreur conversion conversation catégorisée: $e');
            }
          }
        }
      }
    }
    // Format 3: conversationLoaded (single)
    else if (data['type'] == 'single') {
      try {
        final chat = _convertBackendConversationToChat(data['data']);
        if (chat != null) {
          conversations.add(chat);
        }
      } catch (e) {
        print('⚠️ Erreur conversion conversation unique: $e');
      }
    }

    // Trier par dernier message (plus récent en premier)
    conversations.sort((a, b) {
      final aTime = a.lastMessageTime ?? DateTime(1970);
      final bTime = b.lastMessageTime ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  /// Convertir une conversation backend en modèle Chat
  Chat? _convertBackendConversationToChat(dynamic convData) {
    if (convData is! Map<String, dynamic>) return null;

    final data = Map<String, dynamic>.from(convData);

    // Déterminer le type de conversation
    final ChatType type;
    switch (data['type']?.toString().toUpperCase()) {
      case 'GROUP':
        type = ChatType.group;
        break;
      case 'BROADCAST':
        type = ChatType.broadcast;
        break;
      default:
        type = ChatType.personal;
    }

    // Extraire le nom
    String name = data['name']?.toString() ?? 'Conversation';

    // Pour les conversations personnelles, utiliser le nom de l'autre participant
    if (type == ChatType.personal && data['userMetadata'] is Map) {
      final metadata = Map<String, dynamic>.from(data['userMetadata']);
      if (metadata.isNotEmpty) {
        final firstUser = metadata.values.first;
        if (firstUser is Map) {
          final userData = Map<String, dynamic>.from(firstUser);
          name = '${userData['prenom']} ${userData['nom']}'.trim();
          if (name.isEmpty) {
            name = userData['matricule']?.toString() ?? 'Utilisateur';
          }
        }
      }
    }

    // Extraire les participants
    final List<Map<String, dynamic>> participants = [];
    if (data['participants'] is List) {
      for (final participant in data['participants'] as List<dynamic>) {
        if (participant is Map<String, dynamic>) {
          participants.add(Map<String, dynamic>.from(participant));
        }
      }
    }

    // Extraire le dernier message
    String lastMessage = '';
    DateTime? lastMessageTime;
    if (data['lastMessage'] is Map<String, dynamic>) {
      final lastMsg = Map<String, dynamic>.from(data['lastMessage']);
      lastMessage = lastMsg['content']?.toString() ?? '';

      if (lastMsg['timestamp'] != null) {
        try {
          lastMessageTime = DateTime.parse(lastMsg['timestamp'].toString());
        } catch (e) {
          print('⚠️ Erreur parsing timestamp: $e');
        }
      }
    }

    // Compter les messages non lus
    int unreadCount = 0;
    if (data['unreadCount'] != null) {
      unreadCount = (data['unreadCount'] as num).toInt();
    } else if (data['stats'] is Map) {
      final stats = Map<String, dynamic>.from(data['stats']);
      unreadCount = stats['unreadMessages'] as int? ?? 0;
    }

    // Mettre à jour le cache des non lus
    final conversationId =
        data['_id']?.toString() ?? data['id']?.toString() ?? '';
    if (conversationId.isNotEmpty) {
      _unreadCounts[conversationId] = unreadCount;
    }

    return Chat(
      id: conversationId,
      name: name,
      type: type,
      avatarUrl:
          data['avatar']?.toString() ?? '', // Fournir une valeur par défaut
      time: data['time']?.toString() ?? '', // Fournir une valeur par défaut

      // Supprimer la méthode inutile `useSocketService`
      // et laisser le champ inutilisé pour le moment.

      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      participants: participants,
      metadata: data,
    );
  }

  /// Calculer les totaux de messages non lus
  void _calculateUnreadCounts() {
    _totalUnreadMessages = 0;

    for (final chat in _chats) {
      _totalUnreadMessages += chat.unreadCount;
      _unreadCounts[chat.id] = chat.unreadCount;
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
        _filteredChats = _chats.where((chat) => chat.unreadCount > 0).toList();
        break;
      case ChatFilter.groups:
        _filteredChats =
            _chats.where((chat) => chat.type == ChatType.group).toList();
        break;
      case ChatFilter.myService:
        // TODO: Implémenter basé sur le ministère/département de l'utilisateur
        _filteredChats = List.from(_chats);
        break;
      case ChatFilter.allServices:
        // TODO: Implémenter filtrage par service
        _filteredChats = List.from(_chats);
        break;
      case ChatFilter.calls:
        // TODO: Filtrer les conversations avec appels
        _filteredChats = _chats.where((chat) => false).toList(); // Temporaire
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
      return chat.name.toLowerCase().contains(searchLower) ||
          chat.lastMessage.toLowerCase().contains(searchLower) ||
          chat.participants.any((participant) {
            final name =
                '${participant['prenom']} ${participant['nom']}'.toLowerCase();
            return name.contains(searchLower);
          });
    }).toList();
  }

  /// Gérer la réception d'un nouveau message
  void onNewMessageReceived(Map<String, dynamic> messageData) {
    try {
      final message = messageData;
      final conversationId = message['conversationId']?.toString();

      if (conversationId == null || conversationId.isEmpty) return;

      // Trouver la conversation
      final index = _chats.indexWhere((chat) => chat.id == conversationId);

      if (index != -1) {
        // Mettre à jour la conversation existante
        final chat = _chats[index];

        // Incrémenter le compteur non lu
        final newUnreadCount = chat.unreadCount + 1;
        _unreadCounts[conversationId] = newUnreadCount;
        _totalUnreadMessages++;

        // Mettre à jour le dernier message
        final updatedChat = chat.copyWith(
          lastMessage: message['content']?.toString() ?? '',
          lastMessageTime: DateTime.now(),
          unreadCount: newUnreadCount,
        );

        _chats[index] = updatedChat;

        // Déplacer en haut de la liste
        _chats.removeAt(index);
        _chats.insert(0, updatedChat);

        // Re-appliquer les filtres
        _applyFilter(_currentFilter);
        _applySearch(_searchQuery);

        notifyListeners();

        print(
            '📥 Nouveau message dans "${chat.name}", non lus: $newUnreadCount');
      }
    } catch (e) {
      print('❌ Erreur traitement nouveau message: $e');
    }
  }

  /// Marquer une conversation comme lue
  void markConversationAsRead(String conversationId) {
    final index = _chats.indexWhere((chat) => chat.id == conversationId);

    if (index != -1 && _chats[index].unreadCount > 0) {
      final chat = _chats[index];
      final previousUnread = chat.unreadCount;

      // Mettre à jour localement
      _chats[index] = chat.copyWith(unreadCount: 0);
      _unreadCounts[conversationId] = 0;
      _totalUnreadMessages -= previousUnread;

      // Re-appliquer les filtres
      _applyFilter(_currentFilter);
      _applySearch(_searchQuery);

      notifyListeners();

      print('✅ Conversation "${chat.name}" marquée comme lue');
    }
  }

  /// Effacer les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Définir une erreur explicitement
  void setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  /// Obtenir le nombre de messages non lus pour une conversation
  int getUnreadCountForConversation(String conversationId) {
    return _unreadCounts[conversationId] ?? 0;
  }

  /// Nettoyer les ressources
  void dispose() {
    _chats.clear();
    _filteredChats.clear();
    _unreadCounts.clear();
    _conversationsSubscription?.cancel();
    super.dispose();
  }
}
