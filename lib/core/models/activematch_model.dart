class MatchPlayer {
  final String id;
  final String username;
  final double rating;

  MatchPlayer({
    required this.id,
    required this.username,
    required this.rating,
  });

  factory MatchPlayer.fromJson(Map<String, dynamic> json) {
    return MatchPlayer(
      id: json['id'] as String,
      username: json['username'] as String,
      rating: (json['rating'] is double)
          ? json['rating']
          : double.tryParse(json['rating'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'rating': rating,
    };
  }
}

class ActiveMatch {
  final String matchId;
  final MatchPlayer player1;
  final MatchPlayer player2;
  final String gameMode;
  final DateTime? startedAt;
  final DateTime createdAt;

  ActiveMatch({
    required this.matchId,
    required this.player1,
    required this.player2,
    required this.gameMode,
    this.startedAt,
    required this.createdAt,
  });

  factory ActiveMatch.fromJson(Map<String, dynamic> json) {
    return ActiveMatch(
      matchId: json['matchId'] as String,
      player1: MatchPlayer.fromJson(json['player1'] as Map<String, dynamic>),
      player2: MatchPlayer.fromJson(json['player2'] as Map<String, dynamic>),
      gameMode: json['gameMode'] as String,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'player1': player1.toJson(),
      'player2': player2.toJson(),
      'gameMode': gameMode,
      'startedAt': startedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ActiveResponse {
  final List<ActiveMatch> items;
  final String? nextPageToken;

  ActiveResponse({
    required this.items,
    this.nextPageToken,
  });

  factory ActiveResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] ?? [];

    return ActiveResponse(
      items: itemsJson.map((item) => ActiveMatch.fromJson(item)).toList(),
      nextPageToken: json['nextPageToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'nextPageToken': nextPageToken,
    };
  }
}
