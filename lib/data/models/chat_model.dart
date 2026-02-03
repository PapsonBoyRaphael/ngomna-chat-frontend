import 'package:hive/hive.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';

part 'chat_model.g.dart';

// Fonction helper pour extraire les dates MongoDB
DateTime _extractDate(dynamic value) {
  if (value is Map && value.containsKey('\$date')) {
    final dateValue = value['\$date'];
    if (dateValue is String) {
      return DateTime.parse(dateValue); // Format ISO string
    } else if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue); // Timestamp int
    }
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.now(); // Fallback
}

@HiveType(typeId: 1)
class Chat {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ChatType type;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final List<String> participants;

  @HiveField(5)
  final String createdBy;

  @HiveField(6)
  final bool isActive;

  @HiveField(7)
  final bool isArchived;

  @HiveField(8)
  final List<ParticipantMetadata> userMetadata;

  @HiveField(9)
  final Map<String, int> unreadCounts;

  @HiveField(10)
  final LastMessage? lastMessage;

  @HiveField(11)
  final DateTime lastMessageAt;

  @HiveField(12)
  final ChatSettings settings;

  @HiveField(13)
  final ChatMetadata metadata;

  @HiveField(14)
  final ChatIntegrations integrations;

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  final DateTime updatedAt;

  // Calculated fields (not stored in Hive)
  int get unreadCount {
    // TODO: Récupérer le count pour l'utilisateur courant
    if (unreadCounts.isEmpty) return 0;
    return unreadCounts.values.reduce((a, b) => a + b);
  }

  String get displayName {
    if (type == ChatType.personal && userMetadata.length >= 2) {
      final StorageService storageService = StorageService();
      final currentUserMatricule = storageService.getUser()?.matricule;

      if (currentUserMatricule != null) {
        final otherParticipant = userMetadata.firstWhere(
          (meta) => meta.userId != currentUserMatricule,
          orElse: () => userMetadata.first,
        );

        // Utiliser prénom et nom séparés pour un affichage plus naturel
        final fullDisplayName =
            '${otherParticipant.prenom} ${otherParticipant.nom}'.trim();

        return fullDisplayName.isNotEmpty ? fullDisplayName : name;
      }
    }

    return name;
  }

  String? get avatarUrl {
    if (type == ChatType.personal && userMetadata.length >= 2) {
      final StorageService storageService = StorageService();
      final currentUserMatricule = storageService.getUser()?.matricule;

      if (currentUserMatricule != null) {
        final otherParticipant = userMetadata.firstWhere(
          (meta) => meta.userId != currentUserMatricule,
          orElse: () => userMetadata.first,
        );

        return otherParticipant.avatar;
      }
    }
    return null;
  }

  Chat({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    required this.participants,
    required this.createdBy,
    this.isActive = true,
    this.isArchived = false,
    required this.userMetadata,
    required this.unreadCounts,
    this.lastMessage,
    required this.lastMessageAt,
    required this.settings,
    required this.metadata,
    required this.integrations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    // Helper pour extraire les IDs MongoDB
    String _extractId(dynamic value) {
      if (value is Map && value.containsKey('\$oid')) {
        return value['\$oid'].toString();
      }
      return value?.toString() ?? '';
    }

    // Helper pour extraire les dates MongoDB
    DateTime _extractDate(dynamic value) {
      if (value is Map && value.containsKey('\$date')) {
        final dateValue = value['\$date'];
        if (dateValue is String) {
          return DateTime.parse(dateValue); // Format ISO string
        } else if (dateValue is int) {
          return DateTime.fromMillisecondsSinceEpoch(
              dateValue); // Timestamp int
        }
      }
      if (value is String) {
        return DateTime.parse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now(); // Fallback
    }

    // Helper pour extraire unreadCounts depuis userMetadata
    // Prioritaire: extraire depuis userMetadata[].unreadCount au lieu de unreadCounts
    Map<String, int> extractUnreadCountsFromMetadata(
        List<ParticipantMetadata> userMetadataList, dynamic unreadCountsData) {
      final Map<String, int> result = {};

      // Première priorité: extraire depuis userMetadata (source de vérité du serveur)
      if (userMetadataList.isNotEmpty) {
        print('📌 Extraction unreadCounts depuis userMetadata');
        for (final metadata in userMetadataList) {
          result[metadata.userId] = metadata.unreadCount;
          print(
              '   - userId: ${metadata.userId}, unreadCount: ${metadata.unreadCount}');
        }
        return result;
      }

      // Fallback: parser depuis unreadCounts (ancien format)
      if (unreadCountsData is Map) {
        print(
            '📌 Extraction unreadCounts depuis champ unreadCounts (fallback)');
        final Map<String, int> parsedResult = {};
        unreadCountsData.forEach((key, value) {
          final userId = _extractId(key);
          int count = 0;
          if (value is int) {
            count = value;
          } else if (value is String) {
            count = int.tryParse(value) ?? 0;
          } else if (value is Map && value.containsKey('\$oid')) {
            // Si c'est un ObjectId, essayer de parser la valeur comme int
            final oidValue = value['\$oid'];
            if (oidValue is String) {
              count = int.tryParse(oidValue) ?? 0;
            } else if (oidValue is int) {
              count = oidValue;
            }
          }
          parsedResult[userId] = count;
        });
        return parsedResult;
      }

      return result;
    }

    // Parser createdAt en premier
    final createdAt = _extractDate(json['createdAt']);

    final chatType = _stringToChatType(json['type']?.toString());
    final userMetadataList = (() {
      final userMetadataData = json['userMetadata'];

      // Si c'est une liste (format complet attendu)
      if (userMetadataData is List<dynamic>) {
        print(
            '✅ userMetadata est une LISTE avec ${userMetadataData.length} éléments');
        return userMetadataData
            .map((data) =>
                ParticipantMetadata.fromJson(data as Map<String, dynamic>))
            .toList();
      }

      // Si c'est un objet unique (format actuel du serveur - BUG BACKEND)
      if (userMetadataData is Map<String, dynamic>) {
        print(
            '⚠️ userMetadata est un OBJET unique (devrait être une liste) - Conversion...');
        return [ParticipantMetadata.fromJson(userMetadataData)];
      }

      // Sinon, retourner une liste vide
      print('❌ userMetadata est null ou dans un format inconnu');
      return <ParticipantMetadata>[];
    })();

    String chatName = json['name']?.toString() ?? 'Conversation';
    if (chatType == ChatType.personal && userMetadataList.length >= 2) {
      final storageService = StorageService();
      final currentUserMatricule = storageService.getUser()?.matricule;
      if (currentUserMatricule != null) {
        final otherParticipant = userMetadataList.firstWhere(
          (meta) => meta.userId != currentUserMatricule,
          orElse: () => userMetadataList.first,
        );
        final fullName =
            '${otherParticipant.prenom} ${otherParticipant.nom}'.trim();
        if (fullName.isNotEmpty) {
          chatName = fullName;
        }
      }
    }

    return Chat(
      id: _extractId(json['_id']),
      name: chatName,
      type: chatType,
      description: json['description']?.toString(),
      participants: (json['participants'] is List<dynamic>)
          ? (json['participants'] as List<dynamic>)
              .map((p) => _extractId(p))
              .toList()
          : [],
      createdBy: _extractId(json['createdBy']),
      isActive: json['isActive'] as bool? ?? true,
      isArchived: json['isArchived'] as bool? ?? false,
      userMetadata: userMetadataList,

      unreadCounts: extractUnreadCountsFromMetadata(
          userMetadataList, json['unreadCounts']),
      lastMessage: json['lastMessage'] != null
          ? LastMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageAt: json['lastMessage'] != null
          ? _extractDate(json['lastMessageAt'])
          : createdAt, // Si pas de dernier message, utiliser createdAt
      settings: ChatSettings.fromJson(json['settings'] ?? {}),
      metadata: ChatMetadata.fromJson(json['metadata'] ?? {}),
      integrations: ChatIntegrations.fromJson(json['integrations'] ?? {}),
      createdAt: createdAt,
      updatedAt: _extractDate(json['updatedAt']),
    );
  }

  // Factory for empty Chat
  factory Chat.empty() {
    final now = DateTime.now();
    return Chat(
      id: '',
      name: '',
      type: ChatType.personal,
      participants: [],
      createdBy: '',
      userMetadata: [],
      unreadCounts: {},
      lastMessageAt: now, // Utiliser la même date que createdAt
      settings: ChatSettings(),
      metadata: ChatMetadata(stats: ChatStats(lastActivity: now)),
      integrations: ChatIntegrations(),
      createdAt: now,
      updatedAt: now,
    );
  }

  static ChatType _stringToChatType(String? type) {
    switch (type?.toUpperCase()) {
      case 'GROUP':
        return ChatType.group;
      case 'BROADCAST':
        return ChatType.broadcast;
      case 'CHANNEL':
        return ChatType.channel;
      default:
        return ChatType.personal; // PRIVATE -> personal
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': {'\$oid': id},
      'name': name,
      'type': _chatTypeToString(type),
      'description': description,
      'participants': participants,
      'createdBy': createdBy,
      'isActive': isActive,
      'isArchived': isArchived,
      'userMetadata': userMetadata.map((meta) => meta.toJson()).toList(),
      'unreadCounts': unreadCounts,
      'lastMessage': lastMessage?.toJson(),
      'lastMessageAt': {'\$date': lastMessageAt.toIso8601String()},
      'settings': settings.toJson(),
      'metadata': metadata.toJson(),
      'integrations': integrations.toJson(),
      'createdAt': {'\$date': createdAt.toIso8601String()},
      'updatedAt': {'\$date': updatedAt.toIso8601String()},
    };
  }

  static String _chatTypeToString(ChatType type) {
    switch (type) {
      case ChatType.group:
        return 'GROUP';
      case ChatType.broadcast:
        return 'BROADCAST';
      case ChatType.channel:
        return 'CHANNEL';
      default:
        return 'PRIVATE';
    }
  }

  Chat copyWith({
    String? id,
    String? name,
    ChatType? type,
    String? description,
    List<String>? participants,
    String? createdBy,
    bool? isActive,
    bool? isArchived,
    List<ParticipantMetadata>? userMetadata,
    Map<String, int>? unreadCounts,
    LastMessage? lastMessage,
    DateTime? lastMessageAt,
    ChatSettings? settings,
    ChatMetadata? metadata,
    ChatIntegrations? integrations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      userMetadata: userMetadata ?? this.userMetadata,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
      integrations: integrations ?? this.integrations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 2)
class ParticipantMetadata {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final int unreadCount;

  @HiveField(2)
  final DateTime? lastReadAt;

  @HiveField(3)
  final bool isMuted;

  @HiveField(4)
  final bool isPinned;

  @HiveField(5)
  final String? customName;

  @HiveField(6)
  final NotificationSettings notificationSettings;

  @HiveField(7)
  final String name;

  @HiveField(8)
  final String? avatar;

  @HiveField(9)
  final String metadataId;

  // Champs calculés pour nom et prénom
  String get nom {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return parts.sublist(0, parts.length - 1).join(' ');
    }
    return name;
  }

  String get prenom {
    final parts = name.split(' ');
    if (parts.isNotEmpty) {
      return parts.last;
    }
    return '';
  }

  ParticipantMetadata({
    required this.userId,
    required this.unreadCount,
    this.lastReadAt,
    required this.isMuted,
    required this.isPinned,
    this.customName,
    required this.notificationSettings,
    required this.name,
    this.avatar,
    required this.metadataId,
  });

  factory ParticipantMetadata.fromJson(Map<String, dynamic> json) {
    return ParticipantMetadata(
      userId: json['userId']?.toString() ?? '',
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastReadAt:
          json['lastReadAt'] != null ? _extractDate(json['lastReadAt']) : null,
      isMuted: json['isMuted'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      customName: json['customName']?.toString(),
      notificationSettings:
          NotificationSettings.fromJson(json['notificationSettings'] ?? {}),
      name: '${json['prenom'] ?? ''} ${json['nom'] ?? ''}'
          .trim(), // Combiner prenom et nom
      avatar: json['avatar']?.toString(),
      metadataId:
          json['_id']?['\$oid']?.toString() ?? json['_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'unreadCount': unreadCount,
      'lastReadAt':
          lastReadAt != null ? {'\$date': lastReadAt!.toIso8601String()} : null,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'customName': customName,
      'notificationSettings': notificationSettings.toJson(),
      'name': name,
      'avatar': avatar,
      '_id': {'\$oid': metadataId},
    };
  }
}

@HiveType(typeId: 3)
class NotificationSettings {
  @HiveField(0)
  final bool enabled;

  @HiveField(1)
  final bool sound;

  @HiveField(2)
  final bool vibration;

  NotificationSettings({
    required this.enabled,
    required this.sound,
    required this.vibration,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      sound: json['sound'] as bool? ?? true,
      vibration: json['vibration'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'sound': sound,
      'vibration': vibration,
    };
  }
}

@HiveType(typeId: 4)
class LastMessage {
  @HiveField(0)
  final String content;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String? senderName;

  @HiveField(4)
  final DateTime timestamp;

  LastMessage({
    required this.content,
    required this.type,
    required this.senderId,
    this.senderName,
    required this.timestamp,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'TEXT',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString(),
      timestamp: _extractDate(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': {'\$date': timestamp.toIso8601String()},
    };
  }
}

@HiveType(typeId: 5)
class ChatSettings {
  @HiveField(0)
  final bool allowInvites;

  @HiveField(1)
  final bool isPublic;

  @HiveField(2)
  final int maxParticipants;

  @HiveField(3)
  final int messageRetention;

  @HiveField(4)
  final int autoDeleteAfter;

  @HiveField(5)
  final List<String> broadcastAdmins;

  @HiveField(6)
  final List<String> broadcastRecipients;

  ChatSettings({
    this.allowInvites = true,
    this.isPublic = false,
    this.maxParticipants = 2,
    this.messageRetention = 0,
    this.autoDeleteAfter = 0,
    this.broadcastAdmins = const [],
    this.broadcastRecipients = const [],
  });

  factory ChatSettings.fromJson(Map<String, dynamic> json) {
    return ChatSettings(
      allowInvites: json['allowInvites'] as bool? ?? true,
      isPublic: json['isPublic'] as bool? ?? false,
      maxParticipants: json['maxParticipants'] as int? ?? 2,
      messageRetention: json['messageRetention'] as int? ?? 0,
      autoDeleteAfter: json['autoDeleteAfter'] as int? ?? 0,
      broadcastAdmins: List<String>.from(json['broadcastAdmins'] ?? []),
      broadcastRecipients: List<String>.from(json['broadcastRecipients'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowInvites': allowInvites,
      'isPublic': isPublic,
      'maxParticipants': maxParticipants,
      'messageRetention': messageRetention,
      'autoDeleteAfter': autoDeleteAfter,
      'broadcastAdmins': broadcastAdmins,
      'broadcastRecipients': broadcastRecipients,
    };
  }
}

@HiveType(typeId: 6)
class ChatMetadata {
  @HiveField(0)
  final bool autoCreated;

  @HiveField(1)
  final String createdFrom;

  @HiveField(2)
  final int version;

  @HiveField(3)
  final List<String> tags;

  @HiveField(4)
  final List<AuditLogEntry> auditLog;

  @HiveField(5)
  final ChatStats stats;

  ChatMetadata({
    this.autoCreated = false,
    this.createdFrom = '',
    this.version = 1,
    this.tags = const [],
    this.auditLog = const [],
    required this.stats,
  });

  factory ChatMetadata.fromJson(Map<String, dynamic> json) {
    return ChatMetadata(
      autoCreated: json['autoCreated'] as bool? ?? false,
      createdFrom: json['createdFrom']?.toString() ?? '',
      version: json['version'] as int? ?? 1,
      tags: List<String>.from(json['tags'] ?? []),
      auditLog: (json['auditLog'] as List<dynamic>?)
              ?.map((data) => AuditLogEntry.fromJson(data))
              .toList() ??
          [],
      stats: ChatStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoCreated': autoCreated,
      'createdFrom': createdFrom,
      'version': version,
      'tags': tags,
      'auditLog': auditLog.map((log) => log.toJson()).toList(),
      'stats': stats.toJson(),
    };
  }
}

@HiveType(typeId: 7)
class AuditLogEntry {
  @HiveField(0)
  final String action;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final Map<String, dynamic> details;

  @HiveField(4)
  final Map<String, dynamic> metadata;

  @HiveField(5)
  final String logId;

  AuditLogEntry({
    required this.action,
    required this.userId,
    required this.timestamp,
    required this.details,
    required this.metadata,
    required this.logId,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      action: json['action']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      timestamp: _extractDate(json['timestamp']),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      logId: json['_id']?['\$oid']?.toString() ?? json['_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'userId': userId,
      'timestamp': {'\$date': timestamp.toIso8601String()},
      'details': details,
      'metadata': metadata,
      '_id': {'\$oid': logId},
    };
  }
}

@HiveType(typeId: 8)
class ChatStats {
  @HiveField(0)
  final int totalMessages;

  @HiveField(1)
  final int totalFiles;

  @HiveField(2)
  final int totalParticipants;

  @HiveField(3)
  final DateTime lastActivity;

  ChatStats({
    this.totalMessages = 0,
    this.totalFiles = 0,
    this.totalParticipants = 0,
    required this.lastActivity,
  });

  factory ChatStats.fromJson(Map<String, dynamic> json) {
    return ChatStats(
      totalMessages: json['totalMessages'] as int? ?? 0,
      totalFiles: json['totalFiles'] as int? ?? 0,
      totalParticipants: json['totalParticipants'] as int? ?? 0,
      lastActivity: _extractDate(json['lastActivity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMessages': totalMessages,
      'totalFiles': totalFiles,
      'totalParticipants': totalParticipants,
      'lastActivity': {'\$date': lastActivity.toIso8601String()},
    };
  }
}

@HiveType(typeId: 9)
class ChatIntegrations {
  @HiveField(0)
  final List<dynamic> webhooks;

  @HiveField(1)
  final List<dynamic> bots;

  ChatIntegrations({
    this.webhooks = const [],
    this.bots = const [],
  });

  factory ChatIntegrations.fromJson(Map<String, dynamic> json) {
    return ChatIntegrations(
      webhooks: List<dynamic>.from(json['webhooks'] ?? []),
      bots: List<dynamic>.from(json['bots'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'webhooks': webhooks,
      'bots': bots,
    };
  }
}

enum ChatType {
  personal, // PRIVATE dans le backend
  group, // GROUP
  broadcast, // BROADCAST
  channel, // CHANNEL
}

class ChatTypeAdapter extends TypeAdapter<ChatType> {
  @override
  final int typeId = 17; // Choisir un ID unique non utilisé

  @override
  ChatType read(BinaryReader reader) {
    final index = reader.readInt();
    return ChatType.values[index];
  }

  @override
  void write(BinaryWriter writer, ChatType obj) {
    writer.writeInt(obj.index);
  }
}

// Add the ChatHelpers extension
extension ChatHelpers on Chat {
  static Chat empty() {
    return Chat(
      id: '',
      name: '',
      type: ChatType.personal,
      participants: [],
      createdBy: '',
      userMetadata: [],
      unreadCounts: {},
      lastMessageAt: DateTime.now(),
      settings: ChatSettings(),
      metadata: ChatMetadata(stats: ChatStats(lastActivity: DateTime.now())),
      integrations: ChatIntegrations(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  DateTime? get lastMessageTime => lastMessage?.timestamp;

  String? get avatarUrl {
    if (type == ChatType.personal && userMetadata.length == 2) {
      final StorageService storageService = StorageService();
      final currentUserMatricule = storageService.getUser()?.matricule;

      if (currentUserMatricule != null) {
        final otherParticipant = userMetadata.firstWhere(
          (meta) => meta.userId != currentUserMatricule,
          orElse: () => userMetadata.first,
        );

        return otherParticipant.avatar;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get participantsList {
    return userMetadata
        .map((meta) => {
              'id': meta.userId,
              'name': meta.name,
              'avatar': meta.avatar,
            })
        .toList();
  }

  // Additional getters for compatibility
  bool get isUnread => unreadCount > 0;

  DateTime get time => lastMessageAt;

  bool get isOnline => false; // TODO: Implement based on user status
}
