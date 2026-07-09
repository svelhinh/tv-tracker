import 'package:flutter_test/flutter_test.dart';
import 'package:tv_tracker/features/import/data/tv_time_gdpr_parser.dart';

void main() {
  group('TvTimeGdprParser', () {
    test('parse shows from followed_tv_show.csv', () {
      const csv = '''
notification_type,archived,tv_show_name,created_at,active,diffusion,folder_id,notification_offset,user_id,tv_show_id,updated_at
2,0,Star Trek: The Next Generation,2022-04-27 01:49:07,1,original,,-10,12589638,71470,2022-04-27 01:53:21
2,0,Lost,2019-01-01 00:00:00,0,original,,-10,12589638,73739,2019-01-01 00:00:00
''';

      const userData = '''
user_id,tv_show_id,is_followed,is_favorited,nb_episodes_seen,tv_show_name
12589638,73739,1,0,65,Lost
''';

      final result = TvTimeGdprParser.parseFromFiles({
        TvTimeGdprParser.followedShowsFile: csv,
        TvTimeGdprParser.userShowDataFile: userData,
      });

      expect(result.shows, hasLength(2));
      expect(result.shows.first.name, 'Lost');
      expect(result.shows.first.episodesSeenCount, 65);

      final lost = result.shows.firstWhere((show) => show.tvTimeId == '73739');
      expect(lost.isActive, isFalse);
    });

    test('parse watched episodes from tracking v2 rows', () {
      const v2 = '''
ep_id,gsi,series_name,season_number,episode_number,s_id,key,user_id,created_at,episode_id
8068625,watch-episode-1610330701,Attack on Titan,4,3,267440,rewatch-episode-abc,12589638,2021-01-11 02:05:01,8068625
,,Sabikui Bisco,,,398387,user-series-xyz,12589638,2022-01-12 16:29:57,,
''';

      final result = TvTimeGdprParser.parseFromFiles({
        TvTimeGdprParser.trackingRecordsV2File: v2,
      });

      expect(result.watchedEpisodes, hasLength(1));
      expect(result.watchedEpisodes.first.showName, 'Attack on Titan');
      expect(result.watchedEpisodes.first.seasonNumber, 4);
      expect(result.watchedEpisodes.first.episodeNumber, 3);
      expect(result.watchedEpisodes.first.episodeId, '8068625');
    });

    test('parse watched episodes from tracking v1 watch rows', () {
      const v1 = '''
type-uuid-n,created_at,watch_count,series_name,type,user_id,series_id,uuid,updated_at,watches,release_date_range_key,release_date,entity_type,follow_date_range_key,runtime,movie_name,alpha_range_key,rewatch_count,episode_number,series_uuid,episode_id,season_number,watch_date,watched_episode_range_key,total_movies_runtime,total_series_runtime,country,unitarian,watch_date_range_key,bulk_type
watch-abc,2021-07-11 13:14:10,,My Hero Academia,watch,12589638,305074,009fb7d8,2021-07-11 13:14:10,,,,episode,,,,,,15,b4e8e618,8329803,5,1626009250,watched-episode-key,,,us,true,watch-date-1626009250,
''';

      final result = TvTimeGdprParser.parseFromFiles({
        TvTimeGdprParser.trackingRecordsFile: v1,
      });

      expect(result.watchedEpisodes, hasLength(1));
      expect(result.watchedEpisodes.first.showName, 'My Hero Academia');
      expect(result.watchedEpisodes.first.seasonNumber, 5);
      expect(result.watchedEpisodes.first.episodeNumber, 15);
      expect(result.watchedEpisodes.first.watchedAt, isNotNull);
    });

    test('deduplicates episodes by episode_id', () {
      const v2 = '''
ep_id,gsi,series_name,season_number,episode_number,s_id,key,user_id,created_at,episode_id
8068625,watch-episode-1,Attack on Titan,4,3,267440,key,12589638,2021-01-11 02:05:01,8068625
''';

      const rewatched = '''
tv_show_name,episode_season_number,episode_number,user_id,episode_id,cpt,created_at,updated_at
Attack on Titan,4,3,12589638,8068625,1,2022-01-01 00:00:00,2022-01-01 00:00:00
''';

      final result = TvTimeGdprParser.parseFromFiles({
        TvTimeGdprParser.trackingRecordsV2File: v2,
        TvTimeGdprParser.rewatchedEpisodesFile: rewatched,
      });

      expect(result.watchedEpisodes, hasLength(1));
    });
  });
}
