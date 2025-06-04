import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../constants/constants.dart';
import '../models/message_model.dart';

class SpectateService {
  final WebSocketChannel channel;
  final String conversationId;
  final String specId;
  final String idToken;

  SpectateService._(
      this.channel, this.conversationId, this.specId, this.idToken);

  factory SpectateService.startSpectate(
      String conversationId, String specId, String idToken) {
    // Sửa URL từ https:// thành wss:// và loại bỏ :0 và #
    const String endpoint =
        "wss://x7zwyxh5bjez7omsqzkjcyglq4.appsync-realtime-api.ap-southeast-2.amazonaws.com/graphql";

    try {
      print("Đang kết nối tới: $endpoint");
      final channel = IOWebSocketChannel.connect(
        Uri.parse(endpoint),
        headers: {
          'Sec-WebSocket-Protocol': 'graphql-ws',
          'Authorization': idToken,
          'host': dotenv.env['APPSYNC_URL'] ?? '',
        },
      );
      print(channel);
      return SpectateService._(channel, conversationId, specId, idToken);
    } catch (e) {
      print('Lỗi kết nối WebSocket: $e');
      rethrow;
    }
  }

  void listen({
    required void Function(Message message) onMessage,
    required void Function() onStatusChange,
    required void Function() onError,
    required void Function() onDone,
    required void Function() onClose,
    required void Function() onUpdateMatchStatus,
  }) {
    channel.stream.listen(
      (message) {
        try {
          print('Nhận tin nhắn: $message');
          final data = jsonDecode(message);

          if (data['type'] == 'start_ack') {
            print('Kết nối WebSocket thành công');
            onStatusChange();
          } else if (data['type'] == 'ka') {
            onStatusChange();
          } else if (data['type'] == 'data' && data['payload'] != null) {
            // Kiểm tra cấu trúc dữ liệu
            if (data['payload']['data'] != null &&
                data['payload']['data']['onMessageSent'] != null) {
              onMessage(
                  Message.fromJson(data['payload']['data']['onMessageSent']));
            } else {
              print('Cấu trúc dữ liệu không đúng: $data');
            }
          } else {
            print('Loại tin nhắn không xác định: ${data['type']}');
          }
        } catch (e, stackTrace) {
          print('Lỗi xử lý tin nhắn: $e');
          print('Stack trace: $stackTrace');
        }
      },
      onError: (error) {
        print('Lỗi stream: $error');
      },
      onDone: () {
        print('Kết nối chat đã đóng');
      },
    );
  }

  void joinSpectate() async {
    try {
      final String host = dotenv.env['APPSYNC_URL']!;

      channel.sink.add(jsonEncode({
        "id": specId,
        "payload": {
          "data":
              "{\"query\":\"subscription onMessageSent {\\n onMessageSent(ConversationId: \\\"$specId\\\") {\\n __typename\\n Id\\n ConversationId\\n SenderId\\n Username\\n Content\\n CreatedAt\\n}\\n }\",\"variables\":{}}",
          "extensions": {
            "authorization": {"Authorization": idToken, "host": host}
          }
        },
        "type": "start"
      }));
    } catch (e) {
      print('Lỗi khi tham gia conversation: $e');
    }
  }

  void joinConversation() async {
    try {
      final String host = dotenv.env['APPSYNC_URL']!;

      channel.sink.add(jsonEncode({
        "id": conversationId,
        "payload": {
          "data":
              "{\"query\":\"subscription onMessageSent {\\n onMessageSent(ConversationId: \\\"$conversationId\\\") {\\n __typename\\n Id\\n ConversationId\\n SenderId\\n Username\\n Content\\n CreatedAt\\n}\\n }\",\"variables\":{}}",
          "extensions": {
            "authorization": {"Authorization": idToken, "host": host}
          }
        },
        "type": "start"
      }));
    } catch (e) {
      print('Lỗi khi tham gia conversation: $e');
    }
  }

  void leaveConversation() {
    channel.sink.add(jsonEncode({"id": conversationId, "type": "stop"}));
  }

  void leaveSpectate() {
    channel.sink.add(jsonEncode({"id": specId, "type": "stop"}));
  }

  Future<Message?> sendMessage({
    required String senderId,
    required String content,
    required String senderUsername,
  }) async {
    final String host = dotenv.env['APPSYNC_URL']!;

    const String mutation = r'''
      mutation SendMessage($input: SendMessageInput!) {
        sendMessage(input: $input) {
          Id
          ConversationId
          SenderId
          Username
          Content
          CreatedAt
        }
      }
    ''';

    final variables = {
      "input": {
        "conversationId": conversationId,
        "senderId": senderId,
        "username": senderUsername,
        "content": content,
      }
    };

    final body = jsonEncode({
      "query": mutation,
      "variables": variables,
    });

    try {
      final response = await http.post(
        Uri.parse("https://$host/graphql"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              idToken, // hoặc 'Bearer $idToken' tùy cấu hình AppSync
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
          print('GraphQL errors: ${data['errors']}');
          return null;
        }
        final msg = Message.fromJson(data['data']['sendMessage']);
        return msg;
      } else {
        print('Lỗi gửi tin nhắn: ${response.body}');
      }
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
    }
    return null;
  }

  void close() {
    channel.sink.close();
  }
}
