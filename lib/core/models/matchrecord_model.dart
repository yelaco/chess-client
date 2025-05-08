class MatchRecordModel {
  final String matchId;
  final List<Player> players;
  final String pgn;
  final List<String> moves;
  final DateTime startedAt;
  final DateTime endedAt;

  MatchRecordModel({
    required this.matchId,
    required this.players,
    required this.pgn,
    required this.moves,
    required this.startedAt,
    required this.endedAt,
  });

  factory MatchRecordModel.fromJson(Map<String, dynamic> json) {
    // Parse PGN to get moves
    List<String> parsedMoves = [];
    final String pgnString = json['pgn'] as String;

    // Tách PGN thành các nước đi
    // Tìm tất cả các kí tự e2e4, f7f5, g1g3 là các nước đi
    final RegExp moveRegex = RegExp(r'([a-h][1-8][a-h][1-8])');
    final matches = moveRegex.allMatches(pgnString);

    for (final match in matches) {
      if (match.group(1) != null) {
        parsedMoves.add(match.group(1)!);
      }
    }

    return MatchRecordModel(
      matchId: json['matchId'] as String,
      players: (json['players'] as List)
          .map((player) => Player.fromJson(player as Map<String, dynamic>))
          .toList(),
      pgn: json['pgn'] as String,
      moves: parsedMoves,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'players': players.map((player) => player.toJson()).toList(),
      'pgn': pgn,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
    };
  }
}

class Player {
  final String id;
  final int oldRating;
  final int newRating;

  Player({
    required this.id,
    required this.oldRating,
    required this.newRating,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      oldRating: json['oldRating'] as int,
      newRating: json['newRating'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oldRating': oldRating,
      'newRating': newRating,
    };
  }
}

// Hàm main để test
// void main() {
//   final hehe = {
//     "matchId": "a2c203c2-0886-4f58-98be-c6849b10d4ac",
//     "players": [
//       {
//         "id": "091ef4a8-b0b1-7088-f6b2-2596f366e959",
//         "oldRating": 1200,
//         "newRating": 1200
//       },
//       {
//         "id": "698e84c8-3081-7079-1f59-03a523fec9e0",
//         "oldRating": 1200,
//         "newRating": 1200
//       }
//     ],
//     "pgn": "\n1. e2e4 f7f5 2. g1g3 *",
//     "startedAt": "2025-04-10T19:07:37.660617591Z",
//     "endedAt": "2025-04-10T19:10:02.435497112Z"
//   };

//   final model = MatchRecordModel.fromJson(hehe);
//   print('Match ID: ${model.matchId}');
//   print('Players: ${model.players.length}');
//   print('PGN original: "${model.pgn}"');
//   print('Parsed Moves: ${model.moves}');
//   print('Số nước đã được parse: ${model.moves.length}');
//   print('Started At: ${model.startedAt}');
//   print('Ended At: ${model.endedAt}');
// }
