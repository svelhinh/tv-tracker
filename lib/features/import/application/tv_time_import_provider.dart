import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tv_time_export_importer.dart';
import '../domain/tv_time_import_result.dart';

final tvTimeImportZipPathProvider = StateProvider<String?>((ref) => null);

final tvTimeImportProvider = FutureProvider<TvTimeImportResult?>((ref) async {
  final zipPath = ref.watch(tvTimeImportZipPathProvider);
  if (zipPath == null || zipPath.isEmpty) return null;

  return TvTimeExportImporter.importFromZipFile(zipPath);
});
