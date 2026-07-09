import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../application/tv_time_import_actions.dart';
import '../application/tv_time_import_provider.dart';
import 'import_summary_view.dart';

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zipPath = ref.watch(tvTimeImportZipPathProvider);
    final importAsync = ref.watch(tvTimeImportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Import')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Import TV Time',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionne le ZIP GDPR reçu de TV Time pour charger tes '
            'séries et ton historique de visionnage.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => pickAndImportTvTimeExport(ref),
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
                  'commencer.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ImportSummaryView(result: result),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.shows),
                    child: const Text('Voir mes séries'),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Erreur import : $error'),
          ),
        ],
      ),
    );
  }
}
