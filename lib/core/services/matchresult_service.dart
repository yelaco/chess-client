import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/matchresults_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MatchResultService {
  static const String _boxName = 'matchResultsBox';
  static Box<MatchResultsModel>? _box;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(MatchResultsModelAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(MatchResultItemAdapter());
      }
      _box = await Hive.openBox<MatchResultsModel>(_boxName);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing MatchResultService: $e');
      rethrow;
    }
  }

  Future<MatchResultsModel> getMatchResults(
      String userId, String idToken) async {
    try {
      // Lấy từ API
      final response = await http.get(
        Uri.parse(ApiConstants.matchResult),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final results = MatchResultsModel.fromJson(data);

        // Cache kết quả mới
        await _cacheMatchResults(userId, results);

        return results;
      } else {
        throw Exception('Không thể lấy kết quả trận đấu');
      }
    } catch (e) {
      print('Lỗi khi lấy kết quả trận đấu: $e');
      throw Exception('Lỗi khi lấy kết quả trận đấu: $e');
    }
  }

  // Cache Methods
  Future<void> _cacheMatchResults(
      String userId, MatchResultsModel results) async {
    if (!_isInitialized) {
      throw Exception('MatchResultService chưa được khởi tạo');
    }
    try {
      await _box?.put(userId, results);
    } catch (e) {
      print('Error caching match results: $e');
      rethrow;
    }
  }

  Future<MatchResultsModel?> _getCachedMatchResults(String userId) async {
    if (!_isInitialized) {
      throw Exception('MatchResultService chưa được khởi tạo');
    }
    try {
      return _box?.get(userId);
    } catch (e) {
      print('Error getting cached match results: $e');
      return null;
    }
  }

  Future<bool> hasCachedResults(String userId) async {
    if (!_isInitialized) {
      throw Exception('MatchResultService chưa được khởi tạo');
    }
    try {
      return _box?.containsKey(userId) ?? false;
    } catch (e) {
      print('Error checking cached results: $e');
      return false;
    }
  }

  Future<void> clearCache(String userId) async {
    if (!_isInitialized) {
      throw Exception('MatchResultService chưa được khởi tạo');
    }
    try {
      await _box?.delete(userId);
    } catch (e) {
      print('Error clearing cache: $e');
      rethrow;
    }
  }

  Future<void> clearAllCache() async {
    if (!_isInitialized) {
      throw Exception('MatchResultService chưa được khởi tạo');
    }
    try {
      await _box?.clear();
    } catch (e) {
      print('Error clearing all cache: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (!_isInitialized) return;
    try {
      await _box?.close();
      _isInitialized = false;
    } catch (e) {
      print('Error closing MatchResultService: $e');
      rethrow;
    }
  }

  Future<void> reset() async {
    try {
      await close();
      await Hive.deleteBoxFromDisk(_boxName);
      _isInitialized = false;
    } catch (e) {
      print('Error resetting MatchResultService: $e');
      rethrow;
    }
  }
}
