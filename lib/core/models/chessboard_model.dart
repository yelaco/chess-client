import 'match_model.dart';

class ChessboardModel {
  final MatchModel match;
  final bool isOnline;
  final bool isWhite;
  bool enableSwitchBoard;

  ChessboardModel({
    required this.match,
    required this.isOnline,
    required this.isWhite,
    this.enableSwitchBoard = false,
  });
}
