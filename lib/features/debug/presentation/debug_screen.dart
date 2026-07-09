import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../import/application/tv_time_import_provider.dart';
import '../../import/presentation/import_summary_view.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  Future<void> _pickExportZip(WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      dialogTitle: 'Sélectionner l\'export TV Time (ZIP)',
    );

    final zipPath = result?.files.single.path;
    if (zipPath == null) return;

    ref.read(tvTimeImportZipPathProvider.notifier).state = zipPath;
    ref.invalidate(tvTimeImportProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appNameProvider);
    final protoStatus = ref.watch(protoStatusProvider);
    final zipPath = ref.watch(tvTimeImportZipPathProvider);
    final importAsync = ref.watch(tvTimeImportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('App : $appName'),
          const SizedBox(height: 8),
          Text('Statut : $protoStatus'),
          const Divider(height: 32),
          Text(
            'Import TV Time',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionne le ZIP GDPR reçu de TV Time pour obtenir un résumé '
            'exploitable : compteurs, erreurs, exemples et limites des champs.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _pickExportZip(ref),
            icon: const Icon(Icons.upload_file),
            label: const Text('Importer un export ZIP'),
          ),
          if (zipPath != null) ...[
            const SizedBox(height: 8),
            Text('Fichier : $zipPath'),
          ],
          const SizedBox(height: 16),
          importAsync.when(
            data: (result) {
              if (result == null) {
                return const Text(
                  'Aucun export chargé. Importe le ZIP GDPR de TV Time pour '
                  'afficher le résumé.',
                );
              }

              return ImportSummaryView(result: result);
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('Erreur import : $error'),
          ),
        ],
      ),
    );
  }
}
