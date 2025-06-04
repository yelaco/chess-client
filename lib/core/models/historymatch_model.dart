class HistoryMatchModel {
  final List<HistoryMatchItem> items;

  HistoryMatchModel({required this.items});

  factory HistoryMatchModel.fromJson(Map<String, dynamic> json) {
    return HistoryMatchModel(
      items: (json['items'] as List)
          .map((item) => HistoryMatchItem.fromJson(item))
          .toList(),
    );
  }
}

class HistoryMatchItem {
  final String id;
  final String matchId;
  final List<PlayerState> playerStates;
  final String gameState;
  final HistoryMove move;
  final int ply;
  final DateTime timestamp;

  HistoryMatchItem({
    required this.id,
    required this.matchId,
    required this.playerStates,
    required this.gameState,
    required this.move,
    required this.ply,
    required this.timestamp,
  });

  factory HistoryMatchItem.fromJson(Map<String, dynamic> json) {
    return HistoryMatchItem(
      id: json['id'],
      matchId: json['matchId'],
      playerStates: (json['playerStates'] as List)
          .map((state) => PlayerState.fromJson(state))
          .toList(),
      gameState: json['gameState'],
      move: HistoryMove.fromJson(json['move']),
      ply: json['ply'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class PlayerState {
  final String clock;
  final String status;

  PlayerState({required this.clock, required this.status});

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      clock: json['clock'],
      status: json['status'],
    );
  }
}

class HistoryMove {
  final String playerId;
  final String uci;

  HistoryMove({required this.playerId, required this.uci});

  factory HistoryMove.fromJson(Map<String, dynamic> json) {
    return HistoryMove(
      playerId: json['playerId'],
      uci: json['uci'],
    );
  }
}

const historyGame = {
  "items": [
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
    },
    {
      "id": "9eda97ca-97f2-4560-98af-ed507691dd50",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "10.751356685s", "status": "CONNECTED"},
        {"clock": "18.947906136s", "status": "CONNECTED"}
      ],
      "gameState": "3r2k1/1pp2pbp/p3b1p1/4N3/4n3/2N5/PPP2PPP/R1B3K1 w - - 0 15",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "f6e4"
      },
      "ply": 28,
      "timestamp": "2025-04-07T16:41:40.071252099Z"
    },
    {
      "id": "50a75384-bce7-41a4-9928-2db73d04aaad",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "10.751356685s", "status": "CONNECTED"},
        {"clock": "21.030935658s", "status": "CONNECTED"}
      ],
      "gameState": "3r2k1/1pp2pbp/p3bnp1/4N3/4P3/2N5/PPP2PPP/R1B3K1 b - - 0 14",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "e3e4"
      },
      "ply": 27,
      "timestamp": "2025-04-07T16:41:38.729767014Z"
    },
    {
      "id": "538bcc13-e6a8-4336-94bf-9dc93381626f",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "15.298873442s", "status": "CONNECTED"},
        {"clock": "21.030935658s", "status": "CONNECTED"}
      ],
      "gameState": "3r2k1/1pp2pbp/p3bnp1/4N3/8/2N1P3/PPP2PPP/R1B3K1 w - - 0 14",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "f8d8"
      },
      "ply": 26,
      "timestamp": "2025-04-07T16:41:34.182240538Z"
    },
    {
      "id": "0fb8d169-60fd-4cff-b40f-9be4027376d8",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "15.298873442s", "status": "CONNECTED"},
        {"clock": "22.75232239s", "status": "CONNECTED"}
      ],
      "gameState":
          "3R1rk1/1pp2pbp/p3bnp1/4N3/8/2N1P3/PPP2PPP/R1B3K1 b - - 0 13",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "d1d8"
      },
      "ply": 25,
      "timestamp": "2025-04-07T16:41:33.205979247Z"
    },
    {
      "id": "010a6c2e-d8f0-4611-8798-cf8e70a920bb",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "19.222109717s", "status": "CONNECTED"},
        {"clock": "22.75232239s", "status": "CONNECTED"}
      ],
      "gameState":
          "3r1rk1/1pp2pbp/p3bnp1/4N3/8/2N1P3/PPP2PPP/R1BR2K1 w - - 2 13",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "e8g8"
      },
      "ply": 24,
      "timestamp": "2025-04-07T16:41:29.282778842Z"
    },
    {
      "id": "4a2f1cd5-54ce-47b9-b449-f9f47bf3c980",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "19.222109717s", "status": "CONNECTED"},
        {"clock": "25.614187212s", "status": "CONNECTED"}
      ],
      "gameState":
          "3rk2r/1pp2pbp/p3bnp1/4N3/8/2N1P3/PPP2PPP/R1BR2K1 b k - 1 12",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "f1d1"
      },
      "ply": 23,
      "timestamp": "2025-04-07T16:41:27.164949415Z"
    },
    {
      "id": "151b0501-ff92-432c-9851-254bb57aa598",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "23.437598337s", "status": "CONNECTED"},
        {"clock": "25.614187212s", "status": "CONNECTED"}
      ],
      "gameState":
          "3rk2r/1pp2pbp/p3bnp1/4N3/8/2N1P3/PPP2PPP/R1B2RK1 w k - 0 12",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "a8d8"
      },
      "ply": 22,
      "timestamp": "2025-04-07T16:41:22.949603402Z"
    },
    {
      "id": "add700f0-6fe0-402a-ae03-45347a932484",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "23.437598337s", "status": "CONNECTED"},
        {"clock": "27.404527252s", "status": "CONNECTED"}
      ],
      "gameState":
          "r2Qk2r/1pp2pbp/p3bnp1/4N3/8/2N1P3/PPP2PPP/R1B2RK1 b kq - 0 11",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "d1d8"
      },
      "ply": 21,
      "timestamp": "2025-04-07T16:41:21.902173755Z"
    },
    {
      "id": "f47a47fb-ea87-40d1-a7f8-dcdc610c1722",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "31.664456265s", "status": "CONNECTED"},
        {"clock": "27.404527252s", "status": "CONNECTED"}
      ],
      "gameState":
          "r2qk2r/1pp2pbp/p3bnp1/4N3/8/2N1P3/PPP2PPP/R1BQ1RK1 w kq - 1 11",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "d7e6"
      },
      "ply": 20,
      "timestamp": "2025-04-07T16:41:13.675326075Z"
    },
    {
      "id": "b86d5fe2-f701-43b6-8015-de0054eb1df0",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "31.664456265s", "status": "CONNECTED"},
        {"clock": "34.132409465s", "status": "CONNECTED"}
      ],
      "gameState":
          "r2qk2r/1ppb1pbp/p4np1/4N3/8/2N1P3/PPP2PPP/R1BQ1RK1 b kq - 0 10",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "f3e5"
      },
      "ply": 19,
      "timestamp": "2025-04-07T16:41:07.691800848Z"
    },
    {
      "id": "65fd3b83-2be6-435f-8d22-7bdd05095484",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "33.099037066s", "status": "CONNECTED"},
        {"clock": "34.132409465s", "status": "CONNECTED"}
      ],
      "gameState":
          "r2qk2r/1ppb1pbp/p4np1/4p3/8/2N1PN2/PPP2PPP/R1BQ1RK1 w kq - 0 10",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "d6e5"
      },
      "ply": 18,
      "timestamp": "2025-04-07T16:41:06.257288437Z"
    },
    {
      "id": "ce56ce20-e97f-4533-bcb5-3dd9f812d3a6",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "33.099037066s", "status": "CONNECTED"},
        {"clock": "36.169681717s", "status": "CONNECTED"}
      ],
      "gameState":
          "r2qk2r/1ppb1pbp/p2p1np1/4P3/8/2N1PN2/PPP2PPP/R1BQ1RK1 b kq - 0 9",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "d4e5"
      },
      "ply": 17,
      "timestamp": "2025-04-07T16:41:04.964924975Z"
    },
    {
      "id": "4c028ae4-02f6-4206-a4af-476c7ee6ac8e",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "34.487699937s", "status": "CONNECTED"},
        {"clock": "36.169681717s", "status": "CONNECTED"}
      ],
      "gameState":
          "r2qk2r/1ppb1pbp/p2p1np1/4p3/3P4/2N1PN2/PPP2PPP/R1BQ1RK1 w kq - 2 9",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "g8f6"
      },
      "ply": 16,
      "timestamp": "2025-04-07T16:41:03.576254596Z"
    },
    {
      "id": "2f5b5b52-97f6-4e22-89e6-1335e1b21f52",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "34.487699937s", "status": "CONNECTED"},
        {"clock": "38.581272233s", "status": "CONNECTED"}
      ],
      "gameState":
          "r2qk1nr/1ppb1pbp/p2p2p1/4p3/3P4/2N1PN2/PPP2PPP/R1BQ1RK1 b kq - 1 8",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "e1g1"
      },
      "ply": 15,
      "timestamp": "2025-04-07T16:41:01.909192308Z"
    },
    {
      "id": "0cca6a69-fa58-4480-aef1-456c85b68a28",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "36.771850018s", "status": "CONNECTED"},
        {"clock": "38.581272233s", "status": "CONNECTED"}
      ],
      "gameState":
          "r2qk1nr/1ppb1pbp/p2p2p1/4p3/3P4/2N1PN2/PPP2PPP/R1BQK2R w KQkq - 0 8",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "c8d7"
      },
      "ply": 14,
      "timestamp": "2025-04-07T16:40:59.625012684Z"
    },
    {
      "id": "22353b0c-8a6c-4482-bf7b-f192d5fb0e24",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "36.771850018s", "status": "CONNECTED"},
        {"clock": "41.841437948s", "status": "CONNECTED"}
      ],
      "gameState":
          "r1bqk1nr/1ppB1pbp/p2p2p1/4p3/3P4/2N1PN2/PPP2PPP/R1BQK2R b KQkq - 0 7",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "a4d7"
      },
      "ply": 13,
      "timestamp": "2025-04-07T16:40:57.109782173Z"
    },
    {
      "id": "d7dee890-9e3f-4b28-a105-d81054c6107d",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "42.643653324s", "status": "CONNECTED"},
        {"clock": "41.841437948s", "status": "CONNECTED"}
      ],
      "gameState":
          "r1bqk1nr/1ppn1pbp/p2p2p1/4p3/B2P4/2N1PN2/PPP2PPP/R1BQK2R w KQkq e6 0 7",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "e7e5"
      },
      "ply": 12,
      "timestamp": "2025-04-07T16:40:51.237964342Z"
    },
    {
      "id": "7938ff6d-bd47-42b4-869f-d5fc9b6dc9a8",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "42.643653324s", "status": "CONNECTED"},
        {"clock": "47.801928651s", "status": "CONNECTED"}
      ],
      "gameState":
          "r1bqk1nr/1ppnppbp/p2p2p1/8/B2P4/2N1PN2/PPP2PPP/R1BQK2R b KQkq - 1 6",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "b5a4"
      },
      "ply": 11,
      "timestamp": "2025-04-07T16:40:46.021237667Z"
    },
    {
      "id": "c4912bf1-ec18-4252-a516-64ba2a6e6d99",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "45.074776473s", "status": "CONNECTED"},
        {"clock": "47.801928651s", "status": "CONNECTED"}
      ],
      "gameState":
          "r1bqk1nr/1ppnppbp/p2p2p1/1B6/3P4/2N1PN2/PPP2PPP/R1BQK2R w KQkq - 0 6",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "a7a6"
      },
      "ply": 10,
      "timestamp": "2025-04-07T16:40:43.590087774Z"
    },
    {
      "id": "2df243e4-fd2e-4804-88e4-48f828d8a4b0",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "45.074776473s", "status": "CONNECTED"},
        {"clock": "49.460525331s", "status": "CONNECTED"}
      ],
      "gameState":
          "r1bqk1nr/pppnppbp/3p2p1/1B6/3P4/2N1PN2/PPP2PPP/R1BQK2R b KQkq - 3 5",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "b1c3"
      },
      "ply": 9,
      "timestamp": "2025-04-07T16:40:42.67664451Z"
    },
    {
      "id": "d4f17a1a-51b9-4c9f-8f99-c217ef1a493e",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "48.706276859s", "status": "CONNECTED"},
        {"clock": "49.460525331s", "status": "CONNECTED"}
      ],
      "gameState":
          "r1bqk1nr/pppnppbp/3p2p1/1B6/3P4/4PN2/PPP2PPP/RNBQK2R w KQkq - 2 5",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "b8d7"
      },
      "ply": 8,
      "timestamp": "2025-04-07T16:40:39.044823081Z"
    },
    {
      "id": "4b47141f-1e61-4faa-bf13-142a6a7c9b19",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "48.706276859s", "status": "CONNECTED"},
        {"clock": "53.624938619s", "status": "CONNECTED"}
      ],
      "gameState":
          "rnbqk1nr/ppp1ppbp/3p2p1/1B6/3P4/4PN2/PPP2PPP/RNBQK2R b KQkq - 1 4",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "f1b5"
      },
      "ply": 7,
      "timestamp": "2025-04-07T16:40:35.625239521Z"
    },
    {
      "id": "78710d0f-3512-402b-8bc8-5b3a009116ea",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "51.2927369s", "status": "CONNECTED"},
        {"clock": "53.624938619s", "status": "CONNECTED"}
      ],
      "gameState":
          "rnbqk1nr/ppp1ppbp/3p2p1/8/3P4/4PN2/PPP2PPP/RNBQKB1R w KQkq - 0 4",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "d7d6"
      },
      "ply": 6,
      "timestamp": "2025-04-07T16:40:33.038778954Z"
    },
    {
      "id": "a2300288-c269-4870-b6bd-7749bf0b5624",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "51.2927369s", "status": "CONNECTED"},
        {"clock": "55.20744219s", "status": "CONNECTED"}
      ],
      "gameState":
          "rnbqk1nr/ppppppbp/6p1/8/3P4/4PN2/PPP2PPP/RNBQKB1R b KQkq - 0 3",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "e2e3"
      },
      "ply": 5,
      "timestamp": "2025-04-07T16:40:32.201015702Z"
    },
    {
      "id": "28668591-c687-40f6-b0f1-459a091213f0",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "54.342058997s", "status": "CONNECTED"},
        {"clock": "55.20744219s", "status": "CONNECTED"}
      ],
      "gameState":
          "rnbqk1nr/ppppppbp/6p1/8/3P4/5N2/PPP1PPPP/RNBQKB1R w KQkq - 2 3",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "f8g7"
      },
      "ply": 4,
      "timestamp": "2025-04-07T16:40:29.151690721Z"
    },
    {
      "id": "505e6040-dbed-4648-8182-83c306e57255",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "54.342058997s", "status": "CONNECTED"},
        {"clock": "57.159002488s", "status": "CONNECTED"}
      ],
      "gameState":
          "rnbqkbnr/pppppp1p/6p1/8/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq - 1 2",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "g1f3"
      },
      "ply": 3,
      "timestamp": "2025-04-07T16:40:27.945162434Z"
    },
    {
      "id": "b6b02c5f-f031-45df-b6a7-57c0d2ac5f52",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "58.44248711s", "status": "CONNECTED"},
        {"clock": "57.159002488s", "status": "CONNECTED"}
      ],
      "gameState":
          "rnbqkbnr/pppppp1p/6p1/8/3P4/8/PPP1PPPP/RNBQKBNR w KQkq - 0 2",
      "move": {
        "playerId": "e93e7498-f071-7063-50b6-5410bf99d415",
        "uci": "g7g6"
      },
      "ply": 2,
      "timestamp": "2025-04-07T16:40:23.844773936Z"
    },
    {
      "id": "c653dc29-a286-41dd-8b65-3accea850ae0",
      "matchId": "56bf2a73-d41e-4cc7-a8fb-ec2b64a6c738",
      "playerStates": [
        {"clock": "58.44248711s", "status": "CONNECTED"},
        {"clock": "1m0s", "status": "CONNECTED"}
      ],
      "gameState":
          "rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1",
      "move": {
        "playerId": "d90ef498-a0d1-7037-4c01-d3c5992aadba",
        "uci": "d2d4"
      },
      "ply": 1,
      "timestamp": "2025-04-07T16:40:21.747775892Z"
    }
  ],
  "nextPageToken": null
};
