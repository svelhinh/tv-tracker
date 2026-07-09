class TvTimeShow {
  const TvTimeShow({
    required this.tvTimeId,
    required this.name,
    this.isActive = true,
    this.episodesSeenCount,
  });

  final String tvTimeId;
  final String name;
  final bool isActive;
  final int? episodesSeenCount;
}
