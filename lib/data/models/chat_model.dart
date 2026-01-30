class Chat {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final bool isOnline;
  final bool isUnread;
  final String avatarUrl;
  final ChatType type;
  final List<Map<String, dynamic>> participants;
  final int unreadCount; // Nombre de messages non lus
  final DateTime? lastMessageTime; // Temps du dernier message
  final Map<String, dynamic>? metadata; // Métadonnées supplémentaires

  Chat({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.isOnline = false,
    this.isUnread = false,
    required this.avatarUrl,
    this.type = ChatType.personal,
    this.participants = const [],
    this.unreadCount = 0, // Valeur par défaut
    this.lastMessageTime,
    this.metadata,
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
      participants: List<Map<String, dynamic>>.from(json['participants'] ?? []),
      unreadCount: json['unread_count'] ?? 0, // Lecture depuis le JSON
      lastMessageTime: json['last_message_time'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'last_message': lastMessage,
      'time': time,
      'is_online': isOnline,
      'is_unread': isUnread,
      'avatar_url': avatarUrl,
      'type': type.name,
      'participants': participants,
      'unread_count': unreadCount, // Ajout dans le JSON
      'last_message_time': lastMessageTime,
      'metadata': metadata,
    };
  }

  Chat copyWith({
    String? id,
    String? name,
    String? lastMessage,
    String? time,
    bool? isOnline,
    bool? isUnread,
    String? avatarUrl,
    ChatType? type,
    List<Map<String, dynamic>>? participants,
    int? unreadCount,
    DateTime? lastMessageTime,
    Map<String, dynamic>? metadata,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      isOnline: isOnline ?? this.isOnline,
      isUnread: isUnread ?? this.isUnread,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum ChatType {
  personal,
  group,
  broadcast,
}
