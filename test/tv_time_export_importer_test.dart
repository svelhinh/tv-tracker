import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_tracker/features/import/data/tv_time_export_importer.dart';
import 'package:tv_tracker/features/import/data/tv_time_gdpr_parser.dart';

void main() {
  group('TvTimeExportImporter', () {
    test('imports CSV files from a zip archive', () async {
      const followedCsv = '''
notification_type,archived,tv_show_name,created_at,active,diffusion,folder_id,notification_offset,user_id,tv_show_id,updated_at
2,0,Attack on Titan,2022-01-01 00:00:00,1,original,,-10,1,267440,2022-01-01 00:00:00
''';

      const v2Csv = '''
ep_id,gsi,series_name,season_number,episode_number,s_id,key,user_id,created_at,episode_id
8068625,watch-episode-1,Attack on Titan,4,3,267440,key,1,2021-01-11 02:05:01,8068625
''';

      final archive = Archive()
        ..addFile(
          ArchiveFile(
            'gdpr-data/${TvTimeGdprParser.followedShowsFile}',
            followedCsv.length,
            followedCsv.codeUnits,
          ),
        )
        ..addFile(
          ArchiveFile(
            'gdpr-data/${TvTimeGdprParser.trackingRecordsV2File}',
            v2Csv.length,
            v2Csv.codeUnits,
          ),
        );

      final zipBytes = ZipEncoder().encode(archive);
      final result = await TvTimeExportImporter.importFromZipBytes(zipBytes);

      expect(result.shows, hasLength(1));
      expect(result.shows.first.name, 'Attack on Titan');
      expect(result.watchedEpisodes, hasLength(1));
      expect(result.watchedEpisodes.first.label, 'Attack on Titan S4E3');
    });

    test('throws when followed_tv_show.csv is missing', () async {
      final archive = Archive()
        ..addFile(ArchiveFile('readme.txt', 3, 'hi'.codeUnits));

      final zipBytes = ZipEncoder().encode(archive);

      expect(
        () => TvTimeExportImporter.importFromZipBytes(zipBytes),
        throwsFormatException,
      );
    });
  });
}
