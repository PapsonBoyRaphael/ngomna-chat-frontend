import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/repositories/broadcast_repository.dart';
import 'package:ngomna_chat/data/repositories/auth_repository.dart';

class BroadcastViewModel extends ChangeNotifier {
  final BroadcastRepository _repository;
  final AuthRepository _authRepository;
  final String broadcastId;
  final Chat? _chat;

  List<Message> _messages = [];
  List<String> _recipients = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  List<Message> get messages => _messages;
  List<String> get recipients => _recipients;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  BroadcastViewModel(this._repository, this._authRepository, this.broadcastId,
      Map<String, dynamic>? conversationData)
      : _chat =
            conversationData != null ? Chat.fromJson(conversationData) : null;

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.getBroadcastMessages(broadcastId);
      _recipients = await _repository.getBroadcastRecipients(broadcastId);

      // Vérifier si on doit charger depuis le serveur
      final totalMessagesInMetadata = _chat?.metadata.stats.totalMessages ?? 0;
      final cachedMessagesCount = _messages.length;

      print(
          '📊 [BroadcastViewModel] Comparaison: cache=$cachedMessagesCount, metadata.stats.totalMessages=$totalMessagesInMetadata');

      if (cachedMessagesCount != totalMessagesInMetadata) {
        print(
            '🌐 [BroadcastViewModel] Chargement depuis le serveur (différence détectée)');
        // TODO: Implémenter le chargement depuis le serveur pour broadcast
        // await _repository.getBroadcastMessagesFromServer(broadcastId);
      } else {
        print(
            '✅ [BroadcastViewModel] Cache à jour, pas de chargement serveur nécessaire');
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Ajouter immédiatement le message
    final user = await _authRepository.getCurrentUser();
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: broadcastId,
      senderId: user?.matricule ?? 'unknown',
      receiverId: '', // Broadcast n'a pas de destinataire spécifique
      content: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      isMe: true,
    );

    _messages.add(tempMessage);
    notifyListeners();

    _isSending = true;

    try {
      final sentMessage =
          await _repository.sendBroadcastMessage(broadcastId, text);

      final index = _messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        _messages[index] = sentMessage;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      _messages.removeWhere((m) => m.id == tempMessage.id);
    }

    _isSending = false;
    notifyListeners();
  }
}
