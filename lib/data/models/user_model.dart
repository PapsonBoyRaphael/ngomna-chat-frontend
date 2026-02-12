class User {
  final String id;
  final String matricule;
  final String nom;
  final String prenom;
  final String? ministere;
  final String? sexe;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen; // Dernière connexion
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    this.ministere = '',
    this.sexe = '',
    this.avatarUrl = '',
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
  });

  /// Nom complet (nom + prénom)
  String get fullName => '$nom $prenom';

  /// Initiales pour les avatars
  String get initials {
    if (nom.isNotEmpty && prenom.isNotEmpty) {
      return '${nom[0]}${prenom[0]}'.toUpperCase();
    } else if (nom.isNotEmpty) {
      return nom[0].toUpperCase();
    } else if (prenom.isNotEmpty) {
      return prenom[0].toUpperCase();
    }
    return '?';
  }

  /// Couleur basée sur l'ID pour les avatars
  int get avatarColor {
    var hash = 0;
    for (var i = 0; i < id.length; i++) {
      hash = id.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return hash & 0xFFFFFF;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    if (json["id"].runtimeType == int) {
      json["id"] = json["id"].toString();
    }
    return User(
      id: json['id'] as String? ?? '',
      matricule: json['matricule'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      ministere: json['ministere'] as String? ?? '',
      sexe: json['sexe'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String)
          : (json['lastActivity'] != null
              ? DateTime.tryParse(json['lastActivity'] as String)
              : null),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(
              json['createdAt'] as String) // Utilisation de tryParse
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(
              json['updatedAt'] as String) // Utilisation de tryParse
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
      if (ministere != null && ministere!.isNotEmpty) 'ministere': ministere,
      if (sexe != null && sexe!.isNotEmpty) 'sexe': sexe,
      if (avatarUrl != null && avatarUrl!.isNotEmpty) 'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Copy with method for immutability
  User copyWith({
    String? id,
    String? matricule,
    String? nom,
    String? prenom,
    String? ministere,
    String? sexe,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      matricule: matricule ?? this.matricule,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      ministere: ministere ?? this.ministere,
      sexe: sexe ?? this.sexe,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Copy with specific field (for StorageService)
  User copyWithField(String field, dynamic value) {
    switch (field) {
      case 'id':
        return copyWith(id: value as String);
      case 'matricule':
        return copyWith(matricule: value as String);
      case 'nom':
        return copyWith(nom: value as String);
      case 'prenom':
        return copyWith(prenom: value as String);
      case 'ministere':
        return copyWith(ministere: value as String);
      case 'sexe':
        return copyWith(sexe: value as String);
      case 'avatarUrl':
        return copyWith(avatarUrl: value as String);
      case 'isOnline':
        return copyWith(isOnline: value as bool);
      default:
        return this;
    }
  }

  /// Empty user factory
  static User empty() {
    return User(
      id: '',
      matricule: '',
      nom: '',
      prenom: '',
    );
  }

  /// Check if user is empty
  bool get isEmpty => id.isEmpty && matricule.isEmpty;

  /// Check if user is not empty
  bool get isNotEmpty => !isEmpty;

  /// For display in UI
  @override
  String toString() {
    return 'User(id: $id, matricule: $matricule, nom: $nom, prenom: $prenom, isOnline: $isOnline)';
  }

  /// Equality check
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Batch response model for GET /api/auth/batch
class UserBatchResponse {
  final List<User> users;

  UserBatchResponse({required this.users});

  factory UserBatchResponse.fromJson(List<dynamic> json) {
    return UserBatchResponse(
      users: json.map((userJson) => User.fromJson(userJson)).toList(),
    );
  }
}

/// Login response model for POST /api/auth/login
class LoginResponse {
  final User user;
  final String accessToken;
  final String refreshToken;

  LoginResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

/// Registration response model for POST /api/auth/
class RegistrationResponse {
  final User user;

  RegistrationResponse({required this.user});

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      user: User.fromJson(json),
    );
  }
}

/// Update user response model for PUT /api/auth/:id
class UpdateUserResponse {
  final User user;

  UpdateUserResponse({required this.user});

  factory UpdateUserResponse.fromJson(Map<String, dynamic> json) {
    return UpdateUserResponse(
      user: User.fromJson(json),
    );
  }
}
