import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slchess/core/models/evaluation_model.dart';
import 'package:flutter_slchess/core/constants/constants.dart';
import 'package:chess/chess.dart';

class EvaluationService {
  final WebSocketChannel channel;
  bool _isConnected = false;

  // Callback khi có thay đổi trạng thái kết nối
  final Function(bool isConnected)? onConnectionChange;

  EvaluationService._(this.channel, this.onConnectionChange);

  factory EvaluationService.startGame(String idToken,
      {Function(bool)? onConnectionChange}) {
    print("Kết nối đến websocket đánh giá: ${WebsocketConstants.wsUrl}");

    final channel = IOWebSocketChannel.connect(
      Uri.parse(WebsocketConstants.wsUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': idToken,
      },
      pingInterval:
          const Duration(seconds: 10), // Gửi ping định kỳ để giữ kết nối
    );

    final service = EvaluationService._(channel, onConnectionChange);

    // Đánh dấu kết nối thành công ngay từ đầu
    service._isConnected = true;
    onConnectionChange?.call(true);

    return service;
  }

  void listen(
      {void Function(EvaluationModel evaluationModel)? onEvaluation,
      void Function(dynamic error)? onError,
      required BuildContext context}) {
    channel.stream.listen(
      (message) {
        try {
          if (!_isConnected) {
            _isConnected = true;
            onConnectionChange?.call(true);
          }

          // Xử lý tin nhắn
          final data = jsonDecode(message);
          final evaluationModel = EvaluationModel.fromJson(data);
          onEvaluation?.call(evaluationModel);
        } catch (e) {
          print("Lỗi khi xử lý tin nhắn từ websocket: $e");
          if (onError != null) {
            onError(e);
          }
        }
      },
      onError: (error) {
        print("Lỗi websocket: $error");
        _isConnected = false;
        onConnectionChange?.call(false);
        if (onError != null) {
          onError(error);
        }
      },
      onDone: () {
        print("Kết nối websocket đã đóng");
        _isConnected = false;
        onConnectionChange?.call(false);
      },
    );
  }

  void sendEvaluation(String fen) {
    if (!_isConnected) {
      print("Cảnh báo: Đang gửi yêu cầu đánh giá khi chưa kết nối");
    }

    try {
      print("Gửi yêu cầu đánh giá FEN: $fen");
      channel.sink.add(jsonEncode({
        'action': 'evaluate',
        'message': fen,
      }));
    } catch (e) {
      print("Lỗi khi gửi yêu cầu đánh giá: $e");
    }
  }

  bool get isConnected => _isConnected;

  void close() {
    try {
      print("Đóng kết nối websocket đánh giá");
      channel.sink.close();
      _isConnected = false;
      onConnectionChange?.call(false);
    } catch (e) {
      print("Lỗi khi đóng kết nối websocket: $e");
    }
  }

  List<dynamic> convertUciToSan(String uciMoves, String initialFen) {
    try {
      final chess = Chess.fromFEN(initialFen);
      final moves = uciMoves.split(' ');

      for (final move in moves) {
        if (move.isEmpty) continue;

        if (move.length >= 4) {
          final from = move.substring(0, 2);
          final to = move.substring(2, 4);
          String? promotion;

          if (move.length > 4) {
            promotion = move.substring(4, 5);
          }

          final moveObj = {'from': from, 'to': to};
          if (promotion != null) {
            moveObj['promotion'] = promotion;
          }

          chess.move(moveObj);
        }
      }

      return chess.getHistory();
    } catch (e) {
      print("Lỗi khi chuyển đổi UCI sang SAN: $e");
      return [];
    }
  }
}

void main() {
  final service = EvaluationService.startGame('your_token');
  const uciMoves =
      "c1h6 g7h6 d4d5 f8g7 h3f4 e8g8 e2e3 g4d7 f4h5 g7h8 a1a2 d8a5 b1d2 f6f5 f1d3 a5c3 c2b1 a7a5 e1g1 b8a6 d2f3 a6c7 f3h4";
  final sanMoves = service.convertUciToSan(uciMoves,
      'rn1qkb1r/pp2p1pp/3p1p1n/2p5/2PP2b1/PP5N/2Q1PPPP/RNB1KB1R w KQkq - 0 4');
  print(sanMoves);
}
