enum ShowMatchOverrideKind { matched, ignored }

class ShowMatchOverride {
  const ShowMatchOverride({
    required this.tvTimeShowId,
    required this.kind,
    this.tmdbId,
    this.tmdbName,
    this.tmdbFirstAirDate,
    this.tmdbPosterPath,
  });

  final String tvTimeShowId;
  final ShowMatchOverrideKind kind;
  final int? tmdbId;
  final String? tmdbName;
  final String? tmdbFirstAirDate;
  final String? tmdbPosterPath;

  bool get isIgnored => kind == ShowMatchOverrideKind.ignored;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'tmdbId': tmdbId,
    'tmdbName': tmdbName,
    'tmdbFirstAirDate': tmdbFirstAirDate,
    'tmdbPosterPath': tmdbPosterPath,
  };

  factory ShowMatchOverride.fromJson(
    String tvTimeShowId,
    Map<String, dynamic> json,
  ) {
    return ShowMatchOverride(
      tvTimeShowId: tvTimeShowId,
      kind: ShowMatchOverrideKind.values.byName(json['kind'] as String),
      tmdbId: json['tmdbId'] as int?,
      tmdbName: json['tmdbName'] as String?,
      tmdbFirstAirDate: json['tmdbFirstAirDate'] as String?,
      tmdbPosterPath: json['tmdbPosterPath'] as String?,
    );
  }

  factory ShowMatchOverride.matched({
    required String tvTimeShowId,
    required int tmdbId,
    required String tmdbName,
    String? tmdbFirstAirDate,
    String? tmdbPosterPath,
  }) {
    return ShowMatchOverride(
      tvTimeShowId: tvTimeShowId,
      kind: ShowMatchOverrideKind.matched,
      tmdbId: tmdbId,
      tmdbName: tmdbName,
      tmdbFirstAirDate: tmdbFirstAirDate,
      tmdbPosterPath: tmdbPosterPath,
    );
  }

  factory ShowMatchOverride.ignored({required String tvTimeShowId}) {
    return ShowMatchOverride(
      tvTimeShowId: tvTimeShowId,
      kind: ShowMatchOverrideKind.ignored,
    );
  }
}
