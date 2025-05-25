// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_feature_new.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 0;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      id: fields[0] as String,
      isSentByUser: fields[2] as bool,
      timestamp: fields[3] as DateTime,
      text: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.isSentByUser)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatHistoryItemAdapter extends TypeAdapter<ChatHistoryItem> {
  @override
  final int typeId = 1;

  @override
  ChatHistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatHistoryItem(
      id: fields[0] as String,
      contactName: fields[1] as String,
      lastMessage: fields[2] as String,
      lastMessageTime: fields[3] as DateTime,
      messages: (fields[4] as List).cast<ChatMessage>(),
      aiFlow: fields[5] as AiFlow,
      sessionId: fields[6] as String,
      isThinkingModeExplicitlyEnabled: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChatHistoryItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.contactName)
      ..writeByte(2)
      ..write(obj.lastMessage)
      ..writeByte(3)
      ..write(obj.lastMessageTime)
      ..writeByte(4)
      ..write(obj.messages)
      ..writeByte(5)
      ..write(obj.aiFlow)
      ..writeByte(6)
      ..write(obj.sessionId)
      ..writeByte(7)
      ..write(obj.isThinkingModeExplicitlyEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatHistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 2;

  @override
  MessageType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageType.text;
      case 1:
        return MessageType.loading;
      default:
        return MessageType.text;
    }
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    switch (obj) {
      case MessageType.text:
        writer.writeByte(0);
        break;
      case MessageType.loading:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AiFlowAdapter extends TypeAdapter<AiFlow> {
  @override
  final int typeId = 3;

  @override
  AiFlow read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AiFlow.none;
      case 1:
        return AiFlow.defaultChat;
      case 2:
        return AiFlow.gemma3_27b_it;
      case 3:
        return AiFlow.qwen3_235b_a22b;
      default:
        return AiFlow.none;
    }
  }

  @override
  void write(BinaryWriter writer, AiFlow obj) {
    switch (obj) {
      case AiFlow.none:
        writer.writeByte(0);
        break;
      case AiFlow.defaultChat:
        writer.writeByte(1);
        break;
      case AiFlow.gemma3_27b_it:
        writer.writeByte(2);
        break;
      case AiFlow.qwen3_235b_a22b:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFlowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
