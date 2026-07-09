import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv_tracker/app/app.dart';

void main() {
  testWidgets('Home screen displays app name and navigation buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TvTrackerApp()));
    await tester.pumpAndSettle();

    expect(find.text('TV Tracker'), findsWidgets);
    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Shows'), findsOneWidget);
    expect(find.text('Statut : Setup en cours'), findsOneWidget);
  });
}
