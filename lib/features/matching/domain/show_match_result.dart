import '../../import/domain/tv_time_show.dart';

enum ShowMatchConfidence {
  confident,
  ambiguous,
  noMatch,
  error,
  manual,
  ignored,
}

class ShowMatchResult {
  const ShowMatchResult({
    required this.show,
    this.tmdbId,
    this.tmdbName,
    this.tmdbFirstAirDate,
    required this.confidence,
    this.score,
    this.note,
  });

  final TvTimeShow show;
  final int? tmdbId;
  final String? tmdbName;
  final String? tmdbFirstAirDate;
  final ShowMatchConfidence confidence;
  final double? score;
  final String? note;

  bool get isConfidentMatch =>
      confidence == ShowMatchConfidence.confident ||
      confidence == ShowMatchConfidence.manual;

  bool get needsResolution =>
      confidence == ShowMatchConfidence.ambiguous ||
      confidence == ShowMatchConfidence.noMatch ||
      confidence == ShowMatchConfidence.error;
}
