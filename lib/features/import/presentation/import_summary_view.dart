import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../matching/application/post_import_tmdb_sync.dart';
import '../../matching/application/tmdb_match_provider.dart';
import '../domain/import_metrics.dart';
import '../domain/tv_time_import_result.dart';
import '../domain/tv_time_show.dart';
import '../domain/tv_time_watched_episode.dart';

class ImportSummaryView extends ConsumerWidget {
  const ImportSummaryView({super.key, required this.result});

  final TvTimeImportResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = result.summary;
    final report = summary.report;
    final metrics = result.metrics;
    final tmdbMetrics = ref.watch(tmdbApiMetricsProvider);
    final tmdbSyncInProgress = ref.watch(postImportTmdbSyncInProgressProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Résumé'),
        const SizedBox(height: 8),
        _StatRow(
          label: 'Fichiers CSV dans le ZIP',
          value: '${report.csvFileCount}',
        ),
        _StatRow(label: 'Séries trouvées', value: '${summary.showCount}'),
        _StatRow(
          label: 'Épisodes vus',
          value: '${summary.watchedEpisodeCount}',
        ),
        if (report.totalSkippedEpisodeRows > 0)
          _StatRow(
            label: 'Lignes épisodes ignorées',
            value: '${report.totalSkippedEpisodeRows}',
          ),
        if (metrics != null) ...[
          const SizedBox(height: 16),
          _SectionTitle('Métriques import & scale'),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Durée import (parse ZIP)',
            value: _formatDuration(metrics.importDuration),
          ),
          if (metrics.zipSizeBytes > 0)
            _StatRow(
              label: 'Taille ZIP',
              value: _formatBytes(metrics.zipSizeBytes),
            ),
          _StatRow(
            label: 'Stockage local estimé',
            value: _formatBytes(metrics.estimatedStorageBytes),
          ),
          _StatRow(
            label: 'Appels TMDB pendant import',
            value: '${metrics.tmdbCallsDuringImport}',
          ),
          _StatRow(
            label: 'Appels TMDB estimés (1re session)',
            value: '${metrics.estimatedTmdbCallsFirstSession}',
          ),
          if (tmdbSyncInProgress)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Sync TMDB en cours (matching + posters en arrière-plan)…',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
          if (tmdbMetrics.callCount > 0) ...[
            _StatRow(
              label: 'Appels TMDB réels (session)',
              value: '${tmdbMetrics.callCount}',
            ),
            if (tmdbMetrics.cacheHitCount > 0)
              _StatRow(
                label: 'Cache TMDB (hits session)',
                value: '${tmdbMetrics.cacheHitCount}',
              ),
          ],
          const SizedBox(height: 8),
          _SectionTitle('Extrapolation', color: Colors.blueGrey),
          const SizedBox(height: 8),
          ...metrics.extrapolate().map(_scaleLine),
          const SizedBox(height: 8),
          _SectionTitle('Risques coût', color: Colors.deepOrange),
          const SizedBox(height: 8),
          ...metrics.costRiskNotes.map((note) => Text('• $note')),
        ],
        const SizedBox(height: 16),
        _SectionTitle('Fichiers sources'),
        const SizedBox(height: 8),
        ...report.sourceFilesPresent.entries.map(
          (entry) => _StatRow(
            label: entry.key,
            value: entry.value ? 'présent' : 'absent',
            valueColor: entry.value ? null : Colors.orange,
          ),
        ),
        if (report.hasErrors) ...[
          const SizedBox(height: 16),
          _SectionTitle('Erreurs', color: Colors.red),
          const SizedBox(height: 8),
          ...report.errors.map((error) => Text('• $error')),
        ],
        if (report.hasWarnings) ...[
          const SizedBox(height: 16),
          _SectionTitle('Avertissements', color: Colors.orange),
          const SizedBox(height: 8),
          ...report.warnings.map((warning) => Text('• $warning')),
        ],
        const SizedBox(height: 16),
        _SectionTitle('Champs manquants ou limites'),
        const SizedBox(height: 8),
        ...summary.fieldNotes.map((note) => Text('• $note')),
        const SizedBox(height: 16),
        _SectionTitle('Exemples de séries (${summary.exampleShows.length})'),
        const SizedBox(height: 8),
        ...summary.exampleShows.map(_showLine),
        const SizedBox(height: 16),
        _SectionTitle(
          'Exemples d\'épisodes vus (${summary.exampleEpisodes.length})',
        ),
        const SizedBox(height: 8),
        ...summary.exampleEpisodes.map(_episodeLine),
      ],
    );
  }

  Widget _scaleLine(ScaleEstimate estimate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '• ${estimate.userCount} utilisateurs : '
        '${estimate.totalShows} séries, '
        '${estimate.totalEpisodes} épisodes, '
        '${estimate.totalTmdbCallsFirstSession} appels TMDB, '
        '${estimate.storageLabel} stockage, '
        '${estimate.importTimeLabel} import séquentiel',
      ),
    );
  }

  Widget _showLine(TvTimeShow show) {
    final seen = show.episodesSeenCount != null
        ? ' — ${show.episodesSeenCount} ep. vus (agrégat)'
        : '';
    final status = show.isActive ? '' : ' — inactive';
    return Text('• [${show.tvTimeId}] ${show.name}$seen$status');
  }

  Widget _episodeLine(TvTimeWatchedEpisode episode) {
    final date = episode.watchedAt != null
        ? ' — ${_formatDate(episode.watchedAt!)}'
        : ' — date inconnue';
    final showId = episode.showId.isEmpty ? '' : ' (série ${episode.showId})';
    return Text('• ${episode.label}$showId$date');
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds >= 1000) {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)} s';
    }
    return '${duration.inMilliseconds} ms';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Text(
            value,
            style: valueColor != null
                ? TextStyle(color: valueColor, fontWeight: FontWeight.w600)
                : const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
