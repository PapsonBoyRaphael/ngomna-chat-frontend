class Contact {
  final String id;
  final String name;
  final String avatarUrl;
  final String department; // DGB, DGD, DGI, etc.
  final String post;
  final bool isOnline;
  final bool isFrequent; // Pour les conversations fréquentes
  final String? lastMessage;
  final String? lastMessageTime;

  Contact({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.department,
    required this.post,
    this.isOnline = false,
    this.isFrequent = false,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      department: json['department'],
      post: json['post'],
      isOnline: json['is_online'] ?? false,
      isFrequent: json['is_frequent'] ?? false,
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'],
    );
  }
}
