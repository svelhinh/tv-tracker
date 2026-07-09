import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../import/application/tv_time_import_provider.dart';
import '../../matching/application/show_poster_provider.dart';
import '../../tracker/domain/show_progress.dart';
import '../../tracker/domain/tracked_show.dart';
import '../../tracker/presentation/widgets/show_poster.dart';

class ShowsScreen extends ConsumerStatefulWidget {
  const ShowsScreen({super.key});

  @override
  ConsumerState<ShowsScreen> createState() => _ShowsScreenState();
}

class _ShowsScreenState extends ConsumerState<ShowsScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _initialPostersScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPostersForPage(int pageNumber) {
    return loadPostersForPage(ref, pageNumber);
  }

  void _onScroll() {
    if (_isLoadingMore || !_scrollController.hasClients) return;

    final paginated = ref.read(paginatedTrackedShowsProvider);
    if (paginated == null || !paginated.hasMore) return;

    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels < threshold) return;

    _isLoadingMore = true;
    final nextPage = ref.read(showsPageCountProvider) + 1;
    ref.read(showsPageCountProvider.notifier).state = nextPage;

    _loadPostersForPage(nextPage).whenComplete(() {
      if (mounted) setState(() => _isLoadingMore = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final importAsync = ref.watch(tvTimeImportProvider);
    final paginated = ref.watch(paginatedTrackedShowsProvider);
    final isFetchingPosters = ref.watch(posterFetchInProgressProvider);
    final zipPath = ref.watch(tvTimeImportZipPathProvider);

    if (zipPath == null) {
      _initialPostersScheduled = false;
    }

    if (!_initialPostersScheduled &&
        paginated != null &&
        paginated.items.isNotEmpty) {
      _initialPostersScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPostersForPage(1);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Séries')),
      body: importAsync.when(
        data: (_) {
          if (paginated == null) {
            return const _EmptyImportState();
          }

          if (paginated.items.isEmpty) {
            return const Center(child: Text('Aucune série dans l\'export.'));
          }

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: paginated.items.length + (paginated.hasMore ? 1 : 0),
            separatorBuilder: (_, index) {
              if (index >= paginated.items.length - 1) {
                return const SizedBox.shrink();
              }
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              if (index >= paginated.items.length) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: isFetchingPosters || _isLoadingMore
                        ? const CircularProgressIndicator()
                        : Text(
                            '${paginated.items.length} / ${paginated.totalCount} séries',
                          ),
                  ),
                );
              }

              return _ShowListTile(trackedShow: paginated.items[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
    );
  }
}

class _EmptyImportState extends StatelessWidget {
  const _EmptyImportState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Aucun export chargé. Importe d\'abord ton export TV Time '
            'depuis l\'écran Import.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.import),
            child: const Text('Aller à Import'),
          ),
        ],
      ),
    );
  }
}

class _ShowListTile extends ConsumerWidget {
  const _ShowListTile({required this.trackedShow});

  final TrackedShow trackedShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posterUrl = ref.watch(
      showPosterUrlProvider(trackedShow.show.tvTimeId),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ShowPoster(title: trackedShow.show.name, posterUrl: posterUrl),
      title: Text(trackedShow.show.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(trackedShow.progress.label),
          const SizedBox(height: 8),
          _ProgressBar(progress: trackedShow.progress),
        ],
      ),
      isThreeLine: true,
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.showDetail,
          arguments: trackedShow.show.tvTimeId,
        );
      },
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
      minHeight: 6,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
