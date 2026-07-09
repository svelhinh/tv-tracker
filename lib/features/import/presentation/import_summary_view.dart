import 'package:flutter/material.dart';

import '../domain/tv_time_import_result.dart';
import '../domain/tv_time_show.dart';
import '../domain/tv_time_watched_episode.dart';

class ImportSummaryView extends StatelessWidget {
  const ImportSummaryView({super.key, required this.result});

  final TvTimeImportResult result;

  @override
  Widget build(BuildContext context) {
    final summary = result.summary;
    final report = summary.report;

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
