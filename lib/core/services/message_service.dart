import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class MessageService {
  final WebSocketChannel channel;
  MessageService._(this.channel);

  factory MessageService.startMessage(String conversationId, String idToken) {
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
      return MessageService._(channel);
    } catch (e) {
      print('Lỗi kết nối WebSocket: $e');
      rethrow;
    }
  }

  void listen({
    required void Function(Message message) onMessage,
    required void Function() onStatusChange,
  }) {
    channel.stream.listen(
      (message) {
        try {
          print('Nhận tin nhắn: $message');
          final data = jsonDecode(message);

          if (data['type'] == 'start_ack') {
            print('Kết nối WebSocket thành công');
            onStatusChange();
          } else if (data['type'] == 'type') {
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
        print('Kết nối đã đóng');
      },
    );
  }

  void joinConversation({
    required String conversationId,
    required String idToken,
  }) async {
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

  void leaveConversation({required String conversationId}) {
    channel.sink.add(jsonEncode({"id": conversationId, "type": "stop"}));
  }

  Future<Message?> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required String senderUsername,
    required String idToken,
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
