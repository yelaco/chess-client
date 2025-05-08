class GameState {
  final String fen;
  final List<int> clocks;
  final String? outcome;
  final String? method;
  final String? lastMove;

  GameState({
    required this.fen,
    required this.clocks,
    this.outcome,
    this.method,
    this.lastMove,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    List<int> parsedClocks = [];
    if (json['clocks'] != null) {
      // Handle clock values which can be either strings or integers
      for (var clock in json['clocks']) {
        if (clock is int) {
          parsedClocks.add(clock);
        } else if (clock is String) {
          // Extract minutes and seconds from format like "9m53.619414155s"
          int milliseconds = 0;

          // Parse minutes
          RegExp minutesRegex = RegExp(r'(\d+)m');
          var minutesMatch = minutesRegex.firstMatch(clock);
          if (minutesMatch != null) {
            int minutes = int.parse(minutesMatch.group(1)!);
            milliseconds += minutes * 60 * 1000;
          }

          // Parse seconds (including fractional part)
          RegExp secondsRegex = RegExp(r'(\d+\.\d+|\d+)s');
          var secondsMatch = secondsRegex.firstMatch(clock);
          if (secondsMatch != null) {
            double seconds = double.parse(secondsMatch.group(1)!);
            milliseconds += (seconds * 1000).round();
          }

          parsedClocks.add(milliseconds);
        }
      }
    }

    return GameState(
      fen: json['fen'] as String,
      clocks: parsedClocks,
      outcome: json['outcome'] as String?,
      method: json['method'] as String?,
      lastMove: json['lastMove'] as String?,
    );
  }
}

void main() {
  var json = {
    "type": "gameState",
    "game": {
      "outcome": "*",
      "method": "NoMethod",
      "fen": "rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1",
      "clocks": ["9m53.619414155s", "10m0s"]
    }
  };

  print(json.runtimeType);
}
