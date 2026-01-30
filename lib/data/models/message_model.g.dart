// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 10;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String,
      temporaryId: fields[1] as String?,
      conversationId: fields[2] as String,
      senderId: fields[3] as String,
      senderMatricule: fields[4] as String?,
      senderName: fields[5] as String?,
      senderAvatar: fields[6] as String?,
      receiverId: fields[7] as String,
      content: fields[8] as String,
      type: fields[9] as MessageType,
      status: fields[10] as MessageStatus,
      priority: fields[11] as MessagePriority,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime?,
      deletedAt: fields[14] as DateTime?,
      editedAt: fields[15] as DateTime?,
      readAt: fields[16] as DateTime?,
      receivedAt: fields[17] as DateTime?,
      isSystemMessage: fields[18] as bool,
      replyTo: fields[19] as String?,
      reactions: (fields[20] as List).cast<String>(),
      metadata: fields[21] as MessageMetadata?,
      fileId: fields[22] as String?,
      fileUrl: fields[23] as String?,
      fileName: fields[24] as String?,
      fileSize: fields[25] as int?,
      mimeType: fields[26] as String?,
      duration: fields[27] as int?,
      readBy: (fields[28] as List).cast<String>(),
      deliveredTo: (fields[29] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(30)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.temporaryId)
      ..writeByte(2)
      ..write(obj.conversationId)
      ..writeByte(3)
      ..write(obj.senderId)
      ..writeByte(4)
      ..write(obj.senderMatricule)
      ..writeByte(5)
      ..write(obj.senderName)
      ..writeByte(6)
      ..write(obj.senderAvatar)
      ..writeByte(7)
      ..write(obj.receiverId)
      ..writeByte(8)
      ..write(obj.content)
      ..writeByte(9)
      ..write(obj.type)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.priority)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.deletedAt)
      ..writeByte(15)
      ..write(obj.editedAt)
      ..writeByte(16)
      ..write(obj.readAt)
      ..writeByte(17)
      ..write(obj.receivedAt)
      ..writeByte(18)
      ..write(obj.isSystemMessage)
      ..writeByte(19)
      ..write(obj.replyTo)
      ..writeByte(20)
      ..write(obj.reactions)
      ..writeByte(21)
      ..write(obj.metadata)
      ..writeByte(22)
      ..write(obj.fileId)
      ..writeByte(23)
      ..write(obj.fileUrl)
      ..writeByte(24)
      ..write(obj.fileName)
      ..writeByte(25)
      ..write(obj.fileSize)
      ..writeByte(26)
      ..write(obj.mimeType)
      ..writeByte(27)
      ..write(obj.duration)
      ..writeByte(28)
      ..write(obj.readBy)
      ..writeByte(29)
      ..write(obj.deliveredTo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageMetadataAdapter extends TypeAdapter<MessageMetadata> {
  @override
  final int typeId = 11;

  @override
  MessageMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageMetadata(
      technical: fields[0] as TechnicalMetadata?,
      kafkaMetadata: fields[1] as KafkaMetadata?,
      redisMetadata: fields[2] as RedisMetadata?,
      deliveryMetadata: fields[3] as DeliveryMetadata?,
      contentMetadata: fields[4] as ContentMetadata?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageMetadata obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.technical)
      ..writeByte(1)
      ..write(obj.kafkaMetadata)
      ..writeByte(2)
      ..write(obj.redisMetadata)
      ..writeByte(3)
      ..write(obj.deliveryMetadata)
      ..writeByte(4)
      ..write(obj.contentMetadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TechnicalMetadataAdapter extends TypeAdapter<TechnicalMetadata> {
  @override
  final int typeId = 12;

  @override
  TechnicalMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TechnicalMetadata(
      serverId: fields[0] as String?,
      platform: fields[1] as String?,
      version: fields[2] as String?,
      environment: fields[3] as String?,
      processingTime: fields[4] as int?,
      tags: (fields[5] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TechnicalMetadata obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.serverId)
      ..writeByte(1)
      ..write(obj.platform)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.environment)
      ..writeByte(4)
      ..write(obj.processingTime)
      ..writeByte(5)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechnicalMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class KafkaMetadataAdapter extends TypeAdapter<KafkaMetadata> {
  @override
  final int typeId = 13;

  @override
  KafkaMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KafkaMetadata(
      topic: fields[0] as String?,
      events: (fields[1] as List?)?.cast<dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, KafkaMetadata obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.topic)
      ..writeByte(1)
      ..write(obj.events);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KafkaMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RedisMetadataAdapter extends TypeAdapter<RedisMetadata> {
  @override
  final int typeId = 14;

  @override
  RedisMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RedisMetadata(
      ttl: fields[0] as int?,
      cacheStrategy: fields[1] as String?,
      cacheHits: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RedisMetadata obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.ttl)
      ..writeByte(1)
      ..write(obj.cacheStrategy)
      ..writeByte(2)
      ..write(obj.cacheHits);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RedisMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeliveryMetadataAdapter extends TypeAdapter<DeliveryMetadata> {
  @override
  final int typeId = 15;

  @override
  DeliveryMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryMetadata(
      attempts: fields[0] as int?,
      retryCount: fields[1] as int?,
      deliveredAt: fields[2] as DateTime?,
      readAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryMetadata obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.attempts)
      ..writeByte(1)
      ..write(obj.retryCount)
      ..writeByte(2)
      ..write(obj.deliveredAt)
      ..writeByte(3)
      ..write(obj.readAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentMetadataAdapter extends TypeAdapter<ContentMetadata> {
  @override
  final int typeId = 16;

  @override
  ContentMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContentMetadata(
      mentions: (fields[0] as List?)?.cast<String>(),
      hashtags: (fields[1] as List?)?.cast<String>(),
      urls: (fields[2] as List?)?.cast<String>(),
      file: fields[3] as dynamic,
    );
  }

  @override
  void write(BinaryWriter writer, ContentMetadata obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.mentions)
      ..writeByte(1)
      ..write(obj.hashtags)
      ..writeByte(2)
      ..write(obj.urls)
      ..writeByte(3)
      ..write(obj.file);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
