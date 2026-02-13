import 'dart:async';
import 'package:ngomna_chat/data/models/group_message_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'package:ngomna_chat/data/services/chat_stream_manager.dart';

class GroupChatRepository {
  // Singleton pattern
  static GroupChatRepository? _instance;

  final SocketService _socketService;
  final HiveService _hiveService;
  final StorageService _storageService = StorageService();

  GroupChatRepository._internal({
    required SocketService socketService,
    required HiveService hiveService,
  })  : _socketService = socketService,
        _hiveService = hiveService {
    _setupSocketListeners();
  }

  factory GroupChatRepository({
    SocketService? socketService,
    HiveService? hiveService,
  }) {
    if (_instance != null) return _instance!;

    // Si pas de services fournis, utiliser des instances par défaut
    final socket = socketService ?? SocketService();
    final hive = hiveService ?? HiveService();

    _instance = GroupChatRepository._internal(
      socketService: socket,
      hiveService: hive,
    );
    return _instance!;
  }

  // Streams for real-time updates
  final StreamController<GroupMessage> _messageSentController =
      StreamController<GroupMessage>.broadcast();
  final StreamController<GroupMessage> _messageReceivedController =
      StreamController<GroupMessage>.broadcast();
  final StreamController<List<GroupMessage>> _messagesUpdatedController =
      StreamController<List<GroupMessage>>.broadcast();

  // Public streams
  Stream<GroupMessage> get onMessageSent => _messageSentController.stream;
  Stream<GroupMessage> get onMessageReceived =>
      _messageReceivedController.stream;
  Stream<List<GroupMessage>> get onMessagesUpdated =>
      _messagesUpdatedController.stream;

  // Cache for group messages
  final Map<String, List<GroupMessage>> _messageCache = {};

  // Streams for watching messages (real-time updates)
  final Map<String, StreamController<List<GroupMessage>>> _messageStreams = {};

  /// Configurer les listeners Socket.IO
  void _setupSocketListeners() {
    print('🔌 [GroupChatRepository] Configuration des listeners Socket.IO');

    // Écouter les nouveaux messages de groupe via le stream unifié
    _socketService.streamManager.messageStream.listen((event) {
      if (event.context == 'group') {
        _handleGroupMessageEvent(event);
      }
    });

    // Écouter les messages chargés (legacy stream)
    _socketService.messagesLoadedStream.listen((messages) {
      _handleMessagesLoaded(messages);
    });
  }

  /// Gérer un événement message de groupe (depuis MessageEvent)
  void _handleGroupMessageEvent(MessageEvent event) {
    try {
      print('📩 [GroupChatRepository] Nouveau message de groupe reçu');

      final conversationId = event.conversationId;
      if (conversationId.isEmpty) return;

      final currentUser = _storageService.getUser();
      final isMe = event.senderId == currentUser?.matricule;

      final message = GroupMessage(
        id: event.messageId,
        conversationId: conversationId,
        senderId: event.senderId,
        receiverId: conversationId,
        content: event.content,
        createdAt: event.timestamp,
        isMe: isMe,
        sender: User(
          id: event.senderId,
          matricule: event.senderId,
          nom: event.senderName ?? 'Utilisateur',
          prenom: '',
          isOnline: false,
        ),
      );

      // Ajouter au cache
      _messageCache[conversationId] ??= [];
      _messageCache[conversationId]!.add(message);

      // Émettre l'événement
      _messageReceivedController.add(message);
      _messagesUpdatedController.add(_messageCache[conversationId]!);

      print('✅ [GroupChatRepository] Message ajouté: ${message.content}');
    } catch (e) {
      print('❌ [GroupChatRepository] Erreur _handleGroupMessageEvent: $e');
    }
  }

  /// Gérer les messages chargés depuis le serveur
  void _handleMessagesLoaded(List<Message> messages) {
    if (messages.isEmpty) return;

    final conversationId = messages.first.conversationId;
    final currentUser = _storageService.getUser();

    print(
        '📦 [GroupChatRepository] ${messages.length} messages chargés pour $conversationId');

    final groupMessages = messages
        .map((msg) => GroupMessage(
              id: msg.id,
              conversationId: msg.conversationId,
              senderId: msg.senderId,
              receiverId: msg.conversationId,
              content: msg.content,
              createdAt: msg.timestamp,
              isMe: msg.senderId == currentUser?.matricule,
              sender: User(
                id: msg.senderId,
                matricule: msg.senderId,
                nom: msg.senderName ?? 'Utilisateur',
                prenom: '',
                isOnline: false,
              ),
            ))
        .toList();

    // Trier par date
    groupMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Mettre à jour le cache
    _messageCache[conversationId] = groupMessages;

    // Émettre l'événement
    _messagesUpdatedController.add(groupMessages);
  }

  /// Récupérer les messages d'un groupe
  Future<List<GroupMessage>> getGroupMessages(String groupId,
      {int? limit, int? offset}) async {
    print('📥 [GroupChatRepository] Chargement messages pour groupe $groupId');

    // Vérifier le cache d'abord
    if (_messageCache.containsKey(groupId) &&
        _messageCache[groupId]!.isNotEmpty) {
      var messages = _messageCache[groupId]!;
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final startIndex = offset ?? 0;
      final endIndex = limit != null ? startIndex + limit : messages.length;

      print('📦 [GroupChatRepository] ${messages.length} messages en cache');
      return messages.sublist(
        startIndex.clamp(0, messages.length),
        endIndex.clamp(0, messages.length),
      );
    }

    // Charger depuis Hive
    try {
      final cachedMessages =
          await _hiveService.getMessagesForConversation(groupId);
      if (cachedMessages.isNotEmpty) {
        final currentUser = _storageService.getUser();

        final groupMessages = cachedMessages
            .map((msg) => GroupMessage(
                  id: msg.id,
                  conversationId: msg.conversationId,
                  senderId: msg.senderId,
                  receiverId: msg.conversationId,
                  content: msg.content,
                  createdAt: msg.timestamp,
                  isMe: msg.senderId == currentUser?.matricule,
                  sender: User(
                    id: msg.senderId,
                    matricule: msg.senderId,
                    nom: msg.senderName ?? 'Utilisateur',
                    prenom: '',
                    isOnline: false,
                  ),
                ))
            .toList();

        groupMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _messageCache[groupId] = groupMessages;

        print(
            '📦 [GroupChatRepository] ${groupMessages.length} messages depuis Hive');
        return groupMessages;
      }
    } catch (e) {
      print('⚠️ [GroupChatRepository] Erreur lecture Hive: $e');
    }

    // Demander au serveur via Socket.IO
    _socketService.getMessages(groupId);

    print('📡 [GroupChatRepository] Demande messages au serveur pour $groupId');
    return [];
  }

  /// Envoyer un message dans un groupe
  Future<GroupMessage> sendGroupMessage(String groupId, String text) async {
    print('📤 [GroupChatRepository] Envoi message dans groupe $groupId');

    final currentUser = _storageService.getUser();

    final message = GroupMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: groupId,
      senderId: currentUser?.matricule ?? 'unknown',
      receiverId: groupId,
      content: text,
      createdAt: DateTime.now(),
      isMe: true,
      sender: User(
        id: currentUser?.id ?? '',
        matricule: currentUser?.matricule ?? '',
        nom: currentUser?.nom ?? '',
        prenom: currentUser?.prenom ?? '',
        avatarUrl: currentUser?.avatarUrl,
        isOnline: true,
      ),
    );

    // Ajouter au cache immédiatement (optimistic update)
    _messageCache[groupId] ??= [];
    _messageCache[groupId]!.add(message);

    // Émettre l'événement
    _messageSentController.add(message);
    _messagesUpdatedController.add(_messageCache[groupId]!);

    // Envoyer via Socket.IO
    final socketMessage = Message(
      id: message.id,
      conversationId: groupId,
      senderId: message.senderId,
      receiverId: groupId,
      content: text,
      type: MessageType.text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    await _socketService.sendMessage(socketMessage);

    print('✅ [GroupChatRepository] Message envoyé: $text');
    return message;
  }

  /// Recevoir un message de groupe (appelé par le socket service)
  void receiveGroupMessage(GroupMessage message) {
    final groupId = message.conversationId;

    _messageCache[groupId] ??= [];
    _messageCache[groupId]!.add(message);

    _messageReceivedController.add(message);
    _messagesUpdatedController.add(_messageCache[groupId]!);
  }

  /// Vider le cache d'un groupe spécifique
  void clearGroupCache(String groupId) {
    _messageCache.remove(groupId);
  }

  /// Écouter les changements de messages du groupe en temps réel
  Stream<List<GroupMessage>> watchGroupMessages(String groupId) {
    print(
        '👂 [GroupChatRepository] watchGroupMessages: création du stream pour $groupId');

    if (!_messageStreams.containsKey(groupId)) {
      _messageStreams[groupId] =
          StreamController<List<GroupMessage>>.broadcast();

      // Initialiser avec le cache si disponible
      if (_messageCache.containsKey(groupId)) {
        _messageStreams[groupId]!.add(_messageCache[groupId]!);
      }
    }

    return _messageStreams[groupId]!.stream;
  }

  /// Mettre à jour le stream pour un groupe spécifique
  void _updateGroupMessageStream(String groupId, List<GroupMessage> messages) {
    print(
        '📡 [GroupChatRepository] Mise à jour du stream pour groupe $groupId (${messages.length} messages)');

    if (_messageStreams.containsKey(groupId)) {
      _messageStreams[groupId]!.add(messages);
    }
  }

  /// Vider tout le cache
  void clearAllCache() {
    _messageCache.clear();
  }

  /// Nettoyage
  void dispose() {
    _messageSentController.close();
    _messageReceivedController.close();
    _messagesUpdatedController.close();

    // Fermer tous les streams de watch
    for (final stream in _messageStreams.values) {
      stream.close();
    }
    _messageStreams.clear();
  }
}
