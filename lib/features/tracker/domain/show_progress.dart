class ShowProgress {
  const ShowProgress({required this.watchedCount, this.totalCount});

  final int watchedCount;
  final int? totalCount;

  double? get ratio {
    if (totalCount == null || totalCount! <= 0) return null;
    final value = watchedCount / totalCount!;
    return value.clamp(0.0, 1.0);
  }

  String get label {
    if (totalCount != null) {
      return '$watchedCount / $totalCount épisodes';
    }
    return '$watchedCount épisode${watchedCount > 1 ? 's' : ''} vu${watchedCount > 1 ? 's' : ''}';
  }
}
