import 'package:hive/hive.dart';

part 'moveset_model.g.dart';

@HiveType(typeId: 5)
class MoveSet {
  @HiveField(0)
  final String matchId;

  @HiveField(1)
  final List<MoveItem> moves;

  MoveSet({required this.matchId, required this.moves});

  factory MoveSet.fromJson(Map<String, dynamic> json) {
    return MoveSet(
        matchId: json['matchId'] as String,
        moves: (json['moves'] as List)
            .map((move) => MoveItem.fromJson(move as Map<String, dynamic>))
            .toList());
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'moves': moves.map((move) => move.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 4)
class MoveItem {
  @HiveField(0)
  final String move;

  @HiveField(1)
  final String fen;

  MoveItem({required this.move, required this.fen});

  factory MoveItem.fromJson(Map<String, dynamic> json) {
    return MoveItem(move: json['move'] as String, fen: json['fen'] as String);
  }

  Map<String, dynamic> toJson() {
    return {
      'move': move,
      'fen': fen,
    };
  }
}
