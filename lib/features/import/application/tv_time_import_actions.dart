import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../matching/application/show_poster_provider.dart';
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
  resetShowsPagination(ref);
  ref.invalidate(tvTimeImportProvider);
}
