import '../models/player.dart';
import '../models/match_model.dart';

class PlayerService {
  void updateConnectionStatus(PlayerStateModel playerState, MatchModel match) {
    if (playerState.id == match.player1.user.id) {
      match.player1.isConnect = playerState.status;
    }
  }
}
