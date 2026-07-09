import 'package:flutter/material.dart';

import '../domain/show_match_report.dart';
import '../domain/show_match_result.dart';

class TmdbMatchReportView extends StatelessWidget {
  const TmdbMatchReportView({super.key, required this.report});

  final ShowMatchReport report;

  @override
  Widget build(BuildContext context) {
    final confidentPercent = (report.confidentRate * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Matching TMDB', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _StatRow('Échantillon testé', '${report.sampleSize} séries'),
        _StatRow(
          'Matchs confiants',
          '${report.confidentCount} ($confidentPercent%)',
        ),
        if (report.manualCount > 0)
          _StatRow('Choix manuels', '${report.manualCount}'),
        if (report.ignoredCount > 0)
          _StatRow('Ignorées', '${report.ignoredCount}'),
        _StatRow('Ambigus', '${report.ambiguousCount}'),
        _StatRow('Sans match', '${report.noMatchCount}'),
        if (report.apiErrors > 0)
          _StatRow('Erreurs API', '${report.apiErrors}'),
        const SizedBox(height: 8),
        Text(
          report.isReliableEnough
              ? 'Verdict : assez fiable pour continuer le proto (≥ 80%).'
              : 'Verdict : matching à affiner avant de généraliser (< 80%).',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: report.isReliableEnough ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 16),
        Text('Erreurs typiques', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...report.typicalIssues.map((issue) => Text('• $issue')),
        const SizedBox(height: 16),
        Text(
          'Détail des matchs',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...report.results.map((result) => _matchLine(result)),
      ],
    );
  }

  Widget _matchLine(ShowMatchResult result) {
    final icon = switch (result.confidence) {
      ShowMatchConfidence.confident => '✓',
      ShowMatchConfidence.manual => '✓',
      ShowMatchConfidence.ambiguous => '?',
      ShowMatchConfidence.noMatch => '✗',
      ShowMatchConfidence.error => '!',
      ShowMatchConfidence.ignored => '−',
    };

    final tmdbPart = result.tmdbId != null
        ? ' → [${result.tmdbId}] ${result.tmdbName}'
        : '';

    final scorePart = result.score != null
        ? ' (${result.score!.toStringAsFixed(2)})'
        : '';

    final notePart = result.note != null ? ' — ${result.note}' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$icon ${result.show.name}$tmdbPart$scorePart$notePart'),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
