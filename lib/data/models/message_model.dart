import 'package:hive/hive.dart';

part 'message_model.g.dart';

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

enum MessageType {
  text, // TEXT
  image, // IMAGE
  file, // FILE
  audio, // AUDIO
  video, // VIDEO
  location, // LOCATION
  contact, // CONTACT
  system, // SYSTEM (notifications système)
  broadcast, // BROADCAST (messages de diffusion)
}

enum MessageStatus {
  sending, // En cours d'envoi (client seulement)
  sent, // Envoyé au serveur
  delivered, // Livré aux destinataires
  read, // Lu par le destinataire
  failed, // Échec d'envoi
  pending, // En attente de livraison (server side)
}

enum MessagePriority {
  low, // LOW
  normal, // NORMAL
  high, // HIGH
  urgent, // URGENT
}

class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 18;

  @override
  MessageType read(BinaryReader reader) {
    final index = reader.readInt();
    return MessageType.values[index];
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    writer.writeInt(obj.index);
  }
}

class MessageStatusAdapter extends TypeAdapter<MessageStatus> {
  @override
  final int typeId = 19;

  @override
  MessageStatus read(BinaryReader reader) {
    final index = reader.readInt();
    return MessageStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, MessageStatus obj) {
    writer.writeInt(obj.index);
  }
}

class MessagePriorityAdapter extends TypeAdapter<MessagePriority> {
  @override
  final int typeId = 20;

  @override
  MessagePriority read(BinaryReader reader) {
    final index = reader.readInt();
    return MessagePriority.values[index];
  }

  @override
  void write(BinaryWriter writer, MessagePriority obj) {
    writer.writeInt(obj.index);
  }
}

@HiveType(typeId: 10)
class Message {
  @HiveField(0)
  final String id; // MongoDB _id

  @HiveField(1)
  final String? temporaryId; // ID temporaire client pour mapping

  @HiveField(2)
  final String conversationId; // ID conversation/groupe

  @HiveField(3)
  final String senderId; // ID expéditeur

  @HiveField(4)
  final String? senderMatricule; // Matricule expéditeur

  @HiveField(5)
  final String? senderName; // Nom expéditeur (enrichi)

  @HiveField(6)
  final String? senderAvatar; // Avatar expéditeur

  @HiveField(7)
  final String receiverId; // ID destinataire

  @HiveField(8)
  final String content; // Contenu texte

  @HiveField(9)
  final MessageType type; // Type de message

  @HiveField(10)
  final MessageStatus status; // Statut de livraison

  @HiveField(11)
  final MessagePriority priority; // Priorité du message

  @HiveField(12)
  final DateTime createdAt; // Date création

  @HiveField(13)
  final DateTime? updatedAt; // Date modification

  @HiveField(14)
  final DateTime? deletedAt; // Date suppression (soft delete)

  @HiveField(15)
  final DateTime? editedAt; // Date édition

  @HiveField(16)
  final DateTime? readAt; // Date lecture

  @HiveField(17)
  final DateTime? receivedAt; // Date réception

  @HiveField(18)
  final bool isSystemMessage; // Message système

  @HiveField(19)
  final String? replyTo; // ID du message répondu

  @HiveField(20)
  final List<String> reactions; // Réactions (simplifié)

  @HiveField(21)
  final MessageMetadata? metadata; // Métadonnées structurées

  @HiveField(22)
  final String? fileId; // ID du fichier attaché

  @HiveField(23)
  final String? fileUrl; // URL du fichier

  @HiveField(24)
  final String? fileName; // Nom du fichier

  @HiveField(25)
  final int? fileSize; // Taille du fichier en bytes

  @HiveField(26)
  final String? mimeType; // Type MIME du fichier

  @HiveField(27)
  final int? duration; // Durée pour audio/vidéo en secondes

  @HiveField(28)
  final List<String> readBy; // Liste des IDs utilisateurs ayant lu

  @HiveField(29)
  final List<String> deliveredTo; // Liste des IDs utilisateurs ayant reçu

  // Pour UI seulement (non stocké dans Hive)
  final bool isMe; // Message de l'utilisateur courant

  Message({
    required this.id,
    this.temporaryId,
    required this.conversationId,
    required this.senderId,
    this.senderMatricule,
    this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.priority = MessagePriority.normal,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.editedAt,
    this.readAt,
    this.receivedAt,
    this.isSystemMessage = false,
    this.replyTo,
    this.reactions = const [],
    this.metadata,
    this.fileId,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.duration,
    this.readBy = const [],
    this.deliveredTo = const [],
    this.isMe = false,
  });

  /// Getter pour compatibilité avec l'ancien code
  DateTime get timestamp => createdAt;

  /// Factory depuis JSON backend
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: (json['_id'] is Map<String, dynamic>
              ? json['_id']['\$oid']?.toString()
              : json['_id']?.toString()) ??
          '',
      temporaryId: json['temporaryId'] as String?,
      conversationId: (json['conversationId'] is Map<String, dynamic>
              ? json['conversationId']['\$oid']?.toString()
              : json['conversationId']?.toString()) ??
          '',
      senderId: json['senderId'] as String? ?? '',
      senderMatricule: json['senderMatricule'] as String?,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      receiverId: json['receiverId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: _parseMessageType(json['type'] as String?),
      status: _parseMessageStatus(json['status'] as String?),
      priority: _parseMessagePriority(json['priority'] as String?),
      createdAt: _extractDate(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? _extractDate(json['updatedAt']) : null,
      deletedAt:
          json['deletedAt'] != null ? _extractDate(json['deletedAt']) : null,
      editedAt:
          json['editedAt'] != null ? _extractDate(json['editedAt']) : null,
      readAt: json['readAt'] != null ? _extractDate(json['readAt']) : null,
      receivedAt:
          json['receivedAt'] != null ? _extractDate(json['receivedAt']) : null,
      isSystemMessage: json['isSystemMessage'] as bool? ?? false,
      replyTo: json['replyTo'] is Map<String, dynamic>
          ? json['replyTo']['\$oid']?.toString()
          : json['replyTo']?.toString(),
      reactions: List<String>.from(json['reactions'] ?? []),
      metadata: json['metadata'] != null
          ? MessageMetadata.fromJson(json['metadata'])
          : null,
      fileId: json['fileId'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      mimeType: json['mimeType'] as String?,
      duration: json['duration'] as int?,
      readBy: List<String>.from(json['readBy'] ?? []),
      deliveredTo: List<String>.from(json['deliveredTo'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': {'\$oid': id},
      'temporaryId': temporaryId,
      'conversationId': {'\$oid': conversationId},
      'senderId': senderId,
      'senderMatricule': senderMatricule,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverId': receiverId,
      'content': content,
      'type': _messageTypeToString(type),
      'status': _messageStatusToString(status),
      'priority': _messagePriorityToString(priority),
      'createdAt': {'\$date': createdAt.toIso8601String()},
      'updatedAt':
          updatedAt != null ? {'\$date': updatedAt!.toIso8601String()} : null,
      'deletedAt':
          deletedAt != null ? {'\$date': deletedAt!.toIso8601String()} : null,
      'editedAt':
          editedAt != null ? {'\$date': editedAt!.toIso8601String()} : null,
      'readAt': readAt != null ? {'\$date': readAt!.toIso8601String()} : null,
      'receivedAt':
          receivedAt != null ? {'\$date': receivedAt!.toIso8601String()} : null,
      'isSystemMessage': isSystemMessage,
      'replyTo': replyTo != null ? {'\$oid': replyTo} : null,
      'reactions': reactions,
      'metadata': metadata?.toJson(),
      'fileId': fileId,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'duration': duration,
      'readBy': readBy,
      'deliveredTo': deliveredTo,
    };
  }

  // Parsers
  static MessageType _parseMessageType(String? type) {
    switch (type?.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'FILE':
        return MessageType.file;
      case 'AUDIO':
        return MessageType.audio;
      case 'VIDEO':
        return MessageType.video;
      case 'LOCATION':
        return MessageType.location;
      case 'CONTACT':
        return MessageType.contact;
      case 'SYSTEM':
        return MessageType.system;
      case 'BROADCAST':
        return MessageType.broadcast;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'SENDING':
        return MessageStatus.sending;
      case 'SENT':
        return MessageStatus.sent;
      case 'DELIVERED':
        return MessageStatus.delivered;
      case 'READ':
        return MessageStatus.read;
      case 'FAILED':
        return MessageStatus.failed;
      case 'PENDING':
        return MessageStatus.pending;
      default:
        return MessageStatus.sent;
    }
  }

  static MessagePriority _parseMessagePriority(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'LOW':
        return MessagePriority.low;
      case 'HIGH':
        return MessagePriority.high;
      case 'URGENT':
        return MessagePriority.urgent;
      default:
        return MessagePriority.normal;
    }
  }

  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'IMAGE';
      case MessageType.file:
        return 'FILE';
      case MessageType.audio:
        return 'AUDIO';
      case MessageType.video:
        return 'VIDEO';
      case MessageType.location:
        return 'LOCATION';
      case MessageType.contact:
        return 'CONTACT';
      case MessageType.system:
        return 'SYSTEM';
      case MessageType.broadcast:
        return 'BROADCAST';
      default:
        return 'TEXT';
    }
  }

  static String _messageStatusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'SENDING';
      case MessageStatus.sent:
        return 'SENT';
      case MessageStatus.delivered:
        return 'DELIVERED';
      case MessageStatus.read:
        return 'READ';
      case MessageStatus.failed:
        return 'FAILED';
      case MessageStatus.pending:
        return 'PENDING';
    }
  }

  static String _messagePriorityToString(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.low:
        return 'LOW';
      case MessagePriority.high:
        return 'HIGH';
      case MessagePriority.urgent:
        return 'URGENT';
      default:
        return 'NORMAL';
    }
  }

  /// Factory pour création nouveau message
  factory Message.createNew({
    required String conversationId,
    required String senderId,
    String? receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? fileId,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? duration,
  }) {
    final now = DateTime.now();
    return Message(
      id: '', // Vide pour nouveau message
      temporaryId: 'temp_${now.millisecondsSinceEpoch}_${senderId}',
      conversationId: conversationId,
      senderId: senderId,
      receiverId:
          receiverId ?? '', // TODO: Déterminer correctement selon le contexte
      content: content,
      type: type,
      status: MessageStatus.sending,
      createdAt: now,
      isMe: true,
      fileId: fileId,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      duration: duration,
    );
  }

  /// Copy with method pour immutabilité
  Message copyWith({
    String? id,
    String? temporaryId,
    String? conversationId,
    String? senderId,
    String? senderMatricule,
    String? senderName,
    String? senderAvatar,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    MessagePriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? editedAt,
    DateTime? readAt,
    DateTime? receivedAt,
    bool? isSystemMessage,
    String? replyTo,
    List<String>? reactions,
    MessageMetadata? metadata,
    String? fileId,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? duration,
    List<String>? readBy,
    List<String>? deliveredTo,
    bool? isMe,
  }) {
    return Message(
      id: id ?? this.id,
      temporaryId: temporaryId ?? this.temporaryId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderMatricule: senderMatricule ?? this.senderMatricule,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      editedAt: editedAt ?? this.editedAt,
      readAt: readAt ?? this.readAt,
      receivedAt: receivedAt ?? this.receivedAt,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      metadata: metadata ?? this.metadata,
      fileId: fileId ?? this.fileId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      duration: duration ?? this.duration,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      isMe: isMe ?? this.isMe,
    );
  }

  /// Mettre à jour le statut
  Message withStatus(MessageStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// Marquer comme livré
  Message markAsDelivered(String userId) {
    final newDeliveredTo = List<String>.from(deliveredTo);
    if (!newDeliveredTo.contains(userId)) {
      newDeliveredTo.add(userId);
    }

    return copyWith(
      status: MessageStatus.delivered,
      deliveredTo: newDeliveredTo,
      updatedAt: DateTime.now(),
    );
  }

  /// Marquer comme lu
  Message markAsRead(String userId) {
    final newReadBy = List<String>.from(readBy);
    if (!newReadBy.contains(userId)) {
      newReadBy.add(userId);
    }

    return copyWith(
      status: MessageStatus.read,
      readBy: newReadBy,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods
  static MessageType parseMessageType(String? typeStr) {
    if (typeStr == null) return MessageType.text;

    switch (typeStr.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      case 'system':
        return MessageType.system;
      case 'broadcast':
        return MessageType.broadcast;
      default:
        return MessageType.text;
    }
  }

  /// Convertir le type de message en chaîne de caractères
  static String messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'IMAGE';
      case MessageType.file:
        return 'FILE';
      case MessageType.audio:
        return 'AUDIO';
      case MessageType.video:
        return 'VIDEO';
      case MessageType.location:
        return 'LOCATION';
      case MessageType.contact:
        return 'CONTACT';
      case MessageType.system:
        return 'SYSTEM';
      case MessageType.broadcast:
        return 'BROADCAST';
      default:
        return 'TEXT';
    }
  }

  static MessageStatus parseMessageStatus(String? statusStr) {
    if (statusStr == null) return MessageStatus.sent;

    switch (statusStr.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      case 'pending':
        return MessageStatus.pending;
      default:
        return MessageStatus.sent;
    }
  }

  static String messageStatusToString(MessageStatus status) {
    return status.name.toUpperCase();
  }

  // UI helpers
  String getFormattedTime() {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  bool get hasAttachment => fileId != null || fileUrl != null;
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;
  bool get isAudio => type == MessageType.audio;
  bool get isVideo => type == MessageType.video;
  bool get isDeleted => deletedAt != null;

  @override
  String toString() {
    return 'Message(id: $id, sender: $senderId, content: $content, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && (id.isNotEmpty && other.id == id) ||
        (temporaryId != null &&
            other is Message &&
            other.temporaryId == temporaryId);
  }

  @override
  int get hashCode => id.hashCode ^ temporaryId.hashCode;
}

// Sous-classes pour metadata
@HiveType(typeId: 11)
class MessageMetadata {
  @HiveField(0)
  final TechnicalMetadata? technical;

  @HiveField(1)
  final KafkaMetadata? kafkaMetadata;

  @HiveField(2)
  final RedisMetadata? redisMetadata;

  @HiveField(3)
  final DeliveryMetadata? deliveryMetadata;

  @HiveField(4)
  final ContentMetadata? contentMetadata;

  MessageMetadata({
    this.technical,
    this.kafkaMetadata,
    this.redisMetadata,
    this.deliveryMetadata,
    this.contentMetadata,
  });

  factory MessageMetadata.fromJson(Map<String, dynamic> json) {
    return MessageMetadata(
      technical: json['technical'] != null
          ? TechnicalMetadata.fromJson(json['technical'])
          : null,
      kafkaMetadata: json['kafkaMetadata'] != null
          ? KafkaMetadata.fromJson(json['kafkaMetadata'])
          : null,
      redisMetadata: json['redisMetadata'] != null
          ? RedisMetadata.fromJson(json['redisMetadata'])
          : null,
      deliveryMetadata: json['deliveryMetadata'] != null
          ? DeliveryMetadata.fromJson(json['deliveryMetadata'])
          : null,
      contentMetadata: json['contentMetadata'] != null
          ? ContentMetadata.fromJson(json['contentMetadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'technical': technical?.toJson(),
      'kafkaMetadata': kafkaMetadata?.toJson(),
      'redisMetadata': redisMetadata?.toJson(),
      'deliveryMetadata': deliveryMetadata?.toJson(),
      'contentMetadata': contentMetadata?.toJson(),
    };
  }
}

/// Modèle pour la réponse "message_sent" de Socket.IO
class MessageSentResponse {
  final String messageId;
  final String temporaryId;
  final String status;
  final DateTime timestamp;

  MessageSentResponse({
    required this.messageId,
    required this.temporaryId,
    required this.status,
    required this.timestamp,
  });

  factory MessageSentResponse.fromJson(Map<String, dynamic> json) {
    return MessageSentResponse(
      messageId: json['messageId'] as String,
      temporaryId: json['temporaryId'] as String,
      status: json['status'] as String,
      timestamp: _extractDate(json['timestamp']),
    );
  }
}

/// Modèle pour la réponse d'erreur de message
class MessageErrorResponse {
  final String message;
  final String code;
  final String? error;

  MessageErrorResponse({
    required this.message,
    required this.code,
    this.error,
  });

  factory MessageErrorResponse.fromJson(Map<String, dynamic> json) {
    return MessageErrorResponse(
      message: json['message'] as String,
      code: json['code'] as String,
      error: json['error'] as String?,
    );
  }
}

/// Modèle pour la réponse "messagesLoaded"
class MessagesLoadedResponse {
  final List<Message> messages;
  final Map<String, dynamic> pagination;
  final bool fromCache;
  final double processingTime;

  MessagesLoadedResponse({
    required this.messages,
    required this.pagination,
    required this.fromCache,
    required this.processingTime,
  });

  factory MessagesLoadedResponse.fromJson(Map<String, dynamic> json) {
    // Construire pagination à partir des clés racines
    final pagination = <String, dynamic>{
      'nextCursor': json['nextCursor'],
      'hasMore': json['hasMore'] ?? false,
      'totalCount': json['totalCount'] ?? 0,
    };

    return MessagesLoadedResponse(
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((msg) => Message.fromJson(msg as Map<String, dynamic>))
          .toList(),
      pagination: pagination,
      fromCache: json['fromCache'] as bool? ?? false,
      processingTime: (json['processingTime'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@HiveField(1)
@HiveType(typeId: 12)
class TechnicalMetadata {
  @HiveField(0)
  final String? serverId;

  @HiveField(1)
  final String? platform;

  @HiveField(2)
  final String? version;

  @HiveField(3)
  final String? environment;

  @HiveField(4)
  final int? processingTime;

  @HiveField(5)
  final List<String>? tags;

  TechnicalMetadata({
    this.serverId,
    this.platform,
    this.version,
    this.environment,
    this.processingTime,
    this.tags,
  });

  factory TechnicalMetadata.fromJson(Map<String, dynamic> json) {
    final technical = json['technical'] as Map<String, dynamic>? ?? {};
    return TechnicalMetadata(
      serverId: technical['serverId'] as String?,
      platform: technical['platform'] as String?,
      version: technical['version'] as String?,
      environment: technical['environment'] as String?,
      processingTime: technical['processingTime'] as int?,
      tags: List<String>.from(technical['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverId': serverId,
      'platform': platform,
      'version': version,
      'environment': environment,
      'processingTime': processingTime,
      'tags': tags,
    };
  }
}

@HiveType(typeId: 13)
class KafkaMetadata {
  @HiveField(0)
  final String? topic;

  @HiveField(1)
  final List<dynamic>? events;

  KafkaMetadata({
    this.topic,
    this.events,
  });

  factory KafkaMetadata.fromJson(Map<String, dynamic> json) {
    final kafka = json['kafkaMetadata'] as Map<String, dynamic>? ?? {};
    return KafkaMetadata(
      topic: kafka['topic'] as String?,
      events: kafka['events'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'events': events,
    };
  }
}

@HiveType(typeId: 14)
class RedisMetadata {
  @HiveField(0)
  final int? ttl;

  @HiveField(1)
  final String? cacheStrategy;

  @HiveField(2)
  final int? cacheHits;

  RedisMetadata({
    this.ttl,
    this.cacheStrategy,
    this.cacheHits,
  });

  factory RedisMetadata.fromJson(Map<String, dynamic> json) {
    final redis = json['redisMetadata'] as Map<String, dynamic>? ?? {};
    return RedisMetadata(
      ttl: redis['ttl'] as int?,
      cacheStrategy: redis['cacheStrategy'] as String?,
      cacheHits: redis['cacheHits'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ttl': ttl,
      'cacheStrategy': cacheStrategy,
      'cacheHits': cacheHits,
    };
  }
}

@HiveType(typeId: 15)
class DeliveryMetadata {
  @HiveField(0)
  final int? attempts;

  @HiveField(1)
  final int? retryCount;

  @HiveField(2)
  final DateTime? deliveredAt;

  @HiveField(3)
  final DateTime? readAt;

  DeliveryMetadata({
    this.attempts,
    this.retryCount,
    this.deliveredAt,
    this.readAt,
  });

  factory DeliveryMetadata.fromJson(Map<String, dynamic> json) {
    final delivery = json['deliveryMetadata'] as Map<String, dynamic>? ?? {};
    return DeliveryMetadata(
      attempts: delivery['attempts'] as int?,
      retryCount: delivery['retryCount'] as int?,
      deliveredAt: delivery['deliveredAt'] != null
          ? _extractDate(delivery['deliveredAt'])
          : null,
      readAt:
          delivery['readAt'] != null ? _extractDate(delivery['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attempts': attempts,
      'retryCount': retryCount,
      'deliveredAt': deliveredAt != null
          ? {'\$date': deliveredAt!.toIso8601String()}
          : null,
      'readAt': readAt != null ? {'\$date': readAt!.toIso8601String()} : null,
    };
  }
}

@HiveType(typeId: 16)
class ContentMetadata {
  @HiveField(0)
  final List<String>? mentions;

  @HiveField(1)
  final List<String>? hashtags;

  @HiveField(2)
  final List<String>? urls;

  @HiveField(3)
  final dynamic file;

  ContentMetadata({
    this.mentions,
    this.hashtags,
    this.urls,
    this.file,
  });

  factory ContentMetadata.fromJson(Map<String, dynamic> json) {
    final content = json['contentMetadata'] as Map<String, dynamic>? ?? {};
    return ContentMetadata(
      mentions: List<String>.from(content['mentions'] ?? []),
      hashtags: List<String>.from(content['hashtags'] ?? []),
      urls: List<String>.from(content['urls'] ?? []),
      file: content['file'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mentions': mentions,
      'hashtags': hashtags,
      'urls': urls,
      'file': file,
    };
  }
}
