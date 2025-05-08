import 'package:flutter_slchess/core/models/gamestate_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class MatchWebsocketService {
  final WebSocketChannel channel;

  MatchWebsocketService._(this.channel);

  factory MatchWebsocketService.startGame(
      String matchId, String idToken, String server) {
    final channel = IOWebSocketChannel.connect(
      Uri.parse("ws://$server:7202/game/$matchId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': idToken,
      },
    );
    return MatchWebsocketService._(channel);
  }

  void listen(
      {void Function(GameState gameState)? onGameState,
      void Function(GameState gameState)? onEndgame,
      void Function()? onStatusChange,
      required BuildContext context}) {
    // Thêm BuildContext vào tham số
    channel.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          print(data['type'] == "drawOffer");
          switch (data['type']) {
            case "gameState":
              GameState gameState = GameState.fromJson(data['game']);
              if (gameState.outcome != "*") {
                onEndgame?.call(gameState);
              }
              onGameState?.call(gameState);
              break;
            case "drawOffer":
              print("opponent offer a draw");
              _showDrawOfferDialog(context); // Hiện dialog khi có đề nghị hòa
              break;
            case "playerStatus":
              onStatusChange?.call();
              break;
            default:
              print("Unknown message type: ${data['type']}");
          }
        } catch (e, stackTrace) {
          print('Error processing incoming message: $e');
          print('Stack trace: $stackTrace');
        }
      },
      onError: (error) {
        print('Stream encountered an error: $error');
        _showConnectionErrorDialog(context, "Lỗi kết nối: $error");
      },
      onDone: () {
        print('Luồng đã bị đóng.');
        // Hiển thị thông báo và điều hướng về home khi luồng bị đóng
        _showConnectionClosedDialog(context);
      },
    );
  }

  void _showDrawOfferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Đề nghị hòa"),
          content: const Text(
              "Người chơi đã đề nghị hòa. Bạn có muốn chấp nhận không?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Từ chối"),
              onPressed: () {
                Navigator.of(context).pop();
                declineDraw();
              },
            ),
            TextButton(
              child: const Text("Chấp nhận"),
              onPressed: () {
                Navigator.of(context).pop();
                acceptDraw();
              },
            ),
          ],
        );
      },
    );
  }

  void _showConnectionClosedDialog(BuildContext context) {
    // Đảm bảo hiển thị dialog trên main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Kết nối bị ngắt'),
            content: const Text(
                'Kết nối đến máy chủ đã bị đóng. Trận đấu không thể tiếp tục.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Quay về trang chủ'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              ),
            ],
          );
        },
      );
    });
  }

  void _showConnectionErrorDialog(BuildContext context, String errorMessage) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Lỗi kết nối'),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child: const Text('Quay về trang chủ'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              ),
            ],
          );
        },
      );
    });
  }

  void _sendGameData(Map<String, Object> data) {
    final message = {
      "type": "gameData",
      "data": data,
      "createdAt": DateTime.now().toUtc().toIso8601String(),
    };
    try {
      final jsonMessage = jsonEncode(message);
      print('Sending message: $jsonMessage');
      channel.sink.add(jsonMessage);
    } catch (e, stackTrace) {
      print('Error sending message: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void resign() {
    print("Người chơi đã đầu hàng");
    _sendGameData({"action": "resign"});
  }

  void offerDraw() {
    print("Offering draw");
    _sendGameData({"action": "offerDraw"});
  }

  void acceptDraw() {
    print("Người chơi đã chấp nhận hòa");
    _sendGameData({"action": "offerDraw"});
  }

  void declineDraw() {
    print("Người chơi đã từ chối hòa");
    _sendGameData({"action": "declineDraw"});
  }

  void makeMove(String move) {
    print('Sending move data for move: $move');
    _sendGameData({"action": "move", "move": move});
  }

  void close() {
    channel.sink.close();
  }
}
