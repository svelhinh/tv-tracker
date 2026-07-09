import 'env_values.dart';

const tmdbApiBaseUrl = 'https://api.themoviedb.org/3';

String get tmdbApiKey => EnvValues.get('TMDB_API_KEY');

bool get hasTmdbApiKey => tmdbApiKey.isNotEmpty;
