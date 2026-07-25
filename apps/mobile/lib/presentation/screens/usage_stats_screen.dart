import 'package:flutter/material.dart';
import '../widgets/geo_mesh_background.dart';

class UsageStatsScreen extends StatelessWidget {
  const UsageStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usage & Stats')),
      body: Stack(
        children: [
          const Positioned.fill(child: GeoMeshBackground()),
          const Center(child: Text('Usage tracking is coming soon.')),
        ],
      ),
    );
  }
}
