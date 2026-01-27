import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/group_message_model.dart';
import 'package:ngomna_chat/data/repositories/group_chat_repository.dart';

class GroupChatViewModel extends ChangeNotifier {
  final GroupChatRepository _repository;
  final String groupId;

  List<GroupMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  List<GroupMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  GroupChatViewModel(this._repository, this.groupId);

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.getGroupMessages(groupId);
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
