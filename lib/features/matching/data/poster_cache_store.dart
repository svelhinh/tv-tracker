import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PosterCacheStore {
  static const storageKey = 'poster_cache_v1';

  Future<Map<String, String>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> saveAll(Map<String, String> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(cache));
  }
}
