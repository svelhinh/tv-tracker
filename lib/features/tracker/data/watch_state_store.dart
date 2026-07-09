import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/watch_state_delta.dart';

class WatchStateStore {
  static const storageKey = 'tracker_watch_state_v1';

  Future<Map<String, WatchStateDelta>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (showId, value) => MapEntry(
        showId,
        WatchStateDelta.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  Future<void> save(String showId, WatchStateDelta delta) async {
    final all = await loadAll();
    if (delta.added.isEmpty && delta.removed.isEmpty) {
      all.remove(showId);
    } else {
      all[showId] = delta;
    }
    await _persist(all);
  }

  Future<void> _persist(Map<String, WatchStateDelta> states) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      states.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(storageKey, encoded);
  }
}
