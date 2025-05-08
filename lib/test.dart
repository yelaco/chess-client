import 'package:flutter_slchess/core/models/historymatch_model.dart';
import 'package:flutter_slchess/core/models/moveset_model.dart';

void main() async {
  List<MoveItem> historyMatchItemToMove(HistoryMatchModel history) {
    return history.items
        .map((e) => MoveItem(
              move: e.move.uci,
              fen: e.gameState,
            ))
        .toList();
  }

  const json = {
    "items": [
      {
        "id": "a7bde6fa-46ec-409e-91c9-d5bf30504558",
        "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
        "playerStates": [
          {"clock": "8.873298884s", "status": "CONNECTED"},
          {"clock": "16.874894277s", "status": "CONNECTED"}
        ],
        "gameState": "6k1/1pp2pbp/p3b1p1/4N3/4N3/8/PPP2PPP/R1Br2K1 w - - 1 16",
        "move": {
          "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
          "uci": "d8d1"
        },
        "ply": 30,
        "timestamp": "2025-04-07T16:41:43.277511716Z"
      },
      {
        "id": "22323c8c-43b1-486c-8f86-d363689981d2",
        "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
        "playerStates": [
          {"clock": "8.873298884s", "status": "CONNECTED"},
          {"clock": "18.947906136s", "status": "CONNECTED"}
        ],
        "gameState": "3r2k1/1pp2pbp/p3b1p1/4N3/4N3/8/PPP2PPP/R1B3K1 b - - 0 15",
        "move": {
          "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
          "uci": "c3e4"
        },
        "ply": 29,
        "timestamp": "2025-04-07T16:41:41.94935053Z"
      }
    ],
    "nextPageToken": {"id": "22323c8c-43b1-486c-8f86-d363689981d2", "ply": "29"}
  };

  final history = HistoryMatchModel.fromJson(json);
  final moves = historyMatchItemToMove(history);
  print(moves);
}
