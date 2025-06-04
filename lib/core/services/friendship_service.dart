import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/friendship_model.dart';
import '../constants/constants.dart';

class FriendshipService {
  final String _getFriendUrl = ApiConstants.getFriendUrl;
  final String _friendUrl = ApiConstants.friendUrl;

  /// Lấy danh sách bạn bè
  /// [userIdToken] - Token JWT cho xác thực

  Future<FriendshipModel> getFriendshipList(String userIdToken) async {
    try {
      final response = await http.get(
        Uri.parse(_getFriendUrl),
        headers: {'Authorization': 'Bearer $userIdToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return FriendshipModel.fromJson(data);
      } else {
        throw Exception('Failed to load friendship list');
      }
    } catch (e) {
      throw Exception('Error getting friendship list: $e');
    }
  }

  Future<int> addFriend(String userIdToken, String friendId) async {
    try {
      final response = await http.post(
        Uri.parse('$_friendUrl/$friendId/add'),
        headers: {'Authorization': 'Bearer $userIdToken'},
      );
      return response.statusCode;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> acceptFriendRequest(String userIdToken, String friendId) async {
    final response = await http.post(
      Uri.parse('$_friendUrl/$friendId/accept'),
      headers: {'Authorization': 'Bearer $userIdToken'},
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> rejectFriendRequest(String userIdToken, String friendId) async {
    final response = await http.post(
      Uri.parse('$_friendUrl/$friendId/reject'),
      headers: {'Authorization': 'Bearer $userIdToken'},
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<FriendshipRequestModel> getFriendshipRequest(
      String userIdToken) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/friendRequests/received'),
      headers: {'Authorization': 'Bearer $userIdToken'},
    );
    if (response.statusCode == 200) {
      return FriendshipRequestModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load friendship request');
    }
  }
}
