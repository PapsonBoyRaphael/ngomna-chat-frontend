import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/repositories/chat_repository.dart';

class ChatListViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  List<Chat> _chats = [];
  List<Chat> _filteredChats = [];
  bool _isLoading = false;
  String? _error;
  ChatFilter _currentFilter = ChatFilter.all;
  String _searchQuery = '';

  List<Chat> get chats => _filteredChats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ChatFilter get currentFilter => _currentFilter;

  ChatListViewModel(this._repository);

  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = await _repository.getChats();
      _filteredChats = _chats;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setFilter(ChatFilter filter) async {
    _currentFilter = filter;
    _isLoading = true;
    notifyListeners();

    try {
      _filteredChats = await _repository.filterChats(filter);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchChats(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredChats = _chats;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _filteredChats = await _repository.searchChats(query);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
