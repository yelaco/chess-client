import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/leaderboard_model.dart';
import 'package:flutter/material.dart';

class LeaderboardService {
  // URL API lấy bảng xếp hạng
  final String _leaderboardApiUrl =
      'https://ky9s1s2sla.execute-api.ap-southeast-2.amazonaws.com/dev/leaderboard';

  /// Lấy danh sách người chơi có xếp hạng cao nhất
  /// [idToken] - Token JWT cho xác thực
  /// [limit] - Số lượng người chơi muốn lấy (mặc định 100)
  /// [offset] - Vị trí bắt đầu lấy dữ liệu (mặc định 0)
  Future<LeaderboardModel> getLeaderboard(String idToken,
      {int limit = 100, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$_leaderboardApiUrl?limit=$limit&offset=$offset'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return LeaderboardModel.fromJson(data);
      } else {
        print("API trả về lỗi [${response.statusCode}]: ${response.body}");
        throw Exception(
            'Không thể lấy dữ liệu bảng xếp hạng: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi khi lấy bảng xếp hạng: $e");
      throw Exception('Lỗi khi lấy bảng xếp hạng');
    }
  }

  /// Lấy thông tin xếp hạng của người dùng hiện tại
  Future<LeaderboardEntry?> getCurrentUserRanking(
      String idToken, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_leaderboardApiUrl/player/$userId'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LeaderboardEntry.fromJson(data);
      } else if (response.statusCode == 404) {
        // Người dùng chưa có xếp hạng
        return null;
      } else {
        print("API trả về lỗi [${response.statusCode}]: ${response.body}");
        throw Exception(
            'Không thể lấy thông tin xếp hạng: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi khi lấy thông tin xếp hạng: $e");
      throw Exception('Lỗi khi lấy thông tin xếp hạng');
    }
  }
}
