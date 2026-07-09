String? tmdbPosterUrl(String? posterPath, {String size = 'w185'}) {
  if (posterPath == null || posterPath.isEmpty) return null;
  return 'https://image.tmdb.org/t/p/$size$posterPath';
}
