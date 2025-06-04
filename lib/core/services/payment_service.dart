import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_zalopay_sdk/flutter_zalopay_sdk.dart';

class ZaloPayService {
  static const int appId = 2554;
  static const String key1 = "sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn";
  static const String createOrderUrl =
      "https://sb-openapi.zalopay.vn/v2/create";

  // Tạo MAC theo yêu cầu của ZaloPay
  static String generateMac(Map<String, dynamic> order) {
    final rawData =
        "${order['app_id']}|${order['app_trans_id']}|${order['app_user']}|"
        "${order['amount']}|${order['app_time']}|${order['embed_data']}|${order['item']}";

    final key = utf8.encode(key1);
    final bytes = utf8.encode(rawData);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  // Tạo AppTransID theo format yêu cầu: yymmdd_xxxx
  static String generateAppTransId() {
    final now = DateTime.now().toUtc().add(
          const Duration(hours: 7),
        ); // Convert to Vietnam timezone
    final randomNum = DateTime.now().millisecondsSinceEpoch % 1000000;
    return "${DateFormat('yyMMdd').format(now)}_$randomNum";
  }

  // Tạo đơn hàng ZaloPay
  static Future<Map<String, dynamic>> createOrder({
    required String appUser,
    required int amount,
    required String description,
  }) async {
    try {
      // Tạo items theo format ZaloPay yêu cầu
      final items = [
        {
          "itemid": "item1",
          "itemname": "Sản phẩm test",
          "itemprice": amount,
          "itemquantity": 1,
        },
      ];

      // Tạo embed_data theo format yêu cầu
      final embedData = {
        "promotioninfo": "",
        "merchantinfo": "du lieu rieng cua ung dung",
      };

      // Tạo AppTransID
      final appTransId = generateAppTransId();

      // Tạo order request
      final order = {
        "app_id": appId,
        "app_user": appUser,
        "app_time": DateTime.now().millisecondsSinceEpoch,
        "app_trans_id": appTransId,
        "amount": amount,
        "description": description,
        "embed_data": jsonEncode(embedData),
        "item": jsonEncode(items),
        "bank_code": "zalopayapp",
        "callback_url":
            "https://ky9s1s2sla.execute-api.ap-southeast-2.amazonaws.com/dev/payment/confirm"
      };

      // Tạo MAC
      order["mac"] = generateMac(order);

      // Gửi request tạo đơn hàng
      final response = await http.post(
        Uri.parse(createOrderUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(order),
      );

      print("Response: ${response.body}");

      // Parse response
      final responseData = jsonDecode(response.body);

      if (responseData["return_code"] != 1) {
        throw Exception("ZaloPay API error: ${responseData["return_message"]}");
      }

      return responseData;
    } catch (e) {
      throw Exception("Lỗi tạo đơn hàng: $e");
    }
  }

  // Hàm thanh toán với ZaloPay
  static Future<String> payWithZaloPay(String zpTransToken) async {
    try {
      print("ZpTransToken: $zpTransToken");
      print("FlutterZaloPaySdk: $FlutterZaloPaySdk");
      print("bat dau thanh toan");
      final result =
          await FlutterZaloPaySdk.payOrder(zpToken: zpTransToken).then((event) {
        switch (event) {
          case FlutterZaloPayStatus.cancelled:
            return "User Huỷ Thanh Toán";
          case FlutterZaloPayStatus.success:
            return "Thanh toán thành công";
          case FlutterZaloPayStatus.failed:
            return "Thanh toán thất bại";
          default:
            return "Thanh toán thất bại";
        }
      });

      print("Result: $result");
      return result;
    } catch (e) {
      throw Exception("Lỗi thanh toán ZaloPay: $e");
    }
  }
}

void main() async {
  final zaloPayService = ZaloPayService();
  try {
    final token = await ZaloPayService.payWithZaloPay(
      "ACixFNJEUmzGQH7-bsIvsMow",
    );
    print("Token: $token");
  } catch (e) {
    print("Error: $e");
  }
}
