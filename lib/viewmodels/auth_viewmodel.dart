import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:ngomna_chat/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  // Authentication state
  User? _currentUser;
  String? _matricule;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _successMessage;

  // Login form state
  String _matriculeInput = '';
  String _matriculeError = '';

  // Registration form state
  String _regMatricule = '';
  String _regNom = '';
  String _regPrenom = '';
  String _regMinistere = '';
  String _regSexe = 'M';
  final Map<String, String> _registrationErrors = {};

  // Getters
  User? get currentUser => _currentUser;
  String? get matricule => _matricule;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // Login form getters
  String get matriculeInput => _matriculeInput;
  String get matriculeError => _matriculeError;

  // Registration form getters
  String get regMatricule => _regMatricule;
  String get regNom => _regNom;
  String get regPrenom => _regPrenom;
  String get regMinistere => _regMinistere;
  String get regSexe => _regSexe;
  Map<String, String> get registrationErrors => _registrationErrors;

  AuthViewModel(this._repository) {
    _initialize();
  }

  /// Initialize viewmodel (check saved auth state)
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if user is already authenticated
      final isAuth = await _repository.isAuthenticated();
      _isAuthenticated = isAuth;

      if (isAuth) {
        // Load current user from storage
        _currentUser = await _repository.getCurrentUser();
        _matricule = _currentUser?.matricule;
      }

      // Check gateway health (optional)
      try {
        final health = await _repository.checkGatewayHealth();
        print('Gateway status: ${health['status']}');
      } catch (e) {
        print('Gateway health check failed: $e');
      }
    } catch (e) {
      print('Error initializing AuthViewModel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MARK: - Login Methods

  /// Set matricule input for login form
  void setMatriculeInput(String value) {
    _matriculeInput = value.trim();
    _matriculeError = '';
    notifyListeners();
  }

  /// Validate login form
  bool _validateLoginForm() {
    bool isValid = true;

    if (_matriculeInput.isEmpty) {
      _matriculeError = 'Le matricule est requis';
      isValid = false;
    } else if (_matriculeInput.length < 3) {
      _matriculeError = 'Matricule trop court';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  /// Perform login with matricule
  Future<bool> login() async {
    if (!_validateLoginForm()) {
      return false;
    }

    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Appel au dépôt pour se connecter
      final data = await _repository.login(_matriculeInput);

      // Utilisation directe de l'objet `User`
      _currentUser = data['user'] as User;
      _matricule = _currentUser?.matricule;
      _isAuthenticated = true;
      _successMessage = 'Connexion réussie !';

      print('✅ Utilisateur connecté : ${_currentUser?.fullName}');

      return true;
    } catch (e) {
      _error = _repository.getErrorMessage(e);
      print('❌ Échec de la connexion : $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MARK: - Registration Methods

  /// Set registration form fields
  void setRegistrationField(String field, String value) {
    switch (field) {
      case 'matricule':
        _regMatricule = value.trim();
        break;
      case 'nom':
        _regNom = value.trim();
        break;
      case 'prenom':
        _regPrenom = value.trim();
        break;
      case 'ministere':
        _regMinistere = value.trim();
        break;
      case 'sexe':
        _regSexe = value;
        break;
    }

    // Clear error for this field
    _registrationErrors.remove(field);
    notifyListeners();
  }

  /// Validate registration form
  bool _validateRegistrationForm() {
    _registrationErrors.clear();
    bool isValid = true;

    if (_regMatricule.isEmpty) {
      _registrationErrors['matricule'] = 'Le matricule est requis';
      isValid = false;
    }

    if (_regNom.isEmpty) {
      _registrationErrors['nom'] = 'Le nom est requis';
      isValid = false;
    }

    if (_regPrenom.isEmpty) {
      _registrationErrors['prenom'] = 'Le prénom est requis';
      isValid = false;
    }

    if (_regMinistere.isEmpty) {
      _registrationErrors['ministere'] = 'Le ministère est requis';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  /// Perform user registration
  Future<bool> register() async {
    if (!_validateRegistrationForm()) {
      return false;
    }

    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final user = await _repository.register(
        matricule: _regMatricule,
        nom: _regNom,
        prenom: _regPrenom,
        ministere: _regMinistere,
        sexe: _regSexe,
      );

      _successMessage =
          'Compte créé avec succès ! Vous pouvez maintenant vous connecter.';
      _clearRegistrationForm();

      print('✅ User registered: ${user.fullName}');

      return true;
    } catch (e) {
      _error = _repository.getErrorMessage(e);
      print('❌ Registration failed: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear registration form
  void _clearRegistrationForm() {
    _regMatricule = '';
    _regNom = '';
    _regPrenom = '';
    _regMinistere = '';
    _regSexe = 'M';
    _registrationErrors.clear();
  }

  // MARK: - User Management

  /// Logout current user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.logout();

      // Clear all state
      _currentUser = null;
      _matricule = null;
      _isAuthenticated = false;
      _matriculeInput = '';
      _matriculeError = '';

      _successMessage = 'Déconnexion réussie';
      _error = null;

      print('👋 User logged out');
    } catch (e) {
      _error = 'Erreur lors de la déconnexion';
      print('❌ Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh current user profile
  Future<void> refreshProfile() async {
    if (_currentUser == null || _currentUser!.id.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser =
          await _repository.refreshUserProfile(_currentUser!.id);
      _currentUser = updatedUser;

      print('🔄 Profile refreshed: ${updatedUser.fullName}');
    } catch (e) {
      _error = 'Impossible de rafraîchir le profil';
      print('❌ Refresh profile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MARK: - Utility Methods

  /// Clear error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear success messages
  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  /// Clear all messages
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Check if gateway is healthy
  Future<bool> checkGatewayHealth() async {
    try {
      await _repository.checkGatewayHealth();
      return true;
    } catch (e) {
      _error = 'Service temporairement indisponible';
      notifyListeners();
      return false;
    }
  }

  /// Get user by matricule
  Future<User?> getUserByMatricule(String matricule) async {
    try {
      return await _repository.getUserByMatricule(matricule);
    } catch (e) {
      print('❌ Error getting user by matricule: $e');
      return null;
    }
  }

  /// Get multiple users by IDs
  Future<List<User>> getUsersBatch(List<String> userIds) async {
    try {
      return await _repository.getUsersBatch(userIds);
    } catch (e) {
      print('❌ Error getting users batch: $e');
      return [];
    }
  }

  /// Set an error message
  void setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}
