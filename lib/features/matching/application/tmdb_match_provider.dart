import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/tmdb_config.dart';
import '../../import/application/tv_time_import_provider.dart';
import '../data/tmdb_client.dart';
import '../data/tmdb_show_matcher.dart';
import '../domain/show_match_report.dart';

final tmdbClientProvider = Provider<TmdbClient>((ref) {
  final client = TmdbClient();
  ref.onDispose(client.close);
  return client;
});

final tmdbMatchRequestIdProvider = StateProvider<int>((ref) => 0);

final tmdbMatchReportProvider = FutureProvider<ShowMatchReport?>((ref) async {
  final requestId = ref.watch(tmdbMatchRequestIdProvider);
  if (requestId == 0) return null;

  final import = await ref.watch(tvTimeImportProvider.future);
  if (import == null || import.shows.isEmpty) return null;
  if (!hasTmdbApiKey) {
    throw const TmdbException(
      'TMDB_API_KEY manquant. Ajoute-la dans .env ou lance avec '
      '--dart-define=TMDB_API_KEY=ta_cle',
    );
  }

  final matcher = TmdbShowMatcher(ref.watch(tmdbClientProvider));
  return matcher.matchShows(import.shows);
});
