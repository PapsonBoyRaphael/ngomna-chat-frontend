import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/group_message_model.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/repositories/group_chat_repository.dart';

class GroupChatViewModel extends ChangeNotifier {
  final GroupChatRepository _repository;
  final String groupId;
  final Chat? _chat;

  List<GroupMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

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

  GroupChatViewModel(
      this._repository, this.groupId, Map<String, dynamic>? conversationData)
      : _chat =
            conversationData != null ? Chat.fromJson(conversationData) : null;

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
    }

    _isSending = false;
    notifyListeners();
  }
}
