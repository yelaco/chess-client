import 'package:hive_flutter/hive_flutter.dart';
import '../models/matchresults_model.dart';

class MatchResultsCacheService {
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
      print('Error initializing MatchResultsCacheService: $e');
      rethrow;
    }
  }

  Future<void> cacheMatchResults(
      String userId, MatchResultsModel results) async {
    if (!_isInitialized) {
      throw Exception('MatchResultsCacheService chưa được khởi tạo');
    }
    try {
      await _box?.put(userId, results);
    } catch (e) {
      print('Error caching match results for user $userId: $e');
      rethrow;
    }
  }

  Future<MatchResultsModel?> getCachedMatchResults(String userId) async {
    if (!_isInitialized) {
      throw Exception('MatchResultsCacheService chưa được khởi tạo');
    }
    try {
      return _box?.get(userId);
    } catch (e) {
      print('Error getting cached match results for user $userId: $e');
      return null;
    }
  }

  Future<bool> hasCachedResults(String userId) async {
    if (!_isInitialized) {
      throw Exception('MatchResultsCacheService chưa được khởi tạo');
    }
    try {
      return _box?.containsKey(userId) ?? false;
    } catch (e) {
      print('Error checking cached results for user $userId: $e');
      return false;
    }
  }

  Future<void> updateMatchResults(
      String userId, MatchResultsModel results) async {
    if (!_isInitialized) {
      throw Exception('MatchResultsCacheService chưa được khởi tạo');
    }
    try {
      final existingResults = await getCachedMatchResults(userId);
      if (existingResults != null) {
        final updatedItems = [...existingResults.items, ...results.items];
        await _box?.put(userId, MatchResultsModel(items: updatedItems));
      } else {
        await cacheMatchResults(userId, results);
      }
    } catch (e) {
      print('Error updating match results for user $userId: $e');
      rethrow;
    }
  }

  Future<void> clearCache(String userId) async {
    if (!_isInitialized) {
      throw Exception('MatchResultsCacheService chưa được khởi tạo');
    }
    try {
      await _box?.delete(userId);
    } catch (e) {
      print('Error clearing cache for user $userId: $e');
      rethrow;
    }
  }

  Future<void> clearAllCache() async {
    if (!_isInitialized) {
      throw Exception('MatchResultsCacheService chưa được khởi tạo');
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
      print('Error closing MatchResultsCacheService: $e');
      rethrow;
    }
  }

  Future<void> reset() async {
    try {
      await close();
      await Hive.deleteBoxFromDisk(_boxName);
      _isInitialized = false;
    } catch (e) {
      print('Error resetting MatchResultsCacheService: $e');
      rethrow;
    }
  }
}
