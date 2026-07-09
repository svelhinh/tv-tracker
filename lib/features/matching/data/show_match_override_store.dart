import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/show_match_override.dart';

class ShowMatchOverrideStore {
  static const storageKey = 'show_match_overrides_v1';

  Future<Map<String, ShowMatchOverride>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (tvTimeShowId, value) => MapEntry(
        tvTimeShowId,
        ShowMatchOverride.fromJson(
          tvTimeShowId,
          value as Map<String, dynamic>,
        ),
      ),
    );
  }

  Future<void> save(ShowMatchOverride override) async {
    final all = await loadAll();
    all[override.tvTimeShowId] = override;
    await _persist(all);
  }

  Future<void> _persist(Map<String, ShowMatchOverride> overrides) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      overrides.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(storageKey, encoded);
  }
}
