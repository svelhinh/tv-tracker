import 'package:flutter/material.dart';

class ShowsScreen extends StatelessWidget {
  const ShowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shows')),
      body: const Center(child: Text('Écran Shows — à venir')),
    );
  }
}
