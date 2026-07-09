import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../import/domain/tv_time_show.dart';
import '../../matching/application/show_poster_provider.dart';
import '../application/tracker_provider.dart';
import '../domain/show_detail.dart';
import '../domain/show_progress.dart';
import 'widgets/show_poster.dart';

class ShowDetailScreen extends ConsumerStatefulWidget {
  const ShowDetailScreen({super.key, required this.showId});

  final String showId;

  @override
  ConsumerState<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends ConsumerState<ShowDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPoster());
  }

  Future<void> _loadPoster() async {
    final detail = ref.read(showDetailProvider(widget.showId));
    if (detail == null) return;
    await ref.read(showPosterCacheProvider.notifier).loadPostersForShows([
      detail.show,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(showDetailProvider(widget.showId));
    final posterUrl = ref.watch(showPosterUrlProvider(widget.showId));

    if (detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Série introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(detail.show.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShowPoster(
                title: detail.show.name,
                posterUrl: posterUrl,
                width: 96,
                height: 144,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.progress.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _ProgressBar(progress: detail.progress),
                    if (!detail.show.isActive) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Série terminée / plus suivie',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Saisons et épisodes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...detail.seasons.asMap().entries.map(
            (entry) => _SeasonSection(
              show: detail.show,
              season: entry.value,
              initiallyExpanded: entry.key == 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonSection extends ConsumerWidget {
  const _SeasonSection({
    required this.show,
    required this.season,
    required this.initiallyExpanded,
  });

  final TvTimeShow show;
  final TrackedSeason season;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchedCount = season.episodes
        .where((episode) => episode.isWatched)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('Saison ${season.seasonNumber}'),
        subtitle: Text('$watchedCount / ${season.episodes.length} épisodes'),
        initiallyExpanded: initiallyExpanded,
        children: season.episodes
            .map(
              (episode) => CheckboxListTile(
                value: episode.isWatched,
                onChanged: (_) {
                  ref
                      .read(watchStateProvider.notifier)
                      .toggleEpisode(
                        show: show,
                        season: episode.seasonNumber,
                        episode: episode.episodeNumber,
                        currentlyWatched: episode.isWatched,
                      );
                },
                title: Text(episode.label),
                subtitle: Text(
                  'S${episode.seasonNumber}E${episode.episodeNumber}',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final ShowProgress progress;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: progress.ratio,
      minHeight: 8,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
