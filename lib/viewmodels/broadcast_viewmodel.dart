import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/repositories/broadcast_repository.dart';

class BroadcastViewModel extends ChangeNotifier {
  final BroadcastRepository _repository;
  final String broadcastId;

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

  BroadcastViewModel(this._repository, this.broadcastId);

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.getBroadcastMessages(broadcastId);
      _recipients = await _repository.getBroadcastRecipients(broadcastId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Ajouter immédiatement le message
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: broadcastId,
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
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
