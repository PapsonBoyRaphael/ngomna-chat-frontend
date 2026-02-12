// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 1;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chat(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as ChatType,
      description: fields[3] as String?,
      participants: (fields[4] as List).cast<String>(),
      createdBy: fields[5] as String,
      isActive: fields[6] as bool,
      isArchived: fields[7] as bool,
      userMetadata: (fields[8] as List).cast<ParticipantMetadata>(),
      unreadCounts: (fields[9] as Map).cast<String, int>(),
      lastMessage: fields[10] as LastMessage?,
      lastMessageAt: fields[11] as DateTime,
      settings: fields[12] as ChatSettings,
      metadata: fields[13] as ChatMetadata,
      integrations: fields[14] as ChatIntegrations,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.participants)
      ..writeByte(5)
      ..write(obj.createdBy)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.isArchived)
      ..writeByte(8)
      ..write(obj.userMetadata)
      ..writeByte(9)
      ..write(obj.unreadCounts)
      ..writeByte(10)
      ..write(obj.lastMessage)
      ..writeByte(11)
      ..write(obj.lastMessageAt)
      ..writeByte(12)
      ..write(obj.settings)
      ..writeByte(13)
      ..write(obj.metadata)
      ..writeByte(14)
      ..write(obj.integrations)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ParticipantMetadataAdapter extends TypeAdapter<ParticipantMetadata> {
  @override
  final int typeId = 2;

  @override
  ParticipantMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ParticipantMetadata(
      userId: fields[0] as String,
      unreadCount: fields[1] as int,
      lastReadAt: fields[2] as DateTime?,
      isMuted: fields[3] as bool,
      isPinned: fields[4] as bool,
      customName: fields[5] as String?,
      notificationSettings: fields[6] as NotificationSettings,
      nom: fields[7] as String,
      prenom: fields[8] as String,
      avatar: fields[9] as String?,
      metadataId: fields[10] as String,
      sexe: fields[11] as String?,
      departement: fields[12] as String?,
      ministere: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ParticipantMetadata obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.unreadCount)
      ..writeByte(2)
      ..write(obj.lastReadAt)
      ..writeByte(3)
      ..write(obj.isMuted)
      ..writeByte(4)
      ..write(obj.isPinned)
      ..writeByte(5)
      ..write(obj.customName)
      ..writeByte(6)
      ..write(obj.notificationSettings)
      ..writeByte(7)
      ..write(obj.nom)
      ..writeByte(8)
      ..write(obj.prenom)
      ..writeByte(9)
      ..write(obj.avatar)
      ..writeByte(10)
      ..write(obj.metadataId)
      ..writeByte(11)
      ..write(obj.sexe)
      ..writeByte(12)
      ..write(obj.departement)
      ..writeByte(13)
      ..write(obj.ministere);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationSettingsAdapter extends TypeAdapter<NotificationSettings> {
  @override
  final int typeId = 3;

  @override
  NotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettings(
      enabled: fields[0] as bool,
      sound: fields[1] as bool,
      vibration: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.sound)
      ..writeByte(2)
      ..write(obj.vibration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LastMessageAdapter extends TypeAdapter<LastMessage> {
  @override
  final int typeId = 4;

  @override
  LastMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LastMessage(
      content: fields[0] as String,
      type: fields[1] as String,
      senderId: fields[2] as String,
      senderName: fields[3] as String?,
      timestamp: fields[4] as DateTime,
      status: fields[5] as MessageStatus,
      id: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LastMessage obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.senderName)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatSettingsAdapter extends TypeAdapter<ChatSettings> {
  @override
  final int typeId = 5;

  @override
  ChatSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSettings(
      allowInvites: fields[0] as bool,
      isPublic: fields[1] as bool,
      maxParticipants: fields[2] as int,
      messageRetention: fields[3] as int,
      autoDeleteAfter: fields[4] as int,
      broadcastAdmins: (fields[5] as List).cast<String>(),
      broadcastRecipients: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.allowInvites)
      ..writeByte(1)
      ..write(obj.isPublic)
      ..writeByte(2)
      ..write(obj.maxParticipants)
      ..writeByte(3)
      ..write(obj.messageRetention)
      ..writeByte(4)
      ..write(obj.autoDeleteAfter)
      ..writeByte(5)
      ..write(obj.broadcastAdmins)
      ..writeByte(6)
      ..write(obj.broadcastRecipients);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMetadataAdapter extends TypeAdapter<ChatMetadata> {
  @override
  final int typeId = 6;

  @override
  ChatMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMetadata(
      autoCreated: fields[0] as bool,
      createdFrom: fields[1] as String,
      version: fields[2] as int,
      tags: (fields[3] as List).cast<String>(),
      auditLog: (fields[4] as List).cast<AuditLogEntry>(),
      stats: fields[5] as ChatStats,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMetadata obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.autoCreated)
      ..writeByte(1)
      ..write(obj.createdFrom)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.auditLog)
      ..writeByte(5)
      ..write(obj.stats);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuditLogEntryAdapter extends TypeAdapter<AuditLogEntry> {
  @override
  final int typeId = 7;

  @override
  AuditLogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditLogEntry(
      action: fields[0] as String,
      userId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      details: (fields[3] as Map).cast<String, dynamic>(),
      metadata: (fields[4] as Map).cast<String, dynamic>(),
      logId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuditLogEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.action)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.details)
      ..writeByte(4)
      ..write(obj.metadata)
      ..writeByte(5)
      ..write(obj.logId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatStatsAdapter extends TypeAdapter<ChatStats> {
  @override
  final int typeId = 8;

  @override
  ChatStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatStats(
      totalMessages: fields[0] as int,
      totalFiles: fields[1] as int,
      totalParticipants: fields[2] as int,
      lastActivity: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatStats obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.totalMessages)
      ..writeByte(1)
      ..write(obj.totalFiles)
      ..writeByte(2)
      ..write(obj.totalParticipants)
      ..writeByte(3)
      ..write(obj.lastActivity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatIntegrationsAdapter extends TypeAdapter<ChatIntegrations> {
  @override
  final int typeId = 9;

  @override
  ChatIntegrations read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatIntegrations(
      webhooks: (fields[0] as List).cast<dynamic>(),
      bots: (fields[1] as List).cast<dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatIntegrations obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.webhooks)
      ..writeByte(1)
      ..write(obj.bots);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatIntegrationsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
