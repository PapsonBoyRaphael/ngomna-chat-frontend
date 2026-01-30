import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';

class SocketService {
  static const String _socketUrl = 'http://localhost:8003'; // Gateway
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _reconnectInterval = Duration(seconds: 3);
  static const int _maxReconnectAttempts = 5;

  late io.Socket _socket;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  String? _userId;
  String? _matricule;
  String? _accessToken;

  final HiveService _hiveService = HiveService();

  // Stream controllers pour les événements
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _authController =
      StreamController<bool>.broadcast();
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<MessageSentResponse> _messageSentController =
      StreamController<MessageSentResponse>.broadcast();
  final StreamController<MessageErrorResponse> _messageErrorController =
      StreamController<MessageErrorResponse>.broadcast();
  final StreamController<List<Message>> _messagesLoadedController =
      StreamController<List<Message>>.broadcast();
  final StreamController<Map<String, dynamic>> _conversationsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _typingController =
      StreamController<String>.broadcast();
  final StreamController<String> _stopTypingController =
      StreamController<String>.broadcast();

  // Getters pour les streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get authStream => _authController.stream;
  Stream<Message> get messageStream => _messageController.stream;
  Stream<MessageSentResponse> get messageSentStream =>
      _messageSentController.stream;
  Stream<MessageErrorResponse> get messageErrorStream =>
      _messageErrorController.stream;
  Stream<List<Message>> get messagesLoadedStream =>
      _messagesLoadedController.stream;
  Stream<Map<String, dynamic>> get conversationsStream =>
      _conversationsController.stream;
  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;
  Stream<String> get typingStream => _typingController.stream;
  Stream<String> get stopTypingStream => _stopTypingController.stream;

  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;

  SocketService() {
    _loadCredentials();
    _initializeSocket();
  }

  Future<void> requestConversations({int page = 1, int limit = 20}) async {
    if (!_isAuthenticated) return;

    _socket.emit('getConversations', {
      'page': page,
      'limit': limit,
    });

    print('💬 Demande conversations envoyée');
  }

  /// Initialiser la connexion Socket.IO
  Future<void> _initializeSocket() async {
    try {
      _socket = io.io(
        _socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setExtraHeaders({
              'Accept': 'application/json',
            })
            .setTimeout(_connectionTimeout.inMilliseconds)
            .build(),
      );

      _setupEventListeners();

      // Connecter automatiquement
      _socket.connect();
    } catch (e) {
      print('❌ Erreur initialisation Socket.IO: $e');
    }
  }

  /// Charger les credentials depuis SharedPreferences
  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _userId = prefs.getString('user_id');
    _matricule = prefs.getString('matricule');
  }

  /// Configurer tous les listeners d'événements
  void _setupEventListeners() {
    // Événements de connexion
    _socket.onConnect((_) {
      print('✅ Socket.IO connecté');
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);

      // Authentifier automatiquement si on a des credentials
      if (_accessToken != null && _userId != null) {
        _authenticateWithToken();
      }
    });

    _socket.onDisconnect((_) {
      print('❌ Socket.IO déconnecté');
      _isConnected = false;
      _isAuthenticated = false;
      _connectionController.add(false);
      _authController.add(false);
      _scheduleReconnect();
    });

    _socket.onConnectError((data) {
      print('❌ Erreur connexion Socket.IO: $data');
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnect();
    });

    // Événements d'authentification
    _socket.on('authenticated', (data) {
      print('✅ Authentification Socket.IO réussie');
      _isAuthenticated = true;
      _authController.add(true);

      final response = data as Map<String, dynamic>;
      print(
          '📦 Conversations auto-jointe: ${response['autoJoinedConversations']}');

      // Charger les conversations automatiquement
      // _getConversations();
    });

    _socket.on('auth_error', (data) {
      print('❌ Erreur authentification Socket.IO: $data');
      _isAuthenticated = false;
      _authController.add(false);
    });

    // Événements messages
    _socket.on('newMessage', (data) {
      print('📩 Nouveau message reçu');
      try {
        final messageData = data as Map<String, dynamic>;
        final message = Message.fromJson(messageData);
        _messageController.add(message);
      } catch (e) {
        print('❌ Erreur parsing nouveau message: $e');
      }
    });

    _socket.on('message_sent', (data) {
      print('📤 Message envoyé confirmé');
      try {
        final response = MessageSentResponse.fromJson(data);
        _messageSentController.add(response);
      } catch (e) {
        print('❌ Erreur parsing message_sent: $e');
      }
    });

    _socket.on('message_error', (data) {
      print('❌ Erreur message: $data');
      try {
        final error = MessageErrorResponse.fromJson(data);
        _messageErrorController.add(error);
      } catch (e) {
        print('❌ Erreur parsing message_error: $e');
      }
    });

    _socket.on('messagesLoaded', (data) {
      print('📦 Messages chargés');
      try {
        final response = MessagesLoadedResponse.fromJson(data);
        _messagesLoadedController.add(response.messages);
      } catch (e) {
        print('❌ Erreur parsing messagesLoaded: $e');
      }
    });

    // Événements conversations
    _socket.on('conversationsLoaded', (data) async {
      print('📩 Données brutes reçues dans SocketService !!');
      try {
        // Extraire et sauvegarder les conversations dans Hive
        final List<Chat> conversations = _extractConversationsFromData(data);
        await _hiveService.saveChats(conversations);
        print(
            '💾 Conversations sauvegardées dans Hive : ${conversations.length}');
      } catch (e) {
        print('❌ Erreur lors de la sauvegarde des conversations : $e');
      }
    });

    _socket.on('conversationLoaded', (data) {
      print('💬 Conversation chargée');
      try {
        _conversationsController.add({'type': 'single', 'data': data});
        print('💬 Conversation ajoutée au flux');
      } catch (e) {
        print('❌ Erreur lors de l\'ajout de la conversation au flux : $e');
      }
    });

    // Événements présence
    _socket.on('presence:update', (data) {
      _presenceController.add({'type': 'update', 'data': data});
    });

    _socket.on('conversation_online_users', (data) {
      _presenceController.add({'type': 'online_users', 'data': data});
    });

    // Événements frappe
    _socket.on('userTyping', (data) {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null) {
        _typingController.add(conversationId);
      }
    });

    _socket.on('userStoppedTyping', (data) {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null) {
        _stopTypingController.add(conversationId);
      }
    });

    // Événements statuts
    _socket.on('messageStatusChanged', (data) {
      print('🔄 Statut message changé: $data');
    });
  }

  /// Authentifier avec token JWT (double auth)
  Future<void> authenticateWithUser(User user, String accessToken) async {
    if (!_isConnected) {
      print('⚠️ Socket non connecté, tentative de connexion...');
      await _waitForConnection();
    }

    // Sauvegarder les credentials
    _userId = user.id;
    _matricule = user.matricule;
    _accessToken = accessToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('matricule', user.matricule);
    await prefs.setString('access_token', accessToken);

    // Émettre événement authenticate
    _socket.emit('authenticate', {
      'userId': user.id,
      'matricule': user.matricule,
      'token': accessToken,
      'nom': user.nom,
      'prenom': user.prenom,
      'ministere': user.ministere,
      'departement': user.ministere, // fallback
    });

    print('🔐 Authentification Socket.IO envoyée pour ${user.fullName}');
  }

  /// Authentifier avec token existant
  Future<void> _authenticateWithToken() async {
    if (!_isConnected || _accessToken == null || _userId == null) {
      return;
    }

    _socket.emit('authenticate', {
      'userId': _userId,
      'matricule': _matricule,
      'token': _accessToken,
    });

    print('🔐 Authentification auto avec token existant');
  }

  /// Attendre la connexion
  Future<void> _waitForConnection({int maxRetries = 10}) async {
    for (int i = 0; i < maxRetries; i++) {
      if (_isConnected) return;
      await Future.delayed(Duration(milliseconds: 500));
    }
    throw TimeoutException('Connexion Socket.IO timeout');
  }

  /// Programme la reconnexion
  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('🛑 Nombre maximum de tentatives de reconnexion atteint');
      return;
    }

    _reconnectAttempts++;
    print(
        '🔄 Tentative de reconnexion #$_reconnectAttempts dans ${_reconnectInterval.inSeconds}s');

    _reconnectTimer = Timer(_reconnectInterval, () {
      if (!_isConnected) {
        print('🔄 Reconnexion...');
        _socket.connect();
      }
    });
  }

  // MARK: - Émissions vers le serveur

  /// Envoyer un message
  Future<void> sendMessage(Message message) async {
    if (!_isAuthenticated) {
      throw Exception('Non authentifié');
    }

    _socket.emit('sendMessage', {
      'content': message.content,
      'conversationId': message.conversationId,
      'type': Message.messageTypeToString(message.type),
      'receiverId': '', // Pour nouvelles conversations
      ...message.toJson(),
    });

    print(
        '📤 Message envoyé: ${message.content.substring(0, min(30, message.content.length))}...');
  }

  /// Récupérer les messages d'une conversation
  Future<void> getMessages(String conversationId,
      {int page = 1, int limit = 50}) async {
    if (!_isAuthenticated) return;

    _socket.emit('getMessages', {
      'conversationId': conversationId,
      'page': page,
      'limit': limit,
    });

    print('📥 Chargement messages conversation: $conversationId');
  }

  /// Marquer message comme livré
  Future<void> markMessageDelivered(
      String messageId, String conversationId) async {
    if (!_isAuthenticated) return;

    _socket.emit('markMessageDelivered', {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  /// Marquer message comme lu
  Future<void> markMessageRead(String messageId, String conversationId) async {
    if (!_isAuthenticated) return;

    _socket.emit('markMessageRead', {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  /// Signaler que l'utilisateur tape
  Future<void> startTyping(String conversationId) async {
    if (!_isAuthenticated) return;

    _socket.emit('typing', {
      'conversationId': conversationId,
    });
  }

  /// Signaler que l'utilisateur arrête de taper
  Future<void> stopTyping(String conversationId) async {
    if (!_isAuthenticated) return;

    _socket.emit('stopTyping', {
      'conversationId': conversationId,
    });
  }

  /// Créer un groupe
  Future<void> createGroup(String name, List<String> memberIds,
      {String? groupId}) async {
    if (!_isAuthenticated) return;

    _socket.emit('createGroup', {
      'name': name,
      'members': memberIds,
      if (groupId != null) 'groupId': groupId,
    });

    print('👥 Création groupe: $name');
  }

  // MARK: - Gestion de la connexion

  /// Déconnecter manuellement
  Future<void> disconnect() async {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      _reconnectTimer!.cancel();
    }

    _socket.disconnect();
    _isConnected = false;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');

    print('👋 Socket déconnecté manuellement');
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    await disconnect();

    await _connectionController.close();
    await _authController.close();
    await _messageController.close();
    await _messageSentController.close();
    await _messageErrorController.close();
    await _messagesLoadedController.close();
    await _conversationsController.close();
    await _presenceController.close();
    await _typingController.close();
    await _stopTypingController.close();

    print('🧹 SocketService nettoyé');
  }

  // Helper
  int min(int a, int b) => a < b ? a : b;

  /// Extraire les conversations des données reçues
  List<Chat> _extractConversationsFromData(Map<String, dynamic> data) {
    final List<Chat> conversations = [];

    print('🔍 Structure des données reçues: ${data.keys.toList()}');
    print(
        '🔍 Type de data["conversations"]: ${data['conversations']?.runtimeType}');
    print(
        '🔍 Type de data["categorized"]: ${data['categorized']?.runtimeType}');

    // Format 1: array direct
    if (data['conversations'] is List) {
      final conversationsData = data['conversations'] as List<dynamic>;

      // print("conversationsData: $conversationsData");

      for (final convData in conversationsData) {
        try {
          final chat = Chat.fromJson(convData as Map<String, dynamic>);
          conversations.add(chat);
        } catch (e) {
          print('⚠️ Erreur conversion conversation: $e');
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
              final chat = Chat.fromJson(convData as Map<String, dynamic>);
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
        final chat = Chat.fromJson(data['data'] as Map<String, dynamic>);
        conversations.add(chat);
      } catch (e) {
        print('⚠️ Erreur conversion conversation unique: $e');
      }
    }
    // Format 4: Map direct (clé = ID conversation, valeur = données conversation)
    else if (data.isNotEmpty && data.values.first is Map<String, dynamic>) {
      print('🔄 Tentative de traitement comme Map de conversations');
      for (final convData in data.values) {
        if (convData is Map<String, dynamic>) {
          try {
            final chat = Chat.fromJson(convData);
            conversations.add(chat);
            print('✅ Conversation extraite: ${chat.name}');
          } catch (e) {
            print('⚠️ Erreur conversion conversation Map: $e');
          }
        }
      }
    }

    // Trier par dernier message
    conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    return conversations;
  }

  /// Convertir le type de message en chaîne de caractères
  static String messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'IMAGE';
      case MessageType.file:
        return 'FILE';
      case MessageType.audio:
        return 'AUDIO';
      case MessageType.video:
        return 'VIDEO';
      case MessageType.location:
        return 'LOCATION';
      case MessageType.contact:
        return 'CONTACT';
      case MessageType.system:
        return 'SYSTEM';
      case MessageType.broadcast:
        return 'BROADCAST';
      default:
        return 'TEXT';
    }
  }
}
