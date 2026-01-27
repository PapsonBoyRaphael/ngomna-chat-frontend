class User {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}
