import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'env_values.dart';

/// Charge `.env` embarqué comme asset Flutter (app mobile/desktop).
Future<void> loadAppEnv() async {
  try {
    await dotenv.load(fileName: '.env');
    EnvValues.setAll(dotenv.env);
  } catch (_) {
    // .env optionnel si --dart-define est utilisé
  }
}
