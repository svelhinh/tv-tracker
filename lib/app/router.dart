import 'package:flutter/material.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/import/presentation/import_screen.dart';
import '../features/shows/presentation/shows_screen.dart';
import '../features/tracker/presentation/show_detail_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const import = '/import';
  static const shows = '/shows';
  static const showDetail = '/shows/detail';
}

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  return switch (settings.name) {
    AppRoutes.home => MaterialPageRoute(builder: (_) => const HomeScreen()),
    AppRoutes.import => MaterialPageRoute(builder: (_) => const ImportScreen()),
    AppRoutes.shows => MaterialPageRoute(builder: (_) => const ShowsScreen()),
    AppRoutes.showDetail => MaterialPageRoute(
      builder: (_) => ShowDetailScreen(showId: settings.arguments! as String),
    ),
    _ => null,
  };
}
