import 'package:flutter_slchess/core/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../constants/constants.dart';
import '../models/puzzle_model.dart';
import '../services/user_service.dart';
import 'dart:convert';

// Lớp để lưu trữ Profile trong bộ nhớ thay vì sử dụng Hive
class ProfileStorage {
  // Singleton
  static final ProfileStorage _instance = ProfileStorage._internal();
  factory ProfileStorage() => _instance;
  ProfileStorage._internal();

  // Map để lưu profile theo userId
  final Map<String, Map<String, dynamic>> _profiles = {};

  // Lưu profile
  void saveProfile(String userId, int rating, {int dailyCount = 0}) {
    _profiles[userId] = {
      'userId': userId,
      'rating': rating,
      'dailyPuzzleCount': dailyCount,
      'lastPlayDate': DateTime.now().toIso8601String(),
    };
    print(
        "Đã lưu profile vào bộ nhớ: userId=$userId, rating=$rating, count=$dailyCount");
  }

  // Lấy profile
  PuzzleProfile? getProfile(String userId) {
    final profileMap = _profiles[userId];
    if (profileMap == null) return null;

    return PuzzleProfile(
      userId: profileMap['userId'],
      rating: profileMap['rating'],
      dailyPuzzleCount: profileMap['dailyPuzzleCount'],
      lastPlayDate: DateTime.tryParse(profileMap['lastPlayDate']),
    );
  }

  // Xóa profile
  void deleteProfile(String userId) {
    _profiles.remove(userId);
    print("Đã xóa profile từ bộ nhớ: $userId");
  }

  // Xóa tất cả profile
  void clearAllProfiles() {
    _profiles.clear();
    print("Đã xóa tất cả profile từ bộ nhớ");
  }
}

class PuzzleService {
  static String getPuzzlesUrlApi = ApiConstants.getPulzzesUrl;
  static String getPuzzleUrlApi = ApiConstants.getPulzzeUrl;
  static String getPuzzleProfileUrlApi = "${ApiConstants.getPulzzeUrl}/profile";

  // Sử dụng ProfileStorage
  final ProfileStorage _profileStorage = ProfileStorage();

  Future<Puzzles> getPuzzles(String idToken, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse("$getPuzzlesUrlApi?limit=$limit"),
        headers: {'Authorization': idToken},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final puzzles = Puzzles.fromJson(responseData);

        // ✅ Lưu cache sau khi fetch
        await _cachePuzzles(puzzles.puzzles);

        return puzzles;
      } else {
        throw Exception('Không thể lấy puzzles: ${response.statusCode}');
      }
    } catch (error) {
      print("Lỗi khi gọi API, thử lấy từ cache...");

      // ✅ Nếu lỗi, load từ cache
      final cached = await _getCachedPuzzles();
      if (cached.isNotEmpty) {
        return Puzzles(puzzles: cached);
      }

      throw Exception('Không thể lấy puzzle: $error');
    }
  }

  // 🧠 Cache puzzles
  Future<void> _cachePuzzles(List<Puzzle> puzzles) async {
    final box = await Hive.openBox<Puzzle>('puzzleBox');
    await box.clear(); // optional: xoá cũ
    for (var puzzle in puzzles) {
      await box.put(puzzle.puzzleId, puzzle);
    }
  }

  // 📦 Lấy puzzle từ cache nếu cần
  Future<List<Puzzle>> _getCachedPuzzles() async {
    final box = await Hive.openBox<Puzzle>('puzzleBox');
    return box.values.toList();
  }

  // 🔑 Lấy 1 puzzle từ cache, nếu không có thì gọi API và tạo lại cache
  Future<Puzzles> getPuzzleFromCacheOrApi(String idToken) async {
    try {
      // Kiểm tra xem Hive đã được khởi tạo chưa
      if (!Hive.isBoxOpen('puzzleBox')) {
        // Đảm bảo Hive đã được khởi tạo trước khi mở box
        try {
          await Hive.openBox<Puzzle>('puzzleBox');
        } catch (e) {
          print("Lỗi khi mở Hive box: $e");
          // Nếu không thể mở box, gọi API để lấy puzzles
          return await getPuzzles(idToken);
        }
      }

      final box = await Hive.openBox<Puzzle>('puzzleBox');

      if (box.isNotEmpty) {
        final cachedPuzzles = box.values.toList();
        return Puzzles(puzzles: cachedPuzzles);
      }

      // Nếu không có trong cache, gọi API để lấy puzzles
      print("Không tìm thấy trong cache, gọi API để lấy puzzle...");
      final puzzles = await getPuzzles(idToken);
      return puzzles;
    } catch (error) {
      print("Lỗi khi lấy puzzle từ cache hoặc API: $error");
      // Thử gọi API trực tiếp nếu có lỗi với cache
      try {
        return await getPuzzles(idToken);
      } catch (apiError) {
        throw Exception('Không thể lấy puzzle: $error. Lỗi API: $apiError');
      }
    }
  }

  Future<void> deletePuzzleFromCache(Puzzle puzzle) async {
    final String puzzleId = puzzle.puzzleId;
    try {
      final box = await Hive.openBox<Puzzle>('puzzleBox');
      await box.delete(puzzleId); // Xóa puzzle theo puzzleId

      print("Puzzle với ID: $puzzleId đã bị xóa khỏi cache.");
    } catch (error) {
      print("Lỗi khi xóa puzzle khỏi cache: $error");
      throw Exception('Không thể xóa puzzle khỏi cache: $error');
    }
  }

  // Phương thức mới để kiểm tra và lưu profile một cách an toàn
  Future<void> safeStoreProfile(String userId, int rating,
      {int dailyCount = 0}) async {
    try {
      print(
          "Tạo profile mới một cách an toàn: userId=$userId, rating=$rating, count=$dailyCount");

      // Lưu vào bộ nhớ thay vì Hive
      _profileStorage.saveProfile(userId, rating, dailyCount: dailyCount);
    } catch (e) {
      print("Lỗi khi lưu profile an toàn: $e");
    }
  }

  // Lấy profile từ bộ nhớ
  Future<PuzzleProfile?> getProfileFromCache(String userId) async {
    try {
      return _profileStorage.getProfile(userId);
    } catch (e) {
      print("Lỗi khi lấy profile từ cache: $e");
      return null;
    }
  }

  // Sửa phương thức này để sử dụng phương thức lưu an toàn
  Future<PuzzleProfile> getPuzzleProfile(String idToken) async {
    try {
      final response = await http.get(
        Uri.parse(getPuzzleProfileUrlApi),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Đảm bảo tất cả các trường đều có giá trị mặc định nếu trường đó không tồn tại hoặc null
        final userId = responseData['userId'] ?? '';
        final rating = responseData['rating'] ?? 300;

        // Tạo PuzzleProfile mới để trả về
        final puzzleProfile = PuzzleProfile(
          userId: userId,
          rating: rating,
          dailyPuzzleCount: responseData['dailyPuzzleCount'] ?? 0,
          lastPlayDate: DateTime.tryParse(responseData['lastPlayDate'] ?? '') ??
              DateTime.now(),
        );

        // Lưu profile vào cache một cách an toàn
        try {
          await safeStoreProfile(userId, rating);
        } catch (e) {
          print("Lỗi khi lưu puzzle profile vào cache: $e");
        }

        return puzzleProfile;
      }
      throw Exception('Không thể lấy profile puzzle: ${response.statusCode}');
    } catch (e) {
      print("Lỗi khi lấy puzzle profile: $e");

      // Nếu có lỗi, trả về profile mặc định
      final userService = UserService();
      final user = await userService.getPlayer();
      if (user != null) {
        return PuzzleProfile(
          userId: user.id,
          rating: 300,
          dailyPuzzleCount: 0,
          lastPlayDate: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  // Sửa phương thức savePuzzleProfile để sử dụng phương thức lưu an toàn
  Future<void> savePuzzleProfile(PuzzleProfile puzzleProfile) async {
    try {
      await safeStoreProfile(puzzleProfile.userId, puzzleProfile.rating,
          dailyCount: puzzleProfile.dailyPuzzleCount ?? 0);
    } catch (e) {
      print("Lỗi khi lưu puzzle profile: $e");
    }
  }

  Future<int> getPuzzleRatingFromCache(UserModel user) async {
    try {
      final cachedProfile = await getProfileFromCache(user.id);
      if (cachedProfile != null) {
        return cachedProfile.rating;
      }
      return 0; // Trả về giá trị mặc định nếu không tìm thấy
    } catch (e) {
      print("Lỗi khi lấy puzzle rating từ cache: $e");
      return 0;
    }
  }

  Future<PuzzleProfile> getPuzzleRatingFromCacheOrAPI(String idToken) async {
    try {
      // Lấy từ API trực tiếp
      print("Fetching puzzle profile from API...");
      final apiProfile = await getPuzzleProfile(idToken);
      return apiProfile;
    } catch (error) {
      print("Error getting puzzle profile: $error");

      // Nếu có lỗi, trả về profile mặc định
      final userService = UserService();
      final user = await userService.getPlayer();
      if (user != null) {
        return PuzzleProfile(
          userId: user.id,
          rating: 300,
          dailyPuzzleCount: 0,
          lastPlayDate: DateTime.now(),
        );
      }

      throw Exception("Không thể lấy puzzle profile: $error");
    }
  }

  /// Clears all puzzle-related cached data
  /// Call this when a new user logs in
  Future<void> clearAllPuzzleCaches() async {
    try {
      // Clear puzzle profiles from memory
      _profileStorage.clearAllProfiles();

      // Clear puzzles list
      if (Hive.isBoxOpen('puzzleBox')) {
        final puzzleBox = await Hive.openBox<Puzzle>('puzzleBox');
        await puzzleBox.clear();
        print("Puzzles cache cleared");
      }
    } catch (error) {
      print("Error clearing puzzle caches: $error");
    }
  }

  Future<bool> canPlayPuzzle(String idToken) async {
    try {
      final userService = UserService();
      final user = await userService.getPlayer();
      if (user == null) {
        throw Exception("Không tìm thấy thông tin người dùng");
      }

      final puzzleProfile = await getPuzzleRatingFromCacheOrAPI(idToken);

      // Nếu user là premium, luôn cho phép chơi
      if (user.membership == Membership.premium) {
        return true;
      }

      // Kiểm tra số lần chơi trong ngày
      puzzleProfile.resetDailyCount(); // Đảm bảo reset counter nếu là ngày mới
      return puzzleProfile.dailyPuzzleCount <
          3; // Giới hạn 3 lần cho người dùng thường
    } catch (e) {
      print("Lỗi khi kiểm tra quyền chơi puzzle: $e");
      return false;
    }
  }

  Future<void> incrementPuzzleCount(String idToken) async {
    try {
      final userService = UserService();
      final user = await userService.getPlayer();
      if (user == null) {
        throw Exception("Không tìm thấy thông tin người dùng");
      }

      try {
        // Lấy profile từ API hoặc cache
        final puzzleProfile = await getPuzzleRatingFromCacheOrAPI(idToken);

        // Tăng số lần chơi puzzle và lưu lại
        final currentCount = puzzleProfile.dailyPuzzleCount ?? 0;
        await safeStoreProfile(puzzleProfile.userId, puzzleProfile.rating,
            dailyCount: currentCount + 1);

        print("Đã tăng số lần chơi puzzle: ${currentCount + 1}");
      } catch (e) {
        // Nếu có lỗi, tạo profile mới với giá trị mặc định
        await safeStoreProfile(user.id, 300, dailyCount: 1);
        print("Đã tạo profile mới với số lần chơi puzzle: 1");
      }
    } catch (e) {
      print("Lỗi khi cập nhật số lần chơi puzzle: $e");
    }
  }

  Future<int?> solvedPuzzle(String idToken, Puzzle puzzle) async {
    try {
      final solvedPuzzleUrlApi = "$getPuzzleUrlApi/${puzzle.puzzleId}/solved";

      final response = await http.post(
        Uri.parse(solvedPuzzleUrlApi),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      print("Phản hồi từ API khi giải puzzle: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newRating = responseData['newRating'];
        print("Điểm Puzzle Rating mới của bạn sau khi giải: $newRating");

        // Get the current user
        final userService = UserService();
        final user = await userService.getPlayer();

        if (user != null) {
          // Lưu trực tiếp profile mới với rating mới
          await safeStoreProfile(user.id, newRating);
          print(
              "Đã cập nhật puzzle profile: userId=${user.id}, rating=$newRating");

          // Xóa puzzle đã giải khỏi cache
          await deletePuzzleFromCache(puzzle);

          // Trả về rating mới
          return newRating;
        }
      } else {
        print(
            "Lỗi khi gọi API solved puzzle: ${response.statusCode}, ${response.body}");
        throw Exception(
            'Không thể đánh dấu puzzle đã giải: ${response.statusCode}');
      }

      print("Đã đánh dấu puzzle ${puzzle.puzzleId} là đã giải thành công");
      return null;
    } catch (error) {
      print("Lỗi khi đánh dấu puzzle đã giải: $error");
      throw Exception('Không thể đánh dấu puzzle đã giải: $error');
    }
  }

  Future<void> updatePuzzleRating(
      int newRating, PuzzleProfile puzzleProfile) async {
    try {
      await safeStoreProfile(puzzleProfile.userId, newRating,
          dailyCount: puzzleProfile.dailyPuzzleCount ?? 0);
      print(
          "Profile rating đã được cập nhật: userId=${puzzleProfile.userId}, rating=$newRating");
    } catch (e) {
      print("Lỗi khi cập nhật puzzle rating: $e");
    }
  }

  Future<void> deletePuzzleProfile(String userId) async {
    try {
      _profileStorage.deleteProfile(userId);
    } catch (e) {
      print("Lỗi khi xóa puzzle profile: $e");
    }
  }
}
