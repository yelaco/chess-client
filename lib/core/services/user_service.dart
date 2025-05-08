import 'dart:convert';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/amplify_auth_service.dart';

class UserService {
  static String getUserApiUrl = ApiConstants.getUserInfo;
  static String updateRatingUrl = ApiConstants.getUserInfo;

  static const String USER_BOX = 'userBox';

  Future<UserModel> getUserInfo(String userId, String idToken,
      {Function? onAuthError}) async {
    try {
      final url = "$getUserApiUrl?id=$userId";
      print("Gọi API getUserInfo với URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        print("Token hết hạn hoặc không hợp lệ (401) trong getUserInfo");
        if (onAuthError != null) {
          onAuthError();
        }
        throw Exception(
            'Token hết hạn hoặc không hợp lệ: ${response.statusCode}');
      } else {
        print("API lỗi: ${response.statusCode}, Body: ${response.body}");
        throw Exception('Failed to load user info: ${response.statusCode}');
      }
    } catch (e) {
      print("Error when getting user info: $e");
      throw Exception('Error when getting user info: $e');
    }
  }

  Future<void> updateRating(
      String userId, double newRating, String idToken) async {
    try {
      final response = await http.put(
        Uri.parse("$updateRatingUrl/$userId"),
        headers: {
          'Authorization': idToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'rating': newRating}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update rating: ${response.statusCode}');
      }

      // Cập nhật thông tin user trong Hive
      UserModel updatedUser = await getUserInfo(userId, idToken);
      await savePlayer(updatedUser);
    } catch (e) {
      print("Error when updating rating: $e");
      throw Exception('Error when updating rating');
    }
  }

  Future<void> saveSelfUserInfo(String accessToken, String idToken,
      {Function? onAuthError}) async {
    try {
      // Kiểm tra token trước khi xử lý
      if (accessToken.isEmpty || idToken.isEmpty) {
        print("Token không hợp lệ (rỗng), không thể lấy thông tin người dùng");

        if (onAuthError != null) {
          onAuthError();
        }

        throw Exception('Token rỗng, không thể lấy thông tin người dùng');
      }

      // Đảm bảo box được khởi tạo trước khi sử dụng
      if (!Hive.isBoxOpen(USER_BOX)) {
        await Hive.openBox<UserModel>(USER_BOX);
      }

      // Sử dụng dToken
      final String processedIdToken = _processToken(idToken);

      if (processedIdToken.isEmpty) {
        print("Processed token rỗng, không thể lấy thông tin người dùng");

        if (onAuthError != null) {
          onAuthError();
        }

        throw Exception('Processed token rỗng');
      }

      final response = await http.get(
        Uri.parse(getUserApiUrl),
        headers: {'Authorization': 'Bearer $processedIdToken'},
      );

      if (response.statusCode == 200) {
        UserModel user = UserModel.fromJson(jsonDecode(response.body));

        await savePlayer(user);
      } else if (response.statusCode == 401) {
        // Token hết hạn hoặc không hợp lệ
        print("Token hết hạn hoặc không hợp lệ (401)");

        // Xóa thông tin người dùng
        await clearUserData();

        // Gọi callback để xử lý lỗi xác thực (ví dụ: đăng xuất hoặc refresh token)
        if (onAuthError != null) {
          onAuthError();
        }

        throw Exception(
            'Token hết hạn hoặc không hợp lệ: ${response.statusCode}');
      } else {
        throw Exception('Failed to load user info: ${response.statusCode}');
      }
    } catch (e) {
      print("Error when getting user info: $e");
      throw Exception('Error when getting user info: $e');
    }
  }

  // Xử lý token nếu có định dạng JSON
  String _processToken(String token) {
    try {
      // Kiểm tra xem token có phải là một đối tượng JSON không
      if (token.trim().startsWith('{') && token.trim().endsWith('}')) {
        try {
          // Cố gắng phân tích thành JSON
          final Map<String, dynamic> tokenObj = jsonDecode(token);

          // Nếu là token của Amplify Cognito
          if (tokenObj.containsKey('jwtToken')) {
            return tokenObj['jwtToken'];
          }

          // Nếu là token có claims và header
          if (tokenObj.containsKey('claims') &&
              tokenObj.containsKey('header')) {
            // Tạo JWT từ claims và header
            final header =
                base64Url.encode(utf8.encode(jsonEncode(tokenObj['header'])));
            final claims =
                base64Url.encode(utf8.encode(jsonEncode(tokenObj['claims'])));
            final signature = tokenObj['signature'] ?? '';
            return '$header.$claims.$signature';
          }

          // Kiểm tra xem token có chứa sub không - đây có thể là token ID
          if (tokenObj.containsKey('sub')) {
            // Đây có thể là token ID được parse thành JSON, chúng ta cần chuyển lại thành chuỗi
            return token;
          }
        } catch (e) {
          print("Lỗi khi parse token JSON: $e");
        }
      } else if (token.contains('.')) {
        // Kiểm tra nếu token có dạng của JWT (header.payload.signature)
        print("Token có dạng JWT standard");
        return token;
      }
      return token;
    } catch (e) {
      print("Lỗi trong quá trình xử lý token: $e");
      return token;
    }
  }

  Future<void> savePlayer(UserModel player) async {
    try {
      if (!Hive.isBoxOpen(USER_BOX)) {
        await Hive.openBox<UserModel>(USER_BOX);
      }

      final box = await Hive.openBox<UserModel>(USER_BOX);
      await box.put('currentPlayer', player);
      print("Player saved successfully: ${player.username}");
    } catch (e) {
      print("Error saving player to Hive: $e");
      throw Exception('Error saving player data: $e');
    }
  }

  Future<UserModel?> getPlayer() async {
    try {
      // Lấy token từ AmplifyAuthService
      final amplifyAuthService = AmplifyAuthService();
      final accessToken = await amplifyAuthService.getAccessToken();
      final idToken = await amplifyAuthService.getIdToken();

      if (accessToken == null || idToken == null) {
        print("Không tìm thấy token đăng nhập");
        return null;
      }

      // Lấy thông tin người dùng từ API
      final response = await http.get(
        Uri.parse(getUserApiUrl),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(jsonDecode(response.body));
        // Lưu vào cache để sử dụng sau này
        await savePlayer(user);
        return user;
      } else {
        print(
            "Lỗi khi lấy thông tin người dùng từ API: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi khi lấy thông tin người dùng: $e");
      return null;
    }
  }

  // Xóa thông tin người dùng - hữu ích khi đăng xuất
  Future<void> clearUserData() async {
    try {
      // Đảm bảo mở box, nếu chưa mở
      if (!Hive.isBoxOpen(USER_BOX)) {
        await Hive.openBox<UserModel>(USER_BOX);
      }

      final box = await Hive.openBox<UserModel>(USER_BOX);
      await box.delete('currentPlayer');
      await box.close(); // Đóng box sau khi xóa
      print("User data cleared completely");

      // Đảm bảo rằng khi chúng ta truy cập lại thì sẽ nhận được null
      if (Hive.isBoxOpen(USER_BOX)) {
        await Hive.box<UserModel>(USER_BOX).close();
      }
    } catch (e) {
      print("Error clearing user data: $e");
    }
  }
}

void main() async {
  const String accessToken =
      "eyJraWQiOiJkRXlGcVFoZUNBQnlOVzlpRWFIdFpKUUM0XC9OZXJrbU9aQUJWYzJpcHdUTT0iLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhOThlMzQxOC1iMDkxLTcwNzMtZGNhYS1mMGQ0ZmFiNGFjMTciLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAuYXAtc291dGhlYXN0LTIuYW1hem9uYXdzLmNvbVwvYXAtc291dGhlYXN0LTJfYm5rSExrNEl5IiwidmVyc2lvbiI6MiwiY2xpZW50X2lkIjoiYTc0Mmtpa2ludWdydW1oMTgzbWhqYTduZiIsIm9yaWdpbl9qdGkiOiIyYzJjN2FmZC1mODA0LTQxZTEtOGNiOC1mMmZlMGUwYjQ2MzMiLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6InBob25lIG9wZW5pZCBwcm9maWxlIGVtYWlsIiwiYXV0aF90aW1lIjoxNzQzNzY2OTgwLCJleHAiOjE3NDM4NTMzODAsImlhdCI6MTc0Mzc2Njk4MCwianRpIjoiZGFiMjBjMjYtMmFkNy00YWI4LWIxZjYtZTY0OTVjZjdlYTJmIiwidXNlcm5hbWUiOiJ0ZXN0dXNlcjIifQ.IYqSY0iSqhNSMzsoffxC8IsGZrqD67f2ScCeEhjwZlV2iI_yqEUOqFcIJKKwjfPO3x5Bp_83Sx5qbuYkonjgpTw4YUQH3ZO0Vgw0FlzZyIizDm2RuMb0Bchp9Ay83WGdBSoIsuMGruyRwUkOreNo5xCZnP9gQgPw8Jglanr7q_Eh-Xv6iwxeCX1ThHI-hozcKtAIB-sBrbuUcVUWnXHyCpvbLX9ArlGUOk21Sgz0Qs9sOjnivlqM9SiOYZYo25s7nyltJHngmlb1piyBni83Ts0hKWtJDSaKmBEezXWoN3qGpzVcfYDCNdTSI8FeXr1y1szSzsIGuNSVbKBzxndL5g";
  const String idToken =
      "eyJraWQiOiJcL3I1OU5BYWtWakc0VWtwaFlFcHNlSHZ0bThkaDQyYlJPMFprcU5IV1Uxaz0iLCJhbGciOiJSUzI1NiJ9.eyJhdF9oYXNoIjoiUWNPUjVtWXJRczNxcTM0ZGtXQTY3QSIsInN1YiI6ImE5OGUzNDE4LWIwOTEtNzA3My1kY2FhLWYwZDRmYWI0YWMxNyIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX2Jua0hMazRJeSIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjIiLCJvcmlnaW5fanRpIjoiMmMyYzdhZmQtZjgwNC00MWUxLThjYjgtZjJmZTBlMGI0NjMzIiwiYXVkIjoiYTc0Mmtpa2ludWdydW1oMTgzbWhqYTduZiIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzQzNzY2OTgwLCJleHAiOjE3NDM4NTMzODAsImlhdCI6MTc0Mzc2Njk4MCwianRpIjoiOTllN2E0NzAtMDEwZC00ZTE3LWI2Y2ItNmEyNWE3YzAyZjI4IiwiZW1haWwiOiJ0ZXN0dXNlcjJAZ21haWwuY29tIn0.xs0v7orUyWKHnvO9q7WlB2_wrmcH6FV5VEt9sijdODWLAFgdsADkdn11IZI9wnj_lsQm4-669o7A7Fc8fe5xpALuQGvFVl_bPf_7cGi0M0jEyt51zVnyRgB8EiFSm727_DRDskFQrnYxuicVbnr3vkzP1JFD6YRipjutwa_gG3B1xdVsgl280N0p9x1l26TdrhUAP_RRLjZSWmyk0bSWRS_V7utwPnTmOrzQjp25wSwgL6TLkYyCEEfrsqqXT9v3oWiSfu6D-fnnAX0jUcKW367DwTbHTRWhrvS02HpJFR_RfnTos_JCln0NFr6Lrac9NpV0u9MVkKKm_PfM7Fd4MQ";

  final userService = UserService();
  await userService.saveSelfUserInfo(accessToken, idToken);

  UserModel? player = await userService.getPlayer();
}
