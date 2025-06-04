import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activematch_model.dart';
import '../constants/constants.dart';

class SpectateService {
  final String _baseUrl = ApiConstants.baseUrl;

  /// Lấy danh sách trận đấu đang diễn ra để theo dõi
  /// [userIdToken] - Token JWT cho xác thực
  /// [limit] - Số lượng kết quả muốn lấy (mặc định 5)
  /// [gameMode] - Chế độ chơi muốn lọc (tùy chọn)
  Future<ActiveResponse> getActiveMatches(String userIdToken,
      {int limit = 5, String? gameMode}) async {
    try {
      String url = '$_baseUrl/activeMatches?limit=$limit';
      if (gameMode != null) {
        url += '&gameMode=$gameMode';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $userIdToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ActiveResponse.fromJson(data);
      } else {
        throw Exception('Failed to load active matches');
      }
    } catch (e) {
      throw Exception('Error getting active matches: $e');
    }
  }
}
