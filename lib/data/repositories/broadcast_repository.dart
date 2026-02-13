import 'dart:async';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'auth_repository.dart';

class BroadcastRepository {
  final AuthRepository authRepository;
  final HiveService _hiveService;

  // Cache for broadcast messages
  final Map<String, List<Message>> _messageCache = {};

  // Streams for watching messages (real-time updates)
  final Map<String, StreamController<List<Message>>> _messageStreams = {};

  BroadcastRepository(
    this.authRepository, {
    HiveService? hiveService,
  }) : _hiveService = hiveService ?? HiveService();

  Future<List<Message>> getBroadcastMessages(String broadcastId) async {
    print(
        '📥 [BroadcastRepository] Chargement messages pour broadcast $broadcastId');

    // Vérifier le cache d'abord
    if (_messageCache.containsKey(broadcastId) &&
        _messageCache[broadcastId]!.isNotEmpty) {
      var messages = _messageCache[broadcastId]!;
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('📦 [BroadcastRepository] ${messages.length} messages en cache');
      return messages;
    }

    // Charger depuis Hive
    try {
      final cachedMessages =
          await _hiveService.getMessagesForConversation(broadcastId);
      if (cachedMessages.isNotEmpty) {
        final currentUser = StorageService().getUser();

        _messageCache[broadcastId] = cachedMessages;

        print(
            '💾 [BroadcastRepository] ${cachedMessages.length} messages depuis Hive');
        return cachedMessages;
      }
    } catch (e) {
      print('❌ [BroadcastRepository] Erreur lecture Hive: $e');
    }

    // Charger les données de démo si aucun cache
    await Future.delayed(const Duration(milliseconds: 500));

    // Les broadcasts n'ont que des messages sortants
    final user = await authRepository.getCurrentUser();
    final demoMessages = [
      Message(
        id: '1',
        conversationId: broadcastId,
        senderId: user?.matricule ?? 'me',
        receiverId: '', // Broadcast n'a pas de destinataire spécifique
        content: "You are looking in the right place\nI am a UI/UX designer",
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.delivered,
        isMe: true,
      ),
      Message(
        id: '2',
        conversationId: broadcastId,
        senderId: user?.matricule ?? 'me',
        receiverId: '', // Broadcast n'a pas de destinataire spécifique
        content: "I will call you to discuss",
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: MessageStatus.read,
        isMe: true,
      ),
    ];

    _messageCache[broadcastId] = demoMessages;
    return demoMessages;
  }

  Future<Message> sendBroadcastMessage(String broadcastId, String text) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final user = await authRepository.getCurrentUser();

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: broadcastId,
      senderId: user?.matricule ?? 'me',
      receiverId: '', // Broadcast n'a pas de destinataire spécifique
      content: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      isMe: true,
    );
  }

  /// Écouter les changements de messages du broadcast en temps réel
  Stream<List<Message>> watchBroadcastMessages(String broadcastId) {
    print(
        '👂 [BroadcastRepository] watchBroadcastMessages: création du stream pour $broadcastId');

    if (!_messageStreams.containsKey(broadcastId)) {
      _messageStreams[broadcastId] =
          StreamController<List<Message>>.broadcast();

      // Initialiser avec le cache si disponible
      if (_messageCache.containsKey(broadcastId)) {
        _messageStreams[broadcastId]!.add(_messageCache[broadcastId]!);
      }
    }

    return _messageStreams[broadcastId]!.stream;
  }

  /// Mettre à jour le stream pour un broadcast spécifique
  void _updateBroadcastMessageStream(
      String broadcastId, List<Message> messages) {
    print(
        '📡 [BroadcastRepository] Mise à jour du stream pour broadcast $broadcastId (${messages.length} messages)');

    if (_messageStreams.containsKey(broadcastId)) {
      _messageStreams[broadcastId]!.add(messages);
    }
  }

  // Récupérer la liste des destinataires du broadcast
  Future<List<String>> getBroadcastRecipients(String broadcastId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      'Mrs. Aichatou Bello',
      'Mr. Ngah Owona',
      'Mrs. Angu Telma',
      // etc...
    ];
  }

  /// Nettoyage
  void dispose() {
    print('🧹 [BroadcastRepository] dispose() - fermeture des streams');

    // Fermer tous les streams de watch
    for (final stream in _messageStreams.values) {
      stream.close();
    }
    _messageStreams.clear();
    _messageCache.clear();
  }
}
