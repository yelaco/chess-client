import 'package:hive/hive.dart';
import 'user.dart';

part 'puzzle_model.g.dart';

@HiveType(typeId: 1)
class PuzzleProfile {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final int rating;

  @HiveField(2)
  int dailyPuzzleCount;

  @HiveField(3)
  DateTime lastPlayDate;

  PuzzleProfile({
    required this.userId,
    required this.rating,
    this.dailyPuzzleCount = 0,
    DateTime? lastPlayDate,
  }) : lastPlayDate = lastPlayDate ?? DateTime.now();

  factory PuzzleProfile.fromJson(Map<String, dynamic> json) {
    return PuzzleProfile(
      userId: json['userId'] ?? '',
      rating: json['rating'] ?? 300,
      dailyPuzzleCount: json['dailyPuzzleCount'] ?? 0,
      lastPlayDate:
          DateTime.tryParse(json['lastPlayDate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rating': rating,
      'dailyPuzzleCount': dailyPuzzleCount,
      'lastPlayDate': lastPlayDate.toIso8601String(),
    };
  }

  void resetDailyCount() {
    final now = DateTime.now();
    if (lastPlayDate.year != now.year ||
        lastPlayDate.month != now.month ||
        lastPlayDate.day != now.day) {
      dailyPuzzleCount = 0;
      lastPlayDate = now;
    }
  }

  int getRemainingPuzzles(UserModel user) {
    resetDailyCount();
    if (user.membership == Membership.premium ||
        user.membership == Membership.pro) {
      return -1; // -1 nghĩa là không giới hạn
    }
    return 3 - dailyPuzzleCount;
  }

  bool canPlayPuzzle(UserModel user) {
    resetDailyCount();
    if (user.membership == Membership.premium ||
        user.membership == Membership.pro) {
      return true;
    }
    return dailyPuzzleCount < 3;
  }

  void incrementDailyCount() {
    resetDailyCount();
    dailyPuzzleCount++;
  }
}

class Puzzles {
  final List<Puzzle> puzzles;

  Puzzles({
    required this.puzzles,
  });

  factory Puzzles.fromJson(Map<String, dynamic> json) {
    return Puzzles(
      puzzles: List<Puzzle>.from(
          json['items'].map((puzzle) => Puzzle.fromJson(puzzle))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': puzzles.map((puzzle) => puzzle.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 0)
class Puzzle extends HiveObject {
  @HiveField(0)
  final String puzzleId;

  @HiveField(1)
  final String fen;

  @HiveField(2)
  final List<String> moves;

  @HiveField(3)
  final int rating;

  @HiveField(4)
  final int ratingDeviation;

  @HiveField(5)
  final int popularity;

  @HiveField(6)
  final int nbPlays;

  @HiveField(7)
  final List<String> themes;

  @HiveField(8)
  final String gameUrl;

  Puzzle({
    required this.puzzleId,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.ratingDeviation,
    required this.popularity,
    required this.nbPlays,
    required this.themes,
    required this.gameUrl,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      puzzleId: json['puzzleid'],
      fen: json['fen'],
      moves: json['moves'].split(' '),
      rating: json['rating'],
      ratingDeviation: json['ratingdeviation'],
      popularity: json['popularity'],
      nbPlays: json['nbplays'],
      themes: json['themes'].split(' '),
      gameUrl: json['gameurl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puzzleid': puzzleId,
      'fen': fen,
      'moves': moves.join(' '),
      'rating': rating,
      'ratingdeviation': ratingDeviation,
      'popularity': popularity,
      'nbplays': nbPlays,
      'themes': themes.join(' '),
      'gameurl': gameUrl,
    };
  }
}

void main() {
  final hehe = {
    "items": [
      {
        "puzzleid": "tmtWU",
        "fen": "6k1/p5p1/4R3/2p3N1/5P2/1P6/1Pr4r/3K4 b - - 3 32",
        "moves": "c2b2 e6e8",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "endgame mate mateIn1 oneMove",
        "gameurl": "https://lichess.org/WLyekyth/black#64",
        "openingtags": ""
      },
      {
        "puzzleid": "thkRJ",
        "fen": "r1b2rk1/2p1qppp/p3p3/1p6/3P4/2PQ4/PPB2PPP/R4RK1 b - - 1 18",
        "moves": "c8b7 d3h7",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "kingsideAttack mate mateIn1 middlegame oneMove",
        "gameurl": "https://lichess.org/9xPMowv7/black#36",
        "openingtags": "French_Defense French_Defense_Knight_Variation"
      },
      {
        "puzzleid": "tjdNk",
        "fen": "8/7k/5Qpp/7r/5P2/4p1P1/4P3/4qK2 w - - 0 46",
        "moves": "f1e1 h5h1",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "endgame mate mateIn1 oneMove queenRookEndgame",
        "gameurl": "https://lichess.org/k483nzJP#91",
        "openingtags": ""
      },
      {
        "puzzleid": "tmU5Q",
        "fen": "1k6/p1p5/Pp2p3/1P2P1R1/3P3p/2r5/8/6K1 b - - 0 45",
        "moves": "c3c4 g5g8",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "endgame mate mateIn1 oneMove rookEndgame",
        "gameurl": "https://lichess.org/elFnc6GC/black#90",
        "openingtags": ""
      },
      {
        "puzzleid": "tmkIn",
        "fen": "5r1k/6pp/p7/1p6/8/1P5P/2q2P2/4R1K1 b - - 0 31",
        "moves": "f8f2 e1e8 f2f8 e8f8",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "backRankMate endgame mate mateIn2 queenRookEndgame short",
        "gameurl": "https://lichess.org/HmEfFwpf/black#62",
        "openingtags": ""
      },
      {
        "puzzleid": "td3j5",
        "fen": "4r1k1/3nqp1p/6p1/8/3b4/2P2N1P/1PQ2PPB/6K1 w - - 0 24",
        "moves": "c3d4 e7e1 f3e1 e8e1",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "backRankMate endgame mate mateIn2 sacrifice short",
        "gameurl": "https://lichess.org/s9e4su3y#47",
        "openingtags": ""
      },
      {
        "puzzleid": "tZSwC",
        "fen": "6k1/1Q3p1p/4p1p1/1p6/5PPP/5R2/1r6/3r3K w - - 3 37",
        "moves": "f3f1 d1f1",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "endgame hangingPiece mate mateIn1 oneMove queenRookEndgame",
        "gameurl": "https://lichess.org/gksvG8Eo#73",
        "openingtags": ""
      },
      {
        "puzzleid": "tjXde",
        "fen": "N2kr3/pp3ppp/3p4/5P2/8/3P2P1/PPPqR2P/1K3B1Q w - - 1 21",
        "moves": "e2d2 e8e1 d2d1 e1d1",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "backRankMate endgame mate mateIn2 short",
        "gameurl": "https://lichess.org/GvWhwiVA#41",
        "openingtags": ""
      },
      {
        "puzzleid": "tnadE",
        "fen": "3q2k1/5ppp/1N6/p7/3Q4/P2b3P/1P3PP1/4R1K1 b - - 0 34",
        "moves": "d8d4 e1e8",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "backRankMate endgame mate mateIn1 oneMove",
        "gameurl": "https://lichess.org/GoCflBxG/black#68",
        "openingtags": ""
      },
      {
        "puzzleid": "tleVc",
        "fen": "6Qk/7p/4N3/p2pP3/6Pq/7r/P5R1/5RK1 b - - 0 34",
        "moves": "h8g8 f1f8",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "endgame master mate mateIn1 oneMove",
        "gameurl": "https://lichess.org/fkfYrnXP/black#68",
        "openingtags": ""
      }
    ]
  };
  print(Puzzles.fromJson(hehe).puzzles[0].toJson());
}
