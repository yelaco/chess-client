import 'package:flutter_slchess/core/models/user.dart';

import '../constants/constants.dart';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Để sử dụng jsonEncode
// import 'package:shared_preferences/shared_preferences.dart';

import 'match_service.dart';
import '../models/match_model.dart';

class MatchMakingSerice {
  static final String _localWsGameUrl = WebsocketConstants.game;
  static final String _wsQueueUrl = WebsocketConstants.wsUrl;
  static final String _matchMakingApiUrl = ApiConstants.matchMaking;

  static WebSocketChannel startGame(
      String matchId, String idToken, String server) {
    final WebSocketChannel channel = IOWebSocketChannel.connect(
      Uri.parse("ws://$server:7202/game/$matchId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': idToken, // Thêm token vào header
      },
    );
    return channel;
  }

  static void resign(WebSocketChannel channel) {
    try {
      final Map<String, Object> data = {
        "type": "gameData",
        "data": {"action": "resign"},
        "created_at": DateTime.now().toUtc().toIso8601String()
      };
      print("Người chơi đã đầu hàng");
      channel.sink.add(jsonEncode(data));
    } catch (e, stackTrace) {
      print('Lỗi khi gửi thông tin đầu hàng: $e');
      print('Stack trace: $stackTrace');
    }
  }

  static void offerDraw(WebSocketChannel channel) {
    try {
      final Map<String, Object> data = {
        "type": "gameData",
        "data": {"action": "offerDraw"},
        "created_at": DateTime.now().toUtc().toIso8601String()
      };
      print("Offering draw");
      channel.sink.add(jsonEncode(data));
    } catch (e, stackTrace) {
      print('Error offering draw: $e'); // Thêm thông báo lỗi
      print('Stack trace: $stackTrace'); // Thêm thông tin stack trace
    }
  }

  static void makeMove(String move, WebSocketChannel channel) {
    try {
      final Map<String, Object> data = {
        "type": "gameData",
        "data": {"action": "move", "move": move},
        "createdAt": DateTime.now().toUtc().toIso8601String()
      };
      print('Sending move data: ${jsonEncode(data)}');
      channel.sink.add(jsonEncode(data));
    } catch (e, stackTrace) {
      print('Error sending move: $e');
      print('Stack trace: $stackTrace');
      // Kiểm tra trạng thái kết nối
      print('Connection state: ${channel.closeCode} - ${channel.closeReason}');
    }
  }

  void disconnect(WebSocketChannel channel) {
    channel.sink.close();
  }

  Future<MatchModel?> connectToQueue(String idToken) async {
    final WebSocketChannel channel = IOWebSocketChannel.connect(
      Uri.parse(_wsQueueUrl),
      headers: {
        'Authorization': idToken,
      },
    );

    channel.sink.add(jsonEncode({"action": "queueing"}));

    Completer<MatchModel?> completer = Completer();
    String? lastMessage;

    channel.stream.listen(
      (message) async {
        try {
          // Lưu tin nhắn cuối cùng nhận được
          lastMessage = message;

          final data = jsonDecode(message);

          print("Received WebSocket data: $data");

          if (data.containsKey("matchId")) {
            try {
              MatchModel matchData = await handleQueued(message);
              if (!completer.isCompleted) {
                completer.complete(matchData); // Hoàn thành completer trước
                channel.sink.close(); // Đóng WebSocket sau khi hoàn thành
              }
            } catch (e) {
              if (!completer.isCompleted) completer.completeError(e);
            }
          }
        } catch (e) {
          print("Error parsing WebSocket message: $e");
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      onError: (error) {
        print("WebSocket error: $error");
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () async {
        print("WebSocket connection closed");
        // Nếu có tin nhắn cuối cùng và đó chứa thông tin về trận đấu
        if (lastMessage != null && !completer.isCompleted) {
          try {
            // Kiểm tra xem tin nhắn cuối cùng có phải là thông tin trận đấu không
            final data = jsonDecode(lastMessage!);
            if (data.containsKey("matchId")) {
              MatchModel matchData = await handleQueued(lastMessage!);
              completer.complete(matchData);
              return;
            }
          } catch (e) {
            print("Error processing last message: $e");
          }
        }
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      cancelOnError: true, // Đảm bảo ngắt stream nếu gặp lỗi nghiêm trọng
    );

    return completer.future;
  }

  Future<bool> cancelQueue(String idToken) async {
    final response = await http.delete(
      Uri.parse(_matchMakingApiUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }

  Future<MatchModel?> getQueue(String idToken, String gameMode, double rating,
      {int minRating = 0, int maxRating = 100}) async {
    minRating = minRating == 0 ? (rating - 150).toInt() : minRating;
    maxRating = maxRating == 100 ? (rating + 150).toInt() : maxRating;
    try {
      final response = await http.post(
        Uri.parse(_matchMakingApiUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "minRating": minRating,
          "maxRating": maxRating,
          "gameMode": gameMode
        }),
      );

      print(response);

      if (response.statusCode == 200) {
        try {
          return await handleQueued(response.body);
        } catch (e) {
          print("Error handling queue: $e");
          return null;
        }
      } else if (response.statusCode == 202) {
        try {
          return await connectToQueue(idToken);
        } catch (e) {
          print("Error in WebSocket: $e");
          return null;
        }
      }
    } catch (e) {
      print("Error when getting queue: $e");
    }
    return null;
  }

  bool isUserWhite(MatchModel match, UserModel user) =>
      match.player1.user.id == user.id;

  Future<MatchModel> handleQueued(String message) async {
    try {
      print("[DEBUG] Raw WebSocket message: $message");
      final match = await MatchService().getMatchFromJson(message);
      print("[DEBUG] Parsed Match: ${match.toJson()}");
      return match;
    } catch (e, stackTrace) {
      print("[ERROR] handleQueued failed: $e\n$stackTrace");
      rethrow; // Đẩy lỗi lên để catch ở tầng trên
    }
  }
}

void main() {
  const String token =
      "eyJraWQiOiIwUG5IR3RNYWJGSFM1TkNvWkt1Vjd5UktnRUNpZkdPemVqdVJId2VGUkNRPSIsImFsZyI6IlJTMjU2In0.eyJhdF9oYXNoIjoiaUtsZG13azZFakJMdnYwZS1abDhHdyIsInN1YiI6IjY5ZWU3NGY4LTQwZjEtNzA3NC0yNGNmLTg2Zjg0MThiMDlmZCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX0Z2aEQ1amc2diIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjEiLCJvcmlnaW5fanRpIjoiMDk0ZDA3YzEtMDEyZS00OTk1LWExN2MtZDM3MjM1MTMzMzJiIiwiYXVkIjoiMjUxbGIwN25jYWU4YmpmOXBkZjlmaHJvZWQiLCJldmVudF9pZCI6ImEzNjhhYjM2LWU5ZWEtNDAzOS1hZWE0LWUxYzMzNTVlYzAxNCIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzQxOTQ0Mjc4LCJleHAiOjE3NDE5NDc4NzgsImlhdCI6MTc0MTk0NDI3OCwianRpIjoiNmRlNDEwYjUtMDg3Ni00OWVhLWJmYjctY2Q0OGU4M2I5YjZmIiwiZW1haWwiOiJ0ZXN0dXNlcjFAZ21haWwuY29tIn0.nZxQTYPOXrAB7-qZu4a9axgiicHQcKw1i1tu99MOFQeN9FjyLmfcMTLSXgFZ7iRFPRN9Kjfffq2fqBgfTn1t27um0bOAdGwCZToeBuUGLxuiere6-bD_Bo186-rQ8fqLdyGXIrBdHEeyrlJazRnfWDWk58IQBBlF0oCf4pbRwcwjRciZZYktmn6eDqcC83JYR1cN-v568B4bpb24UEYv1INIQamDLhZBDxiMH3bRIceFuttyjD4GlCwyYBtZPe4jfsa4hITW-zqNc2T4VtM72UFJL_R8yzRS48IH44Eh08JtLgft8Zo2rULQhS_7rBPB3ZGv2XUQbf4btWm00aUrPg"; // Thay thế bằng token thực tế
  // print("Token: $token"); // In ra token để kiểm tra

  MatchMakingSerice().getQueue(token, "10+0", 1200);
}
