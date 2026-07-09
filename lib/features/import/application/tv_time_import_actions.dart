import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metrics/tmdb_api_metrics.dart';
import '../../matching/application/post_import_tmdb_sync.dart';
import '../../matching/application/show_poster_provider.dart';
import '../../matching/application/tmdb_match_provider.dart';
import 'tv_time_import_provider.dart';

Future<void> pickAndImportTvTimeExport(WidgetRef ref) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['zip'],
    dialogTitle: 'Sélectionner l\'export TV Time (ZIP)',
  );

  final zipPath = result?.files.single.path;
  if (zipPath == null) return;

  ref.read(tvTimeImportZipPathProvider.notifier).state = zipPath;
  ref.read(tmdbApiMetricsProvider.notifier).state = TmdbApiMetrics();
  await resetShowsPagination(ref);
  ref.invalidate(tvTimeImportProvider);
  await ref.read(tvTimeImportProvider.future);
  startPostImportTmdbSync(ref);
}
