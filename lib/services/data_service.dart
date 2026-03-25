import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing data fetching with caching and error handling
class DataService {
  static const Duration defaultCacheDuration = Duration(hours: 1);
  static const String _cachePrefix = 'cache_';
  static const String _cacheTimePrefix = 'cache_time_';

  /// Fetches data with automatic caching
  /// [cacheKey] - unique key for caching
  /// [fetcher] - async function that returns the data
  /// [cacheDuration] - how long to keep data cached (default 1 hour)
  /// [useCache] - whether to use cached data if available
  static Future<T?> fetchWithCache<T>(
    String cacheKey,
    Future<T?> Function() fetcher, {
    Duration cacheDuration = defaultCacheDuration,
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache) {
      final cachedData = await _getFromCache<T>(cacheKey);
      if (cachedData != null) {
        final cachedTime = await _getCacheTime(cacheKey);
        if (cachedTime != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - cachedTime < cacheDuration.inMilliseconds) {
            return cachedData;
          }
        }
      }
    }

    // Fetch fresh data
    try {
      final freshData = await fetcher();
      if (freshData != null) {
        await _saveToCache<T>(cacheKey, freshData);
      }
      return freshData;
    } catch (e) {
      // If fetch fails, try to return cached data even if expired
      return await _getFromCache<T>(cacheKey);
    }
  }

  /// Manually save data to cache
  static Future<void> saveToCache<T>(String cacheKey, T data) async {
    await _saveToCache<T>(cacheKey, data);
  }

  /// Get data from cache without checking expiration
  static Future<T?> getFromCache<T>(String cacheKey) async {
    return _getFromCache<T>(cacheKey);
  }

  /// Clear specific cache
  static Future<void> clearCache(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachePrefix + cacheKey);
    await prefs.remove(_cacheTimePrefix + cacheKey);
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimePrefix)) {
        await prefs.remove(key);
      }
    }
  }

  // Private helpers
  static Future<T?> _getFromCache<T>(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachePrefix + cacheKey);
      if (cached == null) return null;

      // Handle different types
      if (T == String) {
        return cached as T;
      } else if (T == List<Map<String, dynamic>>) {
        return json.decode(cached) as T;
      } else if (T == Map<String, dynamic>) {
        return json.decode(cached) as T;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _saveToCache<T>(String cacheKey, T data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? encoded;

      if (T == String) {
        encoded = data as String;
      } else if (T == List<Map<String, dynamic>>) {
        encoded = json.encode(data);
      } else if (T == Map<String, dynamic>) {
        encoded = json.encode(data);
      }

      if (encoded != null) {
        await prefs.setString(_cachePrefix + cacheKey, encoded);
        await prefs.setInt(
          _cacheTimePrefix + cacheKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      // Silently fail cache save
    }
  }

  static Future<int?> _getCacheTime(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheTimePrefix + cacheKey);
  }

  /// Check internet connectivity
  static Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
