import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bastikarma'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌿', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              'Welcome to Bastikarma',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Ayurvedic Clinical Assistant',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                // Handle logout
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
