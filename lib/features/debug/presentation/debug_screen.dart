import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/config/tmdb_config.dart';
import '../../import/application/tv_time_import_provider.dart';
import '../../import/presentation/import_summary_view.dart';
import '../../matching/application/tmdb_match_provider.dart';
import '../../matching/presentation/tmdb_match_report_view.dart';

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
    ref.read(tmdbMatchRequestIdProvider.notifier).state = 0;
    ref.invalidate(tvTimeImportProvider);
    ref.invalidate(tmdbMatchReportProvider);
  }

  void _runTmdbMatching(WidgetRef ref) {
    ref.read(tmdbMatchRequestIdProvider.notifier).state++;
    ref.invalidate(tmdbMatchReportProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appNameProvider);
    final protoStatus = ref.watch(protoStatusProvider);
    final zipPath = ref.watch(tvTimeImportZipPathProvider);
    final importAsync = ref.watch(tvTimeImportProvider);
    final matchAsync = ref.watch(tmdbMatchReportProvider);

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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ImportSummaryView(result: result),
                  const Divider(height: 32),
                  Text(
                    'Matching TMDB (20 séries)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasTmdbApiKey
                        ? 'Teste si les titres TV Time trouvent un match TMDB '
                              'évident.'
                        : 'Clé API manquante. Ajoute TMDB_API_KEY dans .env '
                              '(voir .env.example) ou lance avec '
                              '--dart-define=TMDB_API_KEY=ta_cle',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: hasTmdbApiKey
                        ? () => _runTmdbMatching(ref)
                        : null,
                    icon: const Icon(Icons.search),
                    label: const Text('Tester le matching TMDB'),
                  ),
                  const SizedBox(height: 16),
                  matchAsync.when(
                    data: (report) {
                      if (report == null) {
                        return const Text(
                          'Appuie sur le bouton pour lancer le test sur '
                          '20 séries.',
                        );
                      }
                      return TmdbMatchReportView(report: report);
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Text('Erreur matching : $error'),
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
