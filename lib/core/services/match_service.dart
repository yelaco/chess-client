import 'dart:convert';
import '../models/match_model.dart';
import '../models/player.dart';

class MatchService {
  Future<MatchModel> getMatchFromJson(String jsonString) {
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return MatchModel.fromJson(jsonData);
  }

  Player getPlayer1FromMatch(MatchModel match) {
    return match.player1;
  }

  Player getPlayer2FromMatch(MatchModel match) {
    return match.player2;
  }

  bool isUserWhite() {
    return true;
  }
}
