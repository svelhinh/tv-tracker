import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../import/application/tv_time_import_provider.dart';

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
            'Export TV Time (GDPR)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Format : fichier ZIP contenant les CSV de l\'export GDPR.\n'
            'Séries : followed_tv_show.csv\n'
            'Épisodes vus : tracking-prod-records-v2.csv (watch-episode), '
            'tracking-prod-records.csv (watch), rewatched_episode.csv',
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
                  'Aucun export chargé. Sélectionne le ZIP reçu de TV Time '
                  '(dossier gdpr-data compressé).',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Séries suivies : ${result.shows.length}'),
                  Text('Épisodes vus : ${result.watchedEpisodes.length}'),
                  const SizedBox(height: 16),
                  Text(
                    'Séries (10 premières)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...result.shows
                      .take(10)
                      .map(
                        (show) => Text(
                          '• [${show.tvTimeId}] ${show.name}'
                          '${show.episodesSeenCount != null ? ' — ${show.episodesSeenCount} ep. vus' : ''}',
                        ),
                      ),
                  const SizedBox(height: 16),
                  Text(
                    'Épisodes vus (10 premiers)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...result.watchedEpisodes
                      .take(10)
                      .map(
                        (episode) => Text(
                          '• ${episode.label}'
                          '${episode.watchedAt != null ? ' — ${episode.watchedAt}' : ''}',
                        ),
                      ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('Erreur import : $error'),
          ),
        ],
      ),
    );
  }
}
