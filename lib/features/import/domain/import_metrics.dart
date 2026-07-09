class ImportMetrics {
  const ImportMetrics({
    required this.importDuration,
    required this.zipSizeBytes,
    required this.showCount,
    required this.episodeCount,
    required this.estimatedStorageBytes,
    required this.tmdbCallsDuringImport,
    required this.estimatedTmdbCallsForFullMatch,
    required this.estimatedTmdbCallsForPosters,
  });

  final Duration importDuration;
  final int zipSizeBytes;
  final int showCount;
  final int episodeCount;
  final int estimatedStorageBytes;
  final int tmdbCallsDuringImport;
  final int estimatedTmdbCallsForFullMatch;
  final int estimatedTmdbCallsForPosters;

  int get estimatedTmdbCallsFirstSession => estimatedTmdbCallsForFullMatch;

  List<ScaleEstimate> extrapolate({List<int> userCounts = scaleUserCounts}) {
    return userCounts
        .map(
          (count) => ScaleEstimate.fromPerUser(metrics: this, userCount: count),
        )
        .toList();
  }

  List<String> get costRiskNotes => const [
    'TMDB : 1 appel /search/tv par série (matching + poster fusionnés, '
        'cache session local).',
    'Rate limit : délai de 260 ms entre appels (~4 req/s) → sync TMDB long '
        'pour les grosses bibliothèques.',
    'Données import : en mémoire uniquement, pas encore persistées en base.',
    'SharedPreferences : limite pratique ~1–2 Mo sur mobile pour les deltas '
        'et le cache posters.',
    'Ambigus / sans match : résolution manuelle = appels TMDB supplémentaires.',
    'Images posters : bande passante TMDB CDN si chargées côté client.',
    'Sans serveur : pas de cache TMDB partagé entre utilisateurs.',
  ];

  static const scaleUserCounts = [1000, 10000, 100000];
}

class ScaleEstimate {
  const ScaleEstimate({
    required this.userCount,
    required this.totalShows,
    required this.totalEpisodes,
    required this.totalImportTimeIfSequential,
    required this.totalTmdbCallsFirstSession,
    required this.totalStorageBytes,
  });

  final int userCount;
  final int totalShows;
  final int totalEpisodes;
  final Duration totalImportTimeIfSequential;
  final int totalTmdbCallsFirstSession;
  final int totalStorageBytes;

  factory ScaleEstimate.fromPerUser({
    required ImportMetrics metrics,
    required int userCount,
  }) {
    return ScaleEstimate(
      userCount: userCount,
      totalShows: metrics.showCount * userCount,
      totalEpisodes: metrics.episodeCount * userCount,
      totalImportTimeIfSequential: Duration(
        microseconds: metrics.importDuration.inMicroseconds * userCount,
      ),
      totalTmdbCallsFirstSession:
          metrics.estimatedTmdbCallsFirstSession * userCount,
      totalStorageBytes: metrics.estimatedStorageBytes * userCount,
    );
  }

  String get storageLabel => _formatBytes(totalStorageBytes);

  String get importTimeLabel => _formatDuration(totalImportTimeIfSequential);
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} Go';
}

String _formatDuration(Duration duration) {
  if (duration.inHours >= 1) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }
  if (duration.inMinutes >= 1) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}min ${seconds}s';
  }
  if (duration.inMilliseconds >= 1000) {
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)} s';
  }
  return '${duration.inMilliseconds} ms';
}
