import 'player.dart';

class MatchModel {
  final String matchId;
  final String conversationId;
  final Player player1;
  final Player player2;
  final String gameMode;
  final String server;
  final DateTime createdAt;

  MatchModel({
    required this.matchId,
    required this.conversationId,
    required this.player1,
    required this.player2,
    required this.gameMode,
    required this.server,
    required this.createdAt,
  });

  static Future<MatchModel> fromJson(Map<String, dynamic> json) async {
    final player1 = await Player.fromJson(json['player1']);
    final player2 = await Player.fromJson(json['player2']);

    return MatchModel(
      matchId: json['matchId'],
      conversationId: json['conversationId'],
      player1: player1,
      player2: player2,
      gameMode: json['gameMode'],
      server: json['server'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'player1': player1.toJson(),
      'player2': player2.toJson(),
      'gameMode': gameMode,
      'server': server,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
