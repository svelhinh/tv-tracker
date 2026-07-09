class EpisodeKey {
  const EpisodeKey({required this.season, required this.episode});

  final int season;
  final int episode;

  String get storageKey => '$season:$episode';

  factory EpisodeKey.parse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw FormatException('Clé épisode invalide : $value');
    }

    return EpisodeKey(
      season: int.parse(parts[0]),
      episode: int.parse(parts[1]),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodeKey &&
        other.season == season &&
        other.episode == episode;
  }

  @override
  int get hashCode => Object.hash(season, episode);
}
