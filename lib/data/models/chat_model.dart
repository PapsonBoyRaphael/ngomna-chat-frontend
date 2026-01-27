class Chat {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final bool isOnline;
  final bool isUnread;
  final String avatarUrl;
  final ChatType type;

  Chat({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.isOnline = false,
    this.isUnread = false,
    required this.avatarUrl,
    this.type = ChatType.personal,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      lastMessage: json['last_message'],
      time: json['time'],
      isOnline: json['is_online'] ?? false,
      isUnread: json['is_unread'] ?? false,
      avatarUrl: json['avatar_url'],
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.personal,
      ),
    );
  }
}

enum ChatType {
  personal,
  group,
  broadcast,
}
