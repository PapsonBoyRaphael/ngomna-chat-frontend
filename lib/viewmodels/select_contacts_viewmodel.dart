import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';
import 'package:ngomna_chat/data/repositories/contact_repository.dart';

enum SelectMode { broadcast, group }

class SelectContactsViewModel extends ChangeNotifier {
  final ContactRepository _repository;
  final SelectMode mode;

  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  final Set<String> _selectedContactIds = {};
  bool _isLoading = false;
  String? _error;

  List<Contact> get filteredContacts => _filteredContacts;
  Set<String> get selectedContactIds => _selectedContactIds;
  List<Contact> get selectedContacts =>
      _allContacts.where((c) => _selectedContactIds.contains(c.id)).toList();
  bool get hasSelection => _selectedContactIds.isNotEmpty;
  int get selectedCount => _selectedContactIds.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SelectContactsViewModel(this._repository, this.mode);

  Future<void> loadContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allContacts = await _repository.getAllContacts();
      _filteredContacts = _allContacts;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleContact(String contactId) {
    if (_selectedContactIds.contains(contactId)) {
      _selectedContactIds.remove(contactId);
    } else {
      _selectedContactIds.add(contactId);
    }
    notifyListeners();
  }

  bool isContactSelected(String contactId) {
    return _selectedContactIds.contains(contactId);
  }

  Future<void> searchContacts(String query) async {
    if (query.isEmpty) {
      _filteredContacts = _allContacts;
      notifyListeners();
      return;
    }

    _filteredContacts = _allContacts
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  void clearSelection() {
    _selectedContactIds.clear();
    notifyListeners();
  }
}
