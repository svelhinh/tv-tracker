import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tv_tracker/features/matching/data/poster_cache_store.dart';

void main() {
  group('PosterCacheStore', () {
    late PosterCacheStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = PosterCacheStore();
    });

    test('persists and reloads poster paths', () async {
      await store.saveAll({'show-1': '/abc.jpg', 'show-2': ''});
      final loaded = await store.loadAll();

      expect(loaded['show-1'], '/abc.jpg');
      expect(loaded['show-2'], '');
    });
  });
}
