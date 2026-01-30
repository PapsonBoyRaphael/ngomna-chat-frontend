import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/repositories/message_repository.dart';
import 'package:ngomna_chat/data/repositories/auth_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final MessageRepository _repository;
  final AuthRepository _authRepository;
  final String chatId;

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  ChatViewModel(this._repository, this._authRepository, this.chatId);

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.getMessages(chatId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Resolve the Future<User?> before accessing matricule
    final user = await _authRepository.getCurrentUser();
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: chatId,
      senderId: user?.matricule ?? 'unknown',
      receiverId: '', // Sera défini plus tard
      content: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      isMe: true,
    );

    _messages.add(tempMessage);
    notifyListeners();

    _isSending = true;

    try {
      final sentMessage = await _repository.sendMessage(
          conversationId: chatId,
          content: text,
          senderId: user?.matricule ?? 'unknown');

      // Remplacer le message temporaire par le message envoyé
      final index = _messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        _messages[index] = sentMessage;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      // Retirer le message en cas d'erreur
      _messages.removeWhere((m) => m.id == tempMessage.id);
    }

    _isSending = false;
    notifyListeners();
  }
}
