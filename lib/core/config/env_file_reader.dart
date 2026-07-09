import 'dart:io';

import 'env_values.dart';

/// Lit un fichier `.env` depuis le disque (scripts CLI, outils).
Future<void> loadEnvFile({String path = '.env'}) async {
  final file = File(path);
  if (!await file.exists()) return;

  final values = <String, String>{};
  for (final line in await file.readAsLines()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    final separatorIndex = trimmed.indexOf('=');
    if (separatorIndex <= 0) continue;

    final key = trimmed.substring(0, separatorIndex).trim();
    final value = trimmed.substring(separatorIndex + 1).trim();
    values[key] = value;
  }

  EnvValues.setAll(values);
}
