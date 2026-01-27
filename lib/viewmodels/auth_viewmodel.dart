import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  String? _matricule;
  String? _post;
  bool _isLoading = false;
  String? _error;

  String? get matricule => _matricule;
  String? get post => _post;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthViewModel(this._repository);

  void setMatricule(String matricule) {
    _matricule = matricule;
    notifyListeners();
  }

  void setPost(String post) {
    _post = post;
    notifyListeners();
  }

  Future<bool> submitAuthentication() async {
    if (_matricule == null || _post == null) {
      _error = 'Matricule et poste requis';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.authenticate(_matricule!, _post!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
