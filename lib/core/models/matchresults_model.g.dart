// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchresults_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchResultsModelAdapter extends TypeAdapter<MatchResultsModel> {
  @override
  final int typeId = 8;

  @override
  MatchResultsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchResultsModel(
      items: (fields[0] as List).cast<MatchResultItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, MatchResultsModel obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchResultsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MatchResultItemAdapter extends TypeAdapter<MatchResultItem> {
  @override
  final int typeId = 7;

  @override
  MatchResultItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchResultItem(
      userId: fields[0] as String,
      matchId: fields[1] as String,
      opponentId: fields[2] as String,
      opponentRating: fields[3] as double,
      result: fields[4] as double,
      timestamp: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MatchResultItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.matchId)
      ..writeByte(2)
      ..write(obj.opponentId)
      ..writeByte(3)
      ..write(obj.opponentRating)
      ..writeByte(4)
      ..write(obj.result)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchResultItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
