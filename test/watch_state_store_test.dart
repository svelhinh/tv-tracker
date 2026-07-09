import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tv_tracker/features/tracker/data/watch_state_store.dart';
import 'package:tv_tracker/features/tracker/domain/episode_key.dart';
import 'package:tv_tracker/features/tracker/domain/watch_state_delta.dart';

void main() {
  group('WatchStateStore', () {
    late WatchStateStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = WatchStateStore();
    });

    test('persists and reloads watch deltas', () async {
      final delta = WatchStateDelta(
        added: {EpisodeKey(season: 2, episode: 1)},
        removed: {EpisodeKey(season: 1, episode: 3)},
      );

      await store.save('show-1', delta);
      final loaded = await store.loadAll();

      expect(loaded['show-1']?.added, delta.added);
      expect(loaded['show-1']?.removed, delta.removed);
    });

    test('removes empty delta from storage', () async {
      await store.save('show-1', const WatchStateDelta());
      final loaded = await store.loadAll();

      expect(loaded.containsKey('show-1'), isFalse);
    });
  });
}
