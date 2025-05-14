import 'dart:convert';
import 'package:http/http.dart' as http;

class UserRating {
  final String userId;
  final String username;
  final double rating;

  UserRating({
    required this.userId,
    required this.username,
    required this.rating,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UserRatingsResponse {
  final List<UserRating> items;
  final String? nextPageToken;

  UserRatingsResponse({
    required this.items,
    this.nextPageToken,
  });

  factory UserRatingsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] ?? [];

    return UserRatingsResponse(
      items: itemsJson.map((item) => UserRating.fromJson(item)).toList(),
      nextPageToken: json['nextPageToken'],
    );
  }
}

class UserRatingsService {
  final String _baseUrl =
      'https://ky9s1s2sla.execute-api.ap-southeast-2.amazonaws.com/dev';

  /// Lấy danh sách xếp hạng người dùng
  /// [userIdToken] - Token JWT cho xác thực
  /// [limit] - Số lượng kết quả muốn lấy (mặc định 5)
  Future<UserRatingsResponse> getUserRatings(String userIdToken,
      {int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/userRatings?limit=$limit'),
        headers: {'Authorization': 'Bearer $userIdToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserRatingsResponse.fromJson(data);
      } else {
        print("API trả về lỗi [${response.statusCode}]: ${response.body}");
        throw Exception(
            'Không thể lấy dữ liệu xếp hạng người dùng: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi khi lấy xếp hạng người dùng: $e");
      throw Exception('Lỗi khi lấy xếp hạng người dùng');
    }
  }
}
