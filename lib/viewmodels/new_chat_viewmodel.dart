import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';
import 'package:ngomna_chat/data/repositories/contact_repository.dart';

enum Department {
  all,
  dgb,
  dgd,
  dgi,
  dgt,
}

class NewChatViewModel extends ChangeNotifier {
  final ContactRepository _repository;

  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  List<Contact> _frequentContacts = [];
  bool _isLoading = false;
  String? _error;
  Department _selectedDepartment = Department.all;
  String _searchQuery = '';

  List<Contact> get filteredContacts => _filteredContacts;
  List<Contact> get frequentContacts => _frequentContacts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Department get selectedDepartment => _selectedDepartment;

  NewChatViewModel(this._repository);

  Future<void> loadContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allContacts = await _repository.getAllContacts();
      _frequentContacts = await _repository.getFrequentContacts();
      _filteredContacts = _allContacts;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setDepartmentFilter(Department department) async {
    _selectedDepartment = department;
    _isLoading = true;
    notifyListeners();

    try {
      if (department == Department.all) {
        _filteredContacts = _allContacts;
      } else {
        final deptName = department.name.toUpperCase();
        _filteredContacts = await _repository.getContactsByDepartment(deptName);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchContacts(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredContacts = _allContacts;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _filteredContacts = await _repository.searchContacts(query);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
