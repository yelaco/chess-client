import 'package:hive/hive.dart';
import 'package:flutter_slchess/core/models/moveset_model.dart';
import 'package:flutter_slchess/core/models/historymatch_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_slchess/core/constants/constants.dart';

import 'package:chess/chess.dart';

class MoveSetService {
  static const String boxName = 'movesetBox';
  late Box<MoveSet> _box;
  static const initFen =
      "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

  // Khởi tạo service
  Future<void> init() async {
    _box = await Hive.openBox<MoveSet>(boxName);
  }

  // Lưu một ván cờ mới
  Future<void> saveGame(String matchId, List<MoveItem> moves) async {
    final moveSet = MoveSet(matchId: matchId, moves: moves);
    await _box.put(matchId, moveSet);
  }

  // Thêm nước đi mới vào ván cờ hiện tại
  Future<void> addMove(String gameId, String fen, String move) async {
    final moveSet = _box.get(gameId);
    if (moveSet != null) {
      if (moveSet.moves.isEmpty) {
        moveSet.moves.add(MoveItem(move: move, fen: fen));
      } else {
        moveSet.moves.add(MoveItem(move: move, fen: fen));
      }
      await _box.put(gameId, moveSet);
    }
  }

  Move getMoveFromFenDiff(String fen1, String fen2) {
    final chess = Chess.fromFEN(fen1);
    final moves = chess.generate_moves();

    for (var move in moves) {
      final tempGame = Chess.fromFEN(fen1);
      tempGame.move(move);

      if (tempGame.fen == fen2) {
        return move; // Trả về nước đi dưới dạng UCI, ví dụ: "e2e4"
      }
    }

    throw Exception('No move found');
  }

  // Lấy tất cả nước đi của một ván cờ
  Future<MoveSet> getGameMoves(
      String gameId, String idToken, bool isOnline) async {
    final moveSet = _box.get(gameId);
    if (moveSet != null) {
      return moveSet;
    }
    if (isOnline) {
      final historyMoveSet = await getMoveSetfromHistoryMatch(gameId, idToken);
      await saveGame(gameId, historyMoveSet.moves);
      return historyMoveSet;
    }
    return MoveSet(matchId: gameId, moves: []);
  }

  // Xóa một ván cờ
  Future<void> deleteGame(String gameId) async {
    await _box.delete(gameId);
  }

  // Đóng box khi không cần nữa
  Future<void> close() async {
    await _box.close();
  }

  Future<HistoryMatchModel> getHistoryMatch(
      String matchId, String idToken) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getHistoryMatchUrl(matchId)),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      if (response.statusCode == 200) {
        return HistoryMatchModel.fromJson(jsonDecode(response.body));
      } else {
        return HistoryMatchModel(items: []);
      }
    } catch (e) {
      return HistoryMatchModel(items: []);
    }
  }

  Future<MoveSet> getMoveSetfromHistoryMatch(
      String matchId, String idToken) async {
    final history = await getHistoryMatch(matchId, idToken);
    if (history.items.isEmpty) {
      return MoveSet(matchId: matchId, moves: []);
    }
    return MoveSet(
        matchId: history.items[0].matchId,
        moves: historyMatchItemToMoveItem(history));
  }

  List<MoveItem> historyMatchItemToMoveItem(HistoryMatchModel history) {
    return history.items
        .map((e) => MoveItem(
              move: e.move.uci,
              fen: e.gameState,
            ))
        .toList();
  }
}
