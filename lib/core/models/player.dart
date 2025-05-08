import './user.dart';
import '../services/user_service.dart';
import '../services/amplify_auth_service.dart';

class Player {
  final UserModel user;
  final int rating;
  final List<int> newRatings;
  final double rd;
  final List<double> newRDs;
  bool isConnect;

  Player(
      {required this.user,
      required this.rating,
      this.rd = 0.0,
      this.newRatings = const [],
      this.newRDs = const [],
      this.isConnect = false});

  static Future<Player> fromJson(Map<String, dynamic> json) async {
    final userService = UserService();
    final amplifyAuthService = AmplifyAuthService();

    try {
      final storedIdToken = await amplifyAuthService.getIdToken();
      final user = await userService.getUserInfo(json['id'], storedIdToken!);

      return Player(
        user: user,
        rating: json['rating'],
        rd: (json['rd'] != null)
            ? double.tryParse(json['rd'].toString()) ?? 0.0
            : 0.0,
        newRatings: List<int>.from(json['newRatings'] ?? []),
        newRDs: List<double>.from(json['newRDs'] ?? []),
      );
    } catch (e) {
      throw Exception('Error creating Player: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': user.id,
      'rating': rating,
      'rd': rd,
      'newRatings': newRatings,
      'newRDs': newRDs,
    };
  }
}

class PlayerStateModel {
  final String id;
  final bool status; // true nếu CONNECTED, false nếu DISCONNECTED

  PlayerStateModel({
    required this.id,
    required this.status,
  });

  // Chuyển từ JSON thành PlayerStateModel
  factory PlayerStateModel.fromJson(Map<String, dynamic> json) {
    return PlayerStateModel(
      id: json['id'] as String,
      status: (json['status'] as String).toUpperCase() == "CONNECTED",
    );
  }

  // Chuyển từ PlayerStateModel thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
    };
  }
}
