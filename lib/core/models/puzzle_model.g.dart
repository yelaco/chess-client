// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puzzle_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PuzzleProfileAdapter extends TypeAdapter<PuzzleProfile> {
  @override
  final int typeId = 1;

  @override
  PuzzleProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PuzzleProfile(
      userId: fields[0] as String,
      rating: fields[1] as int,
      dailyPuzzleCount: fields[2] as int,
      lastPlayDate: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PuzzleProfile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.rating)
      ..writeByte(2)
      ..write(obj.dailyPuzzleCount)
      ..writeByte(3)
      ..write(obj.lastPlayDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuzzleProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PuzzleAdapter extends TypeAdapter<Puzzle> {
  @override
  final int typeId = 0;

  @override
  Puzzle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Puzzle(
      puzzleId: fields[0] as String,
      fen: fields[1] as String,
      moves: (fields[2] as List).cast<String>(),
      rating: fields[3] as int,
      ratingDeviation: fields[4] as int,
      popularity: fields[5] as int,
      nbPlays: fields[6] as int,
      themes: (fields[7] as List).cast<String>(),
      gameUrl: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Puzzle obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.puzzleId)
      ..writeByte(1)
      ..write(obj.fen)
      ..writeByte(2)
      ..write(obj.moves)
      ..writeByte(3)
      ..write(obj.rating)
      ..writeByte(4)
      ..write(obj.ratingDeviation)
      ..writeByte(5)
      ..write(obj.popularity)
      ..writeByte(6)
      ..write(obj.nbPlays)
      ..writeByte(7)
      ..write(obj.themes)
      ..writeByte(8)
      ..write(obj.gameUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuzzleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
