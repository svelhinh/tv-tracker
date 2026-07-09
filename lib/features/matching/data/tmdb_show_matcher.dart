import '../../import/domain/tv_time_show.dart';
import '../domain/show_match_override.dart';
import '../domain/show_match_report.dart';
import '../domain/show_match_result.dart';
import '../domain/tmdb_show_search_result.dart';
import 'tmdb_client.dart';

const defaultMatchSampleSize = 20;
const defaultCandidateCount = 5;

class TmdbShowMatcher {
  TmdbShowMatcher(this._client);

  final TmdbClient _client;

  Future<ShowMatchReport> matchShows(
    List<TvTimeShow> shows, {
    int? sampleSize,
    Map<String, ShowMatchOverride> overrides = const {},
  }) async {
    final sample = sampleSize == null ? shows : shows.take(sampleSize).toList();
    final results = <ShowMatchResult>[];
    var apiErrors = 0;

    for (final show in sample) {
      final override = overrides[show.tvTimeId];
      if (override != null) {
        results.add(_resultFromOverride(show, override));
        continue;
      }

      try {
        final searchResults = await _client.searchTv(show.name);
        results.add(_pickBestMatch(show, searchResults));
      } on TmdbException catch (error) {
        apiErrors++;
        results.add(
          ShowMatchResult(
            show: show,
            confidence: ShowMatchConfidence.error,
            note: error.message,
          ),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 260));
    }

    return ShowMatchReport(
      results: results,
      sampleSize: sample.length,
      apiErrors: apiErrors,
    );
  }

  Future<List<TmdbShowSearchResult>> getCandidates(
    TvTimeShow show, {
    int limit = defaultCandidateCount,
  }) async {
    final searchResults = await _client.searchTv(show.name);
    final scored = searchResults
        .map(
          (candidate) => (
            candidate: candidate,
            score: _titleScore(show.name, candidate),
          ),
        )
        .toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return b.candidate.popularity.compareTo(a.candidate.popularity);
      });

    return scored.take(limit).map((entry) => entry.candidate).toList();
  }

  ShowMatchResult _resultFromOverride(
    TvTimeShow show,
    ShowMatchOverride override,
  ) {
    if (override.isIgnored) {
      return ShowMatchResult(
        show: show,
        confidence: ShowMatchConfidence.ignored,
        note: 'Ignorée manuellement.',
      );
    }

    return ShowMatchResult(
      show: show,
      tmdbId: override.tmdbId,
      tmdbName: override.tmdbName,
      tmdbFirstAirDate: override.tmdbFirstAirDate,
      confidence: ShowMatchConfidence.manual,
      note: 'Choix manuel enregistré.',
    );
  }

  ShowMatchResult _pickBestMatch(
    TvTimeShow show,
    List<TmdbShowSearchResult> candidates,
  ) {
    if (candidates.isEmpty) {
      return ShowMatchResult(
        show: show,
        confidence: ShowMatchConfidence.noMatch,
        note: 'Aucun résultat TMDB.',
      );
    }

    final scored = candidates
        .map(
          (candidate) => (
            candidate: candidate,
            score: _titleScore(show.name, candidate),
          ),
        )
        .toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return b.candidate.popularity.compareTo(a.candidate.popularity);
      });

    final best = scored.first;
    final secondScore = scored.length > 1 ? scored[1].score : 0.0;
    final gap = best.score - secondScore;

    if (best.score >= 0.92 && gap >= 0.08) {
      return _confident(show, best.candidate, best.score);
    }

    if (best.score >= 0.75 && gap >= 0.12) {
      return _confident(show, best.candidate, best.score);
    }

    if (best.score >= 0.6) {
      final runnerUp = scored.length > 1 ? scored[1].candidate.name : null;
      return ShowMatchResult(
        show: show,
        tmdbId: best.candidate.id,
        tmdbName: best.candidate.name,
        tmdbFirstAirDate: best.candidate.firstAirDate,
        confidence: ShowMatchConfidence.ambiguous,
        score: best.score,
        note: runnerUp != null
            ? 'Plusieurs candidats proches (ex. $runnerUp).'
            : 'Score limite (${best.score.toStringAsFixed(2)}).',
      );
    }

    return ShowMatchResult(
      show: show,
      confidence: ShowMatchConfidence.noMatch,
      score: best.score,
      note: 'Meilleur score trop faible (${best.score.toStringAsFixed(2)}).',
    );
  }

  ShowMatchResult _confident(
    TvTimeShow show,
    TmdbShowSearchResult candidate,
    double score,
  ) {
    return ShowMatchResult(
      show: show,
      tmdbId: candidate.id,
      tmdbName: candidate.name,
      tmdbFirstAirDate: candidate.firstAirDate,
      confidence: ShowMatchConfidence.confident,
      score: score,
    );
  }

  double _titleScore(String query, TmdbShowSearchResult candidate) {
    final scores = [
      _normalizedSimilarity(query, candidate.name),
      if (candidate.originalName != null)
        _normalizedSimilarity(query, candidate.originalName!),
    ];

    return scores.reduce((a, b) => a > b ? a : b);
  }

  double _normalizedSimilarity(String a, String b) {
    final left = _normalizeTitle(a);
    final right = _normalizeTitle(b);

    if (left == right) return 1;
    if (left.contains(right) || right.contains(left)) return 0.88;

    final leftTokens = left.split(' ').where((token) => token.isNotEmpty);
    final rightTokens = right.split(' ').where((token) => token.isNotEmpty);
    final leftSet = leftTokens.toSet();
    final rightSet = rightTokens.toSet();

    if (leftSet.isEmpty || rightSet.isEmpty) return 0;

    final intersection = leftSet.intersection(rightSet).length;
    final union = leftSet.union(rightSet).length;
    return intersection / union;
  }

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r"['':;,.!?()\\[\\]-]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
