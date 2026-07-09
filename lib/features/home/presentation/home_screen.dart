import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appNameProvider);
    final protoStatus = ref.watch(protoStatusProvider);

    return Scaffold(
      appBar: AppBar(title: Text(appName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(appName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(
              AppConstants.protoGoal,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Statut : $protoStatus',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.import),
              child: const Text('Import'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.shows),
              child: const Text('Shows'),
            ),
          ],
        ),
      ),
    );
  }
}
