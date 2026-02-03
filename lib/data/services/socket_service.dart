import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';

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

  // StreamControllers pour chaque événement majeur
  final _connectionChangedController = StreamController<bool>.broadcast();
  Stream<bool> get connectionChangedStream =>
      _connectionChangedController.stream;

  final _authChangedController = StreamController<bool>.broadcast();
  Stream<bool> get authChangedStream => _authChangedController.stream;

  final _newMessageController = StreamController<Message>.broadcast();
  Stream<Message> get newMessageStream => _newMessageController.stream;

  final _messageSentController =
      StreamController<MessageSentResponse>.broadcast();
  Stream<MessageSentResponse> get messageSentStream =>
      _messageSentController.stream;

  final _messageErrorController =
      StreamController<MessageErrorResponse>.broadcast();
  Stream<MessageErrorResponse> get messageErrorStream =>
      _messageErrorController.stream;

  final _messagesLoadedController = StreamController<List<Message>>.broadcast();
  Stream<List<Message>> get messagesLoadedStream =>
      _messagesLoadedController.stream;

  final _conversationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get conversationUpdateStream =>
      _conversationUpdateController.stream;

  final _presenceUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get presenceUpdateStream =>
      _presenceUpdateController.stream;

  final _userTypingController = StreamController<String>.broadcast();
  Stream<String> get userTypingStream => _userTypingController.stream;

  final _userStopTypingController = StreamController<String>.broadcast();
  Stream<String> get userStopTypingStream => _userStopTypingController.stream;

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
      _connectionChangedController.add(true);

      // Authentifier automatiquement si on a des credentials
      if (_accessToken != null && _userId != null) {
        _authenticateWithToken();
      }
    });

    _socket.onDisconnect((_) {
      print('❌ Socket.IO déconnecté');
      _isConnected = false;
      _isAuthenticated = false;
      _connectionChangedController.add(false);
      _authChangedController.add(false);
      _scheduleReconnect();
    });

    _socket.onConnectError((data) {
      print('❌ Erreur connexion Socket.IO: $data');
      _isConnected = false;
      _connectionChangedController.add(false);
      _scheduleReconnect();
    });

    // Événements d'authentification
    _socket.on('authenticated', (data) {
      print('✅ Authentification Socket.IO réussie');
      _isAuthenticated = true;
      _authChangedController.add(true);

      final response = data as Map<String, dynamic>;
      print(
          '📦 Conversations auto-jointe: ${response['autoJoinedConversations']}');

      // Charger les conversations automatiquement après authentification
      // requestConversations();
    });

    _socket.on('auth_error', (data) {
      print('❌ Erreur authentification Socket.IO: $data');
      _isAuthenticated = false;
      _authChangedController.add(false);
    });

    // Événements messages
    _socket.on('newMessage', (data) {
      print('📩 Nouveau message reçu');
      try {
        final messageData = data as Map<String, dynamic>;
        final message = Message.fromJson(messageData);
        _newMessageController.add(message);
        
        // Marquer automatiquement comme livré
        if (message.id.isNotEmpty && !message.isMe) {
          print('📬 Marquage message comme delivered: ${message.id}');
          markMessageDelivered(message.id, message.conversationId);
        }
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
      print('📦 [SocketService] Événement messagesLoaded reçu');
      try {
        final response = MessagesLoadedResponse.fromJson(data);
        print(
            '📦 [SocketService] Messages parsés: ${response.messages.length} messages');
        _messagesLoadedController.add(response.messages);
      } catch (e) {
        print('❌ [SocketService] Erreur parsing messagesLoaded: $e');
      }
    });

    // Événements conversations
    _socket.on('conversationsLoaded', (data) async {
      print('📩 Données brutes reçues dans SocketService !!');
      try {
        // Émettre l'événement sans sauvegarder directement
        _conversationUpdateController.add(data as Map<String, dynamic>);
      } catch (e) {
        print('❌ Erreur conversationsLoaded: $e');
      }
    });

    _socket.on('conversationLoaded', (data) {
      print('💬 Conversation chargée');
      try {
        _conversationUpdateController.add({'type': 'single', 'data': data});
      } catch (e) {
        print('❌ Erreur lors de l\'ajout de la conversation : $e');
      }
    });

    // Événements présence
    _socket.on('presence:update', (data) {
      _presenceUpdateController.add({'type': 'update', 'data': data});
    });

    _socket.on('conversation_online_users', (data) {
      _presenceUpdateController.add({'type': 'online_users', 'data': data});
    });

    // Événements frappe
    _socket.on('userTyping', (data) {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null) {
        _userTypingController.add(conversationId);
      }
    });

    _socket.on('userStoppedTyping', (data) {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null) {
        _userStopTypingController.add(conversationId);
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
    // Temporairement désactivé pour test
    // if (!_isAuthenticated) {
    //   throw Exception('Non authentifié');
    // }

    _socket.emit('sendMessage', {
      'content': message.content,
      'conversationId': message.conversationId, // Plain string
      'type': Message.messageTypeToString(message.type),
      'senderId':
          _matricule ?? message.senderId, // Utiliser matricule si disponible
      'temporaryId': message.temporaryId,
      'fileId': message.fileId,
      'fileName': message.fileName,
      'fileSize': message.fileSize,
      'mimeType': message.mimeType,
      'duration': message.duration,
      // Add other fields if needed, but as plain values
    });

    print(
        '📤 Message envoyé: ${message.content.substring(0, min(30, message.content.length))}...');
  }

  /// Récupérer les messages d'une conversation
  Future<void> getMessages(String conversationId,
      {int page = 1, int limit = 50}) async {
    // Temporairement désactivé pour test
    // if (!_isAuthenticated) {
    //   print(
    //       '❌ [SocketService] getMessages: Socket non authentifié, impossible d\'émettre');
    //   return;
    // }
    if (!_isConnected) {
      print(
          '❌ [SocketService] getMessages: Socket non connecté, impossible d\'émettre');
      return;
    }

    _socket.emit('getMessages', {
      'conversationId': conversationId,
      'page': page,
      'limit': limit,
    });

    print(
        '📥 [SocketService] Émission getMessages pour conversation: $conversationId, page: $page, limit: $limit');
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

    // Close tous les controllers
    _connectionChangedController.close();
    _authChangedController.close();
    _newMessageController.close();
    _messageSentController.close();
    _messageErrorController.close();
    _messagesLoadedController.close();
    _conversationUpdateController.close();
    _presenceUpdateController.close();
    _userTypingController.close();
    _userStopTypingController.close();

    print('🧹 SocketService nettoyé');
  }

  // Helper
  int min(int a, int b) => a < b ? a : b;

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
