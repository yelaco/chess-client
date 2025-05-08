// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moveset_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoveSetAdapter extends TypeAdapter<MoveSet> {
  @override
  final int typeId = 5;

  @override
  MoveSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoveSet(
      matchId: fields[0] as String,
      moves: (fields[1] as List).cast<MoveItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, MoveSet obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.matchId)
      ..writeByte(1)
      ..write(obj.moves);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoveItemAdapter extends TypeAdapter<MoveItem> {
  @override
  final int typeId = 4;

  @override
  MoveItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoveItem(
      move: fields[0] as String,
      fen: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MoveItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.move)
      ..writeByte(1)
      ..write(obj.fen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
