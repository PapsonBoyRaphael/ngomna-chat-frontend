import 'dart:convert';

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

class Message {
  final String id; // MongoDB _id
  final String? temporaryId; // ID temporaire client pour mapping
  final String conversationId; // ID conversation/groupe
  final String senderId; // ID expéditeur
  final String? senderMatricule; // Matricule expéditeur
  final String? senderName; // Nom expéditeur (enrichi)
  final String? senderAvatar; // Avatar expéditeur
  final String content; // Contenu texte
  final MessageType type; // Type de message
  final MessageStatus status; // Statut de livraison
  final DateTime timestamp; // Date création
  final DateTime? updatedAt; // Date modification
  final bool isDeleted; // Supprimé (soft delete)

  // Fichiers attachés
  final String? fileId; // ID fichier dans chat-file-service
  final String? fileUrl; // URL de téléchargement
  final String? fileName; // Nom original fichier
  final int? fileSize; // Taille en bytes
  final String? mimeType; // Type MIME

  // Audio/Video spécifiques
  final int? duration; // Durée en secondes (audio/video)

  // Métadonnées
  final Map<String, dynamic>? metadata; // Données supplémentaires
  final List<String>? readBy; // IDs utilisateurs qui ont lu
  final List<String>? deliveredTo; // IDs utilisateurs qui ont reçu

  // Pour UI seulement
  final bool isMe; // Message de l'utilisateur courant

  Message({
    required this.id,
    this.temporaryId,
    required this.conversationId,
    required this.senderId,
    this.senderMatricule,
    this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.updatedAt,
    this.isDeleted = false,
    this.fileId,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.duration,
    this.metadata,
    this.readBy,
    this.deliveredTo,
    this.isMe = false,
  });

  /// Factory depuis JSON backend (Socket.IO events)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      temporaryId: json['temporaryId'] as String?,
      conversationId:
          json['conversationId'] as String? ?? json['chatId'] as String? ?? '',
      senderId:
          json['senderId'] as String? ?? json['sender_id'] as String? ?? '',
      senderMatricule: json['senderMatricule'] as String?,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String? ?? json['text'] as String? ?? '',
      type: parseMessageType(json['type'] as String?),
      status: parseMessageStatus(json['status'] as String?),
      timestamp: DateTime.parse(json['timestamp'] as String? ??
          json['createdAt'] as String? ??
          DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      fileId: json['fileId'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      mimeType: json['mimeType'] as String?,
      duration: json['duration'] as int?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      readBy: json['readBy'] != null ? List<String>.from(json['readBy']) : null,
      deliveredTo: json['deliveredTo'] != null
          ? List<String>.from(json['deliveredTo'])
          : null,
      isMe: json['isMe'] as bool? ?? false,
    );
  }

  /// Factory pour création nouveau message
  factory Message.createNew({
    required String conversationId,
    required String senderId,
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
      content: content,
      type: type,
      status: MessageStatus.sending,
      timestamp: now,
      isMe: true,
      fileId: fileId,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      duration: duration,
    );
  }

  /// Convertir en JSON pour Socket.IO emit
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (temporaryId != null) 'temporaryId': temporaryId,
      'conversationId': conversationId,
      'senderId': senderId,
      if (senderMatricule != null) 'senderMatricule': senderMatricule,
      'content': content,
      'type': messageTypeToString(type),
      'status': messageStatusToString(status),
      'timestamp': timestamp.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (fileId != null) 'fileId': fileId,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (mimeType != null) 'mimeType': mimeType,
      if (duration != null) 'duration': duration,
      if (metadata != null) 'metadata': metadata,
      if (readBy != null) 'readBy': readBy,
      if (deliveredTo != null) 'deliveredTo': deliveredTo,
    };
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
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? updatedAt,
    bool? isDeleted,
    String? fileId,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? duration,
    Map<String, dynamic>? metadata,
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
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      fileId: fileId ?? this.fileId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
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
    final newDeliveredTo = List<String>.from(deliveredTo ?? []);
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
    final newReadBy = List<String>.from(readBy ?? []);
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
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
    }
  }

  bool get hasAttachment => fileId != null || fileUrl != null;
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;
  bool get isAudio => type == MessageType.audio;
  bool get isVideo => type == MessageType.video;

  @override
  String toString() {
    return 'Message(id: $id, sender: $senderId, content: $content, status: $status, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && (id.isNotEmpty && other.id == id) ||
        (temporaryId != null && other is Message && other.temporaryId == temporaryId);
  }

  @override
  int get hashCode => id.hashCode ^ temporaryId.hashCode;
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
      timestamp: DateTime.parse(json['timestamp'] as String),
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
    return MessagesLoadedResponse(
      messages: (json['messages'] as List<dynamic>)
          .map((msg) => Message.fromJson(msg))
          .toList(),
      pagination: Map<String, dynamic>.from(json['pagination']),
      fromCache: json['fromCache'] as bool? ?? false,
      processingTime: (json['processingTime'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
