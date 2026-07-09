class TmdbShowSearchResult {
  const TmdbShowSearchResult({
    required this.id,
    required this.name,
    this.originalName,
    this.firstAirDate,
    this.popularity = 0,
    this.voteCount = 0,
  });

  final int id;
  final String name;
  final String? originalName;
  final String? firstAirDate;
  final double popularity;
  final int voteCount;

  factory TmdbShowSearchResult.fromJson(Map<String, dynamic> json) {
    return TmdbShowSearchResult(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      originalName: json['original_name'] as String?,
      firstAirDate: json['first_air_date'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      voteCount: json['vote_count'] as int? ?? 0,
    );
  }
}
