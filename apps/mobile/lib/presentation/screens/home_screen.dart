import 'package:flutter/material.dart';
import '../widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppCard(title: 'Recent conversations', subtitle: 'Pick up where you left off'),
          SizedBox(height: 12),
          AppCard(title: 'Recent artifacts', subtitle: 'Documents and code you\'ve been editing'),
          SizedBox(height: 12),
          AppCard(title: 'Storage usage', subtitle: 'Track your free-tier limits'),
        ],
      ),
    );
  }
}
