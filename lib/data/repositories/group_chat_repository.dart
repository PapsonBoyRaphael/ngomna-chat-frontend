import 'dart:async';
import 'package:ngomna_chat/data/models/group_message_model.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class GroupChatRepository {
  // Singleton pattern
  static GroupChatRepository? _instance;
  GroupChatRepository._internal();

  factory GroupChatRepository() {
    _instance ??= GroupChatRepository._internal();
    return _instance!;
  }

  // Streams for real-time updates
  final StreamController<GroupMessage> _messageSentController =
      StreamController<GroupMessage>.broadcast();
  final StreamController<GroupMessage> _messageReceivedController =
      StreamController<GroupMessage>.broadcast();

  // Public streams
  Stream<GroupMessage> get onMessageSent => _messageSentController.stream;
  Stream<GroupMessage> get onMessageReceived =>
      _messageReceivedController.stream;

  // Cache for group messages
  final Map<String, List<GroupMessage>> _messageCache = {};
  Future<List<GroupMessage>> getGroupMessages(String groupId,
      {int? limit, int? offset}) async {
    // Check cache first
    if (_messageCache.containsKey(groupId)) {
      var messages = _messageCache[groupId]!;

      // Sort messages by creation time (oldest first)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Apply pagination
      final startIndex = offset ?? 0;
      final endIndex = limit != null ? startIndex + limit : messages.length;
      return messages.sublist(
        startIndex.clamp(0, messages.length),
        endIndex.clamp(0, messages.length),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data avec différents expéditeurs
    final messages = [
      GroupMessage(
        id: '1',
        conversationId: groupId,
        senderId: 'user2',
        receiverId: groupId, // Pour les groupes, receiverId = groupId
        content: "I'm looking for a designer",
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isMe: false,
        sender: User(
          id: 'user2',
          matricule: 'user2', // Utilisation de l'ID comme matricule par défaut
          nom: 'Mrs.', // Extraction du prénom
          prenom: 'Aichatou Bello', // Extraction du nom
          avatarUrl: 'assets/avatars/avatar.png',
          isOnline: true,
        ),
      ),
      GroupMessage(
        id: '2',
        conversationId: groupId,
        senderId: 'user3',
        receiverId: groupId,
        content: "UI/UX",
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
        isMe: false,
        sender: User(
          id: 'user3',
          matricule: 'user3', // Utilisation de l'ID comme matricule par défaut
          nom: 'Mr.', // Extraction du prénom
          prenom: 'John Doe', // Extraction du nom
          avatarUrl: 'assets/avatars/avatar2.png',
          isOnline: false,
        ),
      ),
      GroupMessage(
        id: '3',
        conversationId: groupId,
        senderId: 'me',
        receiverId: groupId,
        content: "You are looking in the right place\nI am a UI/UX designer",
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isMe: true,
        sender: User(
          id: 'me',
          matricule: 'me', // Utilisation de l'ID comme matricule par défaut
          nom: 'Me', // Extraction du prénom
          prenom: '', // Extraction du nom
          avatarUrl: 'assets/avatars/avatar.png',
          isOnline: true,
        ),
      ),
    ];

    // Sort messages by creation time (oldest first)
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Cache the messages
    _messageCache[groupId] = messages;

    // Apply pagination
    final startIndex = offset ?? 0;
    final endIndex = limit != null ? startIndex + limit : messages.length;
    return messages.sublist(
      startIndex.clamp(0, messages.length),
      endIndex.clamp(0, messages.length),
    );
  }

  Future<GroupMessage> sendGroupMessage(String groupId, String text) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final message = GroupMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: groupId,
      senderId: 'me',
      receiverId: groupId, // Pour les groupes, receiverId = groupId
      content: text,
      createdAt: DateTime.now(),
      isMe: true,
      sender: User(
        id: 'me',
        matricule: 'me', // Utilisation de l'ID comme matricule par défaut
        nom: 'Me', // Extraction du prénom
        prenom: '', // Extraction du nom
        avatarUrl: 'assets/avatars/avatar.png',
        isOnline: true,
      ),
    );

    // Add to cache
    if (_messageCache.containsKey(groupId)) {
      _messageCache[groupId]!.add(message);
    } else {
      _messageCache[groupId] = [message];
    }

    // Emit event
    _messageSentController.add(message);

    return message;
  }

  // Receive a group message (called by socket service)
  void receiveGroupMessage(GroupMessage message) {
    final groupId = message.conversationId;

    // Add to cache
    if (_messageCache.containsKey(groupId)) {
      _messageCache[groupId]!.add(message);
    } else {
      _messageCache[groupId] = [message];
    }

    // Emit event
    _messageReceivedController.add(message);
  }

  // Clear cache for a specific group
  void clearGroupCache(String groupId) {
    _messageCache.remove(groupId);
  }

  // Clear all cache
  void clearAllCache() {
    _messageCache.clear();
  }

  // Cleanup method
  void dispose() {
    _messageSentController.close();
    _messageReceivedController.close();
  }
}
