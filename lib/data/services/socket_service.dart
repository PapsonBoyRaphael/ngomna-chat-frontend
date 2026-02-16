import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/services/chat_stream_manager.dart';

class SocketService {
  static const String _socketUrl = 'http://localhost:8003'; // Gateway
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _reconnectInterval = Duration(seconds: 3);
  static const int _maxReconnectAttempts = 5;

  // 🔥 SINGLETON PATTERN
  static SocketService? _instance;

  factory SocketService() {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal() {
    _loadCredentials();
    _initializeSocket();
  }

  late io.Socket _socket;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  String? _userId;
  String? _matricule;
  String? _accessToken;

  // ChatStreamManager unifié (remplace les 25+ StreamControllers)
  final _streamManager = ChatStreamManager();
  ChatStreamManager get streamManager => _streamManager;

  // Stream d'authentification
  final _authChangedController = StreamController<bool>.broadcast();
  Stream<bool> get authChangedStream => _authChangedController.stream;

  // Legacy streams pour compatibilité arrière (seront dépréciés)
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

  final _messageStatusChangedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStatusChangedStream =>
      _messageStatusChangedController.stream;

  final _messageReadController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageReadStream =>
      _messageReadController.stream;

  final _participantRemovedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get participantRemovedStream =>
      _participantRemovedController.stream;

  final _conversationDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get conversationDeletedStream =>
      _conversationDeletedController.stream;

  final _fileEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get fileEventStream =>
      _fileEventController.stream;

  final _messageReactionController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageReactionStream =>
      _messageReactionController.stream;

  final _messageReplyController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageReplyStream =>
      _messageReplyController.stream;

  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> requestConversations({int page = 1, int limit = 20}) async {
    if (!_isAuthenticated) return;

    _socket.emit('getConversations', {
      'page': page,
      'limit': limit,
    });

    print('💬 Demande conversations envoyée');
  }

  /// Demander une seule conversation au serveur
  Future<void> requestConversation(String conversationId) async {
    if (!_isAuthenticated) return;

    _socket.emit('getConversation', {
      'conversationId': conversationId,
    });

    print('💬 Demande conversation $conversationId envoyée');
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
      final timestamp = DateTime.now().toIso8601String();
      print('[$timestamp] ✅ Socket.IO connecté');
      print('[$timestamp] 🔄 _isConnected: false → true');
      _isConnected = true;
      _reconnectAttempts = 0;
      _streamManager.emitConnection(ConnectionState.connected);

      // Démarrer le heartbeat
      _startHeartbeat();

      // Authentifier automatiquement si on a des credentials
      print(
          '[$timestamp] 🔍 [onConnect] Credentials: token=${_accessToken != null ? "présent" : "manquant"}, userId=$_userId, matricule=$_matricule');
      if (_accessToken != null && _userId != null) {
        print(
            '[$timestamp] 🔐 [onConnect] Déclenchement authentification automatique');
        _authenticateWithToken();
      } else {
        print(
            '[$timestamp] ⚠️ [onConnect] PAS d\'authentification auto: _accessToken=${_accessToken != null}, _userId=${_userId != null}');
      }
    });

    _socket.onDisconnect((_) {
      print('❌ Socket.IO déconnecté');
      _isConnected = false;
      _isAuthenticated = false;
      _stopHeartbeat();
      _streamManager.emitConnection(ConnectionState.disconnected);
      _scheduleReconnect();
    });

    _socket.onConnectError((data) {
      print('❌ Erreur connexion Socket.IO: $data');
      _isConnected = false;
      _streamManager.emitConnection(ConnectionState.error);
      _scheduleReconnect();
    });

    // Événements d'authentification
    _socket.on('authenticated', (data) {
      print('✅ Authentification Socket.IO réussie');
      _isAuthenticated = true;
      _authChangedController.add(true);
      _streamManager.emitConnection(ConnectionState.authenticated);

      final response = data as Map<String, dynamic>;
      print(
          '📬 Conversations auto-jointe: ${response['autoJoinedConversations']}');
    });

    _socket.on('auth_error', (data) {
      print('❌ Erreur authentification Socket.IO: $data');
      _isAuthenticated = false;
      _authChangedController.add(false);
      _streamManager.emitConnection(ConnectionState.error);
    });

    // Événements messages privés
    _socket.on('newMessage', (data) {
      print('📩 Nouveau message reçu');
      print('📋 Raw data keys: ${(data as Map).keys.toList()}');
      print('📋 Raw data: $data');
      try {
        final messageData = data as Map<String, dynamic>;
        final message = Message.fromJson(messageData);

        // Déterminer le contexte selon le type de message
        String context = 'private';
        if (messageData.containsKey('type')) {
          final type = messageData['type'] as String?;
          if (type == 'GROUP') {
            context = 'group';
          } else if (type == 'BROADCAST') {
            context = 'broadcast';
          }
        }

        // Émission via ChatStreamManager
        final event = MessageEvent.fromJson(messageData, context);
        _streamManager.emitMessage(event);

        // Marquer automatiquement comme livré
        if (message.id.isNotEmpty && !message.isMe) {
          print(
              '📦 markMessageDelivered ($context) → messageId=${message.id}, conversationId=${message.conversationId}');
          markMessageDelivered(message.id, message.conversationId);
        } else {
          print(
              '⏭️ markMessageDelivered ignoré ($context) → id=${message.id}, isMe=${message.isMe}');
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
      print('🟢 [SocketService] Événement presence:update reçu');
      print('   - Data: $data');
      _presenceUpdateController.add({'type': 'update', 'data': data});
    });

    // Heartbeat acknowledgement - confirme que la connexion est active
    _socket.on('heartbeat_ack', (_) {
      print('💓 Heartbeat_ack reçu – connexion active');
    });

    _socket.on('conversation_online_users', (data) {
      print('🟢 [SocketService] Événement conversation_online_users reçu');
      print('   - Data: $data');
      _presenceUpdateController.add({'type': 'online_users', 'data': data});
    });

    // 🆕 Événement user_online - quand un utilisateur se connecte
    _socket.on('user_online', (data) {
      print('🟢 [SocketService] Événement user_online reçu');
      print('   - Data: $data');
      _presenceUpdateController.add({'type': 'user_online', 'data': data});
    });

    // 🆕 Événement user_offline - quand un utilisateur se déconnecte
    _socket.on('user_offline', (data) {
      print('🔴 [SocketService] Événement user_offline reçu');
      print('   - Data: $data');
      _presenceUpdateController.add({'type': 'user_offline', 'data': data});
    });

    // Événements frappe (typing)
    _socket.on('userTyping', (data) {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null) {
        _userTypingController.add(conversationId);
        try {
          final event = TypingEvent.fromJson({...data, 'isTyping': true});
          _streamManager.emitTyping(event);
        } catch (e) {
          print('❌ Erreur parsing userTyping: $e');
        }
      }
    });

    _socket.on('userStoppedTyping', (data) {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null) {
        _userStopTypingController.add(conversationId);
        try {
          final event = TypingEvent.fromJson({...data, 'isTyping': false});
          _streamManager.emitTyping(event);
        } catch (e) {
          print('❌ Erreur parsing userStoppedTyping: $e');
        }
      }
    });

    // Événements statut message
    _socket.on('messageStatusChanged', (data) {
      print('📊 Statut message changé');
      try {
        // ❌ SUPPRIMÉ: _messageStatusChangedController.add(data);
        // SEULEMENT ChatStreamManager
        final event = MessageStatusEvent.fromJson(data as Map<String, dynamic>);
        _streamManager.emitMessageStatus(event);
      } catch (e) {
        print('❌ Erreur parsing messageStatusChanged: $e');
      }
    });

    _socket.on('messageRead', (data) {
      print('👁️ Message marqué comme lu');
      try {
        // ❌ SUPPRIMÉ: _messageReadController.add(data);
        // SEULEMENT ChatStreamManager
        final event = MessageStatusEvent.fromJson(data as Map<String, dynamic>);
        _streamManager.emitMessageStatus(event);
      } catch (e) {
        print('❌ Erreur parsing messageRead: $e');
      }
    });

    // Événements groupe
    _socket.on('message:group', (data) {
      print('👥 Message groupe reçu: $data');
      try {
        final messageData = data as Map<String, dynamic>;
        final event = MessageEvent.fromJson(messageData, 'group');
        _streamManager.emitMessage(event);

        // Marquer automatiquement comme livré
        final message = Message.fromJson(messageData);
        if (message.id.isNotEmpty && !message.isMe) {
          print(
              '📦 markMessageDelivered (group) → messageId=${message.id}, conversationId=${message.conversationId}');
          markMessageDelivered(message.id, message.conversationId);
        } else {
          print(
              '⏭️ markMessageDelivered ignoré (group) → id=${message.id}, isMe=${message.isMe}');
        }
      } catch (e) {
        print('❌ Erreur parsing message:group: $e');
      }
    });

    // Événements canal
    _socket.on('message:channel', (data) {
      print('📢 Message canal reçu: $data');
      try {
        final messageData = data as Map<String, dynamic>;
        final event = MessageEvent.fromJson(messageData, 'channel');
        _streamManager.emitMessage(event);

        // Marquer automatiquement comme livré
        final message = Message.fromJson(messageData);
        if (message.id.isNotEmpty && !message.isMe) {
          print(
              '📦 markMessageDelivered (channel) → messageId=${message.id}, conversationId=${message.conversationId}');
          markMessageDelivered(message.id, message.conversationId);
        } else {
          print(
              '⏭️ markMessageDelivered ignoré (channel) → id=${message.id}, isMe=${message.isMe}');
        }
      } catch (e) {
        print('❌ Erreur parsing message:channel: $e');
      }
    });

    // Événements typing structurés
    _socket.on('typing:event', (data) {
      print('⌨️ Événement typing: $data');
      try {
        final event = TypingEvent.fromJson(data as Map<String, dynamic>);
        _streamManager.emitTyping(event);
      } catch (e) {
        print('❌ Erreur parsing typing:event: $e');
      }
    });

    // Événements statut message
    _socket.on('message:status', (data) {
      print('📊 Statut message: $data');
      try {
        final event = MessageStatusEvent.fromJson(data as Map<String, dynamic>);
        _streamManager.emitMessageStatus(event);
      } catch (e) {
        print('❌ Erreur parsing message:status: $e');
      }
    });

    // Événements conversation génériques et spécifiques
    _socket.on('conversation:event', (data) {
      print('💬 Événement conversation: $data');
      try {
        final event = ConversationEvent.fromJson(data as Map<String, dynamic>);
        _streamManager.emitConversation(event);
      } catch (e) {
        print('❌ Erreur parsing conversation:event: $e');
      }
    });

    _socket.on('conversation:created', (data) {
      print('✨ Conversation créée: $data');
      try {
        final event = ConversationEvent.fromJson(
            {...data as Map<String, dynamic>, 'event': 'created'});
        _streamManager.emitConversation(event);
      } catch (e) {
        print('❌ Erreur parsing conversation:created: $e');
      }
    });

    _socket.on('conversation:updated', (data) {
      print('🔄 Conversation mise à jour: $data');
      try {
        final event = ConversationEvent.fromJson(
            {...data as Map<String, dynamic>, 'event': 'updated'});
        _streamManager.emitConversation(event);
      } catch (e) {
        print('❌ Erreur parsing conversation:updated: $e');
      }
    });

    _socket.on('conversation:participant:added', (data) {
      print('➕ Participant ajouté: $data');
      try {
        final event = ConversationEvent.fromJson(
            {...data as Map<String, dynamic>, 'event': 'participant_added'});
        _streamManager.emitConversation(event);
      } catch (e) {
        print('❌ Erreur parsing conversation:participant:added: $e');
      }
    });

    _socket.on('conversation:participant:removed', (data) {
      print('➖ Participant supprimé: $data');
      try {
        final event = ConversationEvent.fromJson(
            {...data as Map<String, dynamic>, 'event': 'participant_removed'});
        _streamManager.emitConversation(event);
      } catch (e) {
        print('❌ Erreur parsing conversation:participant:removed: $e');
      }
    });

    _socket.on('conversation:deleted', (data) {
      print('🗑️ Conversation supprimée: $data');
      try {
        final event = ConversationEvent.fromJson(
            {...data as Map<String, dynamic>, 'event': 'deleted'});
        _streamManager.emitConversation(event);
      } catch (e) {
        print('❌ Erreur parsing conversation:deleted: $e');
      }
    });

    // Événements fichier
    _socket.on('file:event', (data) {
      print('📁 Événement fichier: $data');
      try {
        final event = FileEvent.fromJson(data as Map<String, dynamic>);
        _streamManager.emitFile(event);
      } catch (e) {
        print('❌ Erreur parsing file:event: $e');
      }
    });

    // Événements interactions message (réaction, réponse)
    _socket.on('message:reaction', (data) {
      print('😊 Réaction message: $data');
      try {
        final event = MessageInteractionEvent.fromJson(
            {...data as Map<String, dynamic>, 'type': 'reaction'});
        _streamManager.emitMessageInteraction(event);
      } catch (e) {
        print('❌ Erreur parsing message:reaction: $e');
      }
    });

    _socket.on('message:reply', (data) {
      print('↩️ Réponse message: $data');
      try {
        final event = MessageInteractionEvent.fromJson(
            {...data as Map<String, dynamic>, 'type': 'reply'});
        _streamManager.emitMessageInteraction(event);
      } catch (e) {
        print('❌ Erreur parsing message:reply: $e');
      }
    });

    // Événements présence (garder pour compatibilité)
    _socket.on('presence:update', (data) {
      print('🟢 [SocketService/Legacy] Événement presence:update reçu');
      print('   - Data: $data');
      _presenceUpdateController.add({'type': 'update', 'data': data});
    });

    _socket.on('conversation_online_users', (data) {
      print(
          '🟢 [SocketService/Legacy] Événement conversation_online_users reçu');
      print('   - Data: $data');
      _presenceUpdateController.add({'type': 'online_users', 'data': data});
    });

    // Événements conversations (legacy, garder pour compatibilité)
    _socket.on('conversationsLoaded', (data) async {
      print('📩 Données brutes reçues dans SocketService !!');
      try {
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

    // Événements messages chargés (legacy)
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

    // Événements envoi (legacy)
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
    print(
        '🔐 [_authenticateWithToken] Entrée: _isConnected=$_isConnected, token=${_accessToken != null}, userId=$_userId');

    if (!_isConnected || _accessToken == null || _userId == null) {
      print(
          '❌ [_authenticateWithToken] Conditions échouées, pas d\'envoi authenticate');
      return;
    }

    print('📤 [_authenticateWithToken] Envoi \'authenticate\' au serveur...');
    _socket.emit('authenticate', {
      'userId': _userId,
      'matricule': _matricule,
      'token': _accessToken,
    });

    print(
        '✅ [_authenticateWithToken] Event \'authenticate\' envoyé (userId=$_userId, matricule=$_matricule)');
  }

  /// Attendre la connexion (et optionnellement l'authentification)
  Future<void> _waitForConnection(
      {int maxRetries = 10, bool requireAuth = false}) async {
    print(
        '🔄 [_waitForConnection] Démarrage (requireAuth=$requireAuth, maxRetries=$maxRetries)');

    for (int i = 0; i < maxRetries; i++) {
      // Vérifier l'état réel du socket ET nos flags
      final socketConnected = _socket.connected;
      final flagsOk =
          requireAuth ? (_isConnected && _isAuthenticated) : _isConnected;

      if (i % 5 == 0) {
        // Log tous les 2.5 secondes
        print(
            '🔄 [_waitForConnection] Tentative ${i + 1}/$maxRetries: socket.connected=$socketConnected, _isConnected=$_isConnected, _isAuthenticated=$_isAuthenticated');
      }

      if (socketConnected && flagsOk) {
        print(
            '✅ [_waitForConnection] Socket prêt après ${i + 1} tentatives (connected=$socketConnected, authenticated=$_isAuthenticated)');
        return;
      }

      // Synchroniser les flags si désynchronisés
      if (socketConnected && !_isConnected) {
        print('⚠️ [_waitForConnection] Flags désynchronisés, correction...');
        _isConnected = true;
      }

      await Future.delayed(const Duration(milliseconds: 500));
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

  /// Démarre le heartbeat pour maintenir la connexion active
  void _startHeartbeat() {
    _stopHeartbeat(); // Arrêter l'ancien timer s'il existe

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_isConnected && _isAuthenticated) {
        _socket.emit('heartbeat');
        print('💓 Heartbeat envoyé au serveur (matricule: $_matricule)');
      } else {
        print(
            '💓 Heartbeat ignoré - connecté: $_isConnected, authentifié: $_isAuthenticated');
      }
    });

    print(
        '💓 Heartbeat démarré (intervalle: ${_heartbeatInterval.inSeconds}s)');
  }

  /// Arrête le heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    print('💔 Heartbeat arrêté');
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
    print(
        '🔍 [SocketService] getMessages appelé: conversationId=$conversationId');
    print(
        '   - Flags: isConnected=$_isConnected, isAuthenticated=$_isAuthenticated');
    print('   - Socket réel: _socket.connected=${_socket.connected}');

    // Temporairement désactivé pour test
    // if (!_isAuthenticated) {
    //   print(
    //       '❌ [SocketService] getMessages: Socket non authentifié, impossible d\'émettre');
    //   return;
    // }

    // Si pas connecté OU pas authentifié, attendre/forcer la reconnexion
    if (!_isConnected || !_isAuthenticated) {
      print('⏳ [SocketService] Socket non prêt, tentative de reconnexion...');

      // Forcer la reconnexion immédiatement si nécessaire
      if (!_socket.connected) {
        print('🔄 [SocketService] Déclenchement manuel de socket.connect()');
        _socket.connect();
      }

      try {
        await _waitForConnection(
            maxRetries: 40, requireAuth: true); // 40 * 500ms = 20 secondes
        print(
            '✅ [SocketService] Socket prêt (connecté et authentifié), envoi de getMessages');
      } catch (e) {
        print('❌ [SocketService] Timeout reconnexion: $e');
        print(
            '   - État flags: connected=$_isConnected, authenticated=$_isAuthenticated');
        print('   - Socket.connected: ${_socket.connected}');
        print('   - Matricule: $_matricule');
        return;
      }
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
    if (!_isAuthenticated) {
      print(
          '⚠️ markMessageDelivered annulé (non authentifié) → messageId=$messageId, conversationId=$conversationId');
      return;
    }

    print(
        '✅ markMessageDelivered émis → messageId=$messageId, conversationId=$conversationId');
    _socket.emit('markMessageDelivered', {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  /// Marquer message comme lu
  Future<void> markMessageRead(String messageId, String conversationId) async {
    if (!_isAuthenticated) {
      print(
          '⚠️ markMessageRead annulé (non authentifié) → messageId=$messageId, conversationId=$conversationId');
      return;
    }

    print(
        '✅ markMessageRead émis → messageId=$messageId, conversationId=$conversationId');
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
    _stopHeartbeat();

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

    // Fermer le ChatStreamManager
    _streamManager.dispose();

    // Fermer le stream d'authentification
    _authChangedController.close();

    // Fermer les legacy controllers
    _newMessageController.close();
    _messageSentController.close();
    _messageErrorController.close();
    _messagesLoadedController.close();
    _conversationUpdateController.close();
    _presenceUpdateController.close();
    _userTypingController.close();
    _userStopTypingController.close();
    _messageStatusChangedController.close();
    _messageReadController.close();

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
