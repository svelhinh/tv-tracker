class EnvValues {
  static final Map<String, String> _values = {};

  static void setAll(Map<String, String> values) {
    for (final entry in values.entries) {
      final value = entry.value.trim();
      if (value.isNotEmpty) {
        _values[entry.key] = value;
      }
    }
  }

  static String get(String key) {
    final value = _values[key]?.trim();
    if (value != null && value.isNotEmpty) return value;

    if (key == 'TMDB_API_KEY') {
      return const String.fromEnvironment('TMDB_API_KEY');
    }
    return '';
  }
}
