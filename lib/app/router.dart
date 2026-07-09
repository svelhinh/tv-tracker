import 'package:flutter/material.dart';

import '../features/debug/presentation/debug_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/import/presentation/import_screen.dart';
import '../features/shows/presentation/shows_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const import = '/import';
  static const shows = '/shows';
  static const debug = '/debug';
}

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  return switch (settings.name) {
    AppRoutes.home => MaterialPageRoute(builder: (_) => const HomeScreen()),
    AppRoutes.import => MaterialPageRoute(builder: (_) => const ImportScreen()),
    AppRoutes.shows => MaterialPageRoute(builder: (_) => const ShowsScreen()),
    AppRoutes.debug => MaterialPageRoute(builder: (_) => const DebugScreen()),
    _ => null,
  };
}
