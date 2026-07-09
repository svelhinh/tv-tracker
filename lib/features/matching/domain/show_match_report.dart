import 'show_match_result.dart';

class ShowMatchReport {
  const ShowMatchReport({
    required this.results,
    required this.sampleSize,
    this.apiErrors = 0,
  });

  final List<ShowMatchResult> results;
  final int sampleSize;
  final int apiErrors;

  int get confidentCount =>
      results.where((result) => result.isConfidentMatch).length;

  int get manualCount => results
      .where((result) => result.confidence == ShowMatchConfidence.manual)
      .length;

  int get ignoredCount => results
      .where((result) => result.confidence == ShowMatchConfidence.ignored)
      .length;

  List<ShowMatchResult> get needsResolutionResults =>
      results.where((result) => result.needsResolution).toList();

  int get ambiguousCount => results
      .where((result) => result.confidence == ShowMatchConfidence.ambiguous)
      .length;

  int get noMatchCount => results
      .where((result) => result.confidence == ShowMatchConfidence.noMatch)
      .length;

  double get confidentRate => sampleSize == 0 ? 0 : confidentCount / sampleSize;

  bool get isReliableEnough => confidentRate >= 0.8;

  List<String> get typicalIssues {
    final issues = <String>[];

    final ambiguous = results
        .where((r) => r.confidence == ShowMatchConfidence.ambiguous)
        .toList();
    if (ambiguous.isNotEmpty) {
      issues.add(
        'Titres ambigus (${ambiguous.length}) : homonymes ou scores proches '
        '(ex. ${ambiguous.take(2).map((r) => r.show.name).join(', ')}).',
      );
    }

    final noMatch = results
        .where((r) => r.confidence == ShowMatchConfidence.noMatch)
        .toList();
    if (noMatch.isNotEmpty) {
      issues.add(
        'Aucun match TMDB (${noMatch.length}) : titre introuvable ou score trop '
        'faible (ex. ${noMatch.take(2).map((r) => r.show.name).join(', ')}).',
      );
    }

    final errors = results
        .where((r) => r.confidence == ShowMatchConfidence.error)
        .toList();
    if (errors.isNotEmpty) {
      issues.add('Erreurs API sur ${errors.length} série(s).');
    }

    if (issues.isEmpty && confidentCount == sampleSize) {
      issues.add('Aucun problème notable sur l\'échantillon testé.');
    }

    return issues;
  }
}
