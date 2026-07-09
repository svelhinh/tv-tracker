import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../import/domain/tv_time_show.dart';
import '../application/tmdb_match_provider.dart';
import '../domain/show_match_report.dart';
import '../domain/show_match_result.dart';
import '../domain/tmdb_show_search_result.dart';

class ShowMatchResolutionView extends ConsumerWidget {
  const ShowMatchResolutionView({
    super.key,
    required this.report,
    required this.allShows,
  });

  final ShowMatchReport report;
  final List<TvTimeShow> allShows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toResolve = report.needsResolutionResults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correction manuelle',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (toResolve.isEmpty)
          const Text('Aucune série à corriger. Tous les matchs sont résolus.')
        else ...[
          Text('${toResolve.length} série(s) ambiguë(s) ou sans match.'),
          const SizedBox(height: 12),
          ...toResolve.map(
            (result) => _ResolutionCard(result: result),
          ),
        ],
        const SizedBox(height: 16),
        _ManualCorrectionPicker(allShows: allShows),
      ],
    );
  }
}

class _ResolutionCard extends ConsumerWidget {
  const _ResolutionCard({required this.result});

  final ShowMatchResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(
      tmdbCandidatesProvider(result.show.tvTimeId),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.show.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (result.note != null) ...[
              const SizedBox(height: 4),
              Text(result.note!),
            ],
            const SizedBox(height: 12),
            candidatesAsync.when(
              data: (candidates) {
                if (candidates.isEmpty) {
                  return const Text('Aucun candidat TMDB trouvé.');
                }

                return Column(
                  children: [
                    ...candidates.map(
                      (candidate) => _CandidateTile(
                        showId: result.show.tvTimeId,
                        candidate: candidate,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => ref
                            .read(showMatchOverridesProvider.notifier)
                            .ignoreShow(result.show.tvTimeId),
                        child: const Text('Ignorer pour l\'instant'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (error, _) => Text('Erreur candidats : $error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateTile extends ConsumerWidget {
  const _CandidateTile({
    required this.showId,
    required this.candidate,
  });

  final String showId;
  final TmdbShowSearchResult candidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = candidate.firstAirDate != null &&
            candidate.firstAirDate!.length >= 4
        ? ' (${candidate.firstAirDate!.substring(0, 4)})'
        : '';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('[${candidate.id}] ${candidate.name}$year'),
      subtitle: candidate.originalName != null &&
              candidate.originalName != candidate.name
          ? Text(candidate.originalName!)
          : null,
      trailing: FilledButton.tonal(
        onPressed: () => ref.read(showMatchOverridesProvider.notifier).saveManualMatch(
              tvTimeShowId: showId,
              tmdbId: candidate.id,
              tmdbName: candidate.name,
              tmdbFirstAirDate: candidate.firstAirDate,
            ),
        child: const Text('Choisir'),
      ),
    );
  }
}

class _ManualCorrectionPicker extends ConsumerStatefulWidget {
  const _ManualCorrectionPicker({required this.allShows});

  final List<TvTimeShow> allShows;

  @override
  ConsumerState<_ManualCorrectionPicker> createState() =>
      _ManualCorrectionPickerState();
}

class _ManualCorrectionPickerState extends ConsumerState<_ManualCorrectionPicker> {
  TvTimeShow? _selectedShow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Corriger un autre match',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownMenu<TvTimeShow>(
          width: double.infinity,
          label: const Text('Série TV Time'),
          dropdownMenuEntries: widget.allShows
              .map(
                (show) => DropdownMenuEntry(
                  value: show,
                  label: show.name,
                ),
              )
              .toList(),
          onSelected: (show) => setState(() => _selectedShow = show),
        ),
        if (_selectedShow != null) ...[
          const SizedBox(height: 12),
          _ResolutionCard(
            result: ShowMatchResult(
              show: _selectedShow!,
              confidence: ShowMatchConfidence.ambiguous,
              note: 'Correction manuelle d\'un match automatique.',
            ),
          ),
        ],
      ],
    );
  }
}
