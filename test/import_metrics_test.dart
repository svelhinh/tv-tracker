import 'package:flutter_test/flutter_test.dart';
import 'package:tv_tracker/features/import/application/import_metrics_calculator.dart';
import 'package:tv_tracker/features/import/data/tv_time_gdpr_parser.dart';
import 'package:tv_tracker/features/import/domain/import_metrics.dart';

void main() {
  group('ImportMetricsCalculator', () {
    test('estimates storage from parsed export', () {
      const followedCsv = '''
notification_type,archived,tv_show_name,created_at,active,diffusion,folder_id,notification_offset,user_id,tv_show_id,updated_at
2,0,Attack on Titan,2022-01-01 00:00:00,1,original,,-10,1,267440,2022-01-01 00:00:00
2,0,Breaking Bad,2022-01-01 00:00:00,1,original,,-10,1,123,2022-01-01 00:00:00
''';

      const v2Csv = '''
ep_id,gsi,series_name,season_number,episode_number,s_id,key,user_id,created_at,episode_id
8068625,watch-episode-1,Attack on Titan,4,3,267440,key,1,2021-01-11 02:05:01,8068625
8068626,watch-episode-2,Breaking Bad,1,1,123,key,1,2021-01-11 02:05:01,8068626
''';

      final result = TvTimeGdprParser.parseFromFiles({
        TvTimeGdprParser.followedShowsFile: followedCsv,
        TvTimeGdprParser.trackingRecordsV2File: v2Csv,
      });

      final metrics = ImportMetricsCalculator.compute(
        result: result,
        importDuration: const Duration(milliseconds: 42),
        zipSizeBytes: 1024,
      );

      expect(metrics.showCount, 2);
      expect(metrics.episodeCount, 2);
      expect(metrics.importDuration.inMilliseconds, 42);
      expect(metrics.zipSizeBytes, 1024);
      expect(metrics.tmdbCallsDuringImport, 0);
      expect(metrics.estimatedTmdbCallsForFullMatch, 2);
      expect(metrics.estimatedTmdbCallsForPosters, 0);
      expect(metrics.estimatedTmdbCallsFirstSession, 2);
      expect(metrics.estimatedStorageBytes, greaterThan(100));
    });

    test('extrapolates for scale user counts', () {
      const metrics = ImportMetrics(
        importDuration: Duration(seconds: 2),
        zipSizeBytes: 500000,
        showCount: 100,
        episodeCount: 5000,
        estimatedStorageBytes: 1024 * 1024,
        tmdbCallsDuringImport: 0,
        estimatedTmdbCallsForFullMatch: 100,
        estimatedTmdbCallsForPosters: 100,
      );

      final estimates = metrics.extrapolate();
      expect(estimates, hasLength(3));
      expect(estimates[0].userCount, 1000);
      expect(estimates[0].totalShows, 100000);
      expect(estimates[0].totalEpisodes, 5000000);
      expect(estimates[0].totalTmdbCallsFirstSession, 100000);
      expect(estimates[2].userCount, 100000);
      expect(estimates[2].totalStorageBytes, 1024 * 1024 * 100000);
    });
  });
}
