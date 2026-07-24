import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../widgets/app_card.dart';

class ArtifactsScreen extends ConsumerWidget {
  const ArtifactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerId = ref.watch(firebaseServiceProvider).currentUserId;
    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }

    final artifactsStream = ref.watch(artifactRepositoryProvider).watchArtifacts(ownerId);

    return Scaffold(
      appBar: AppBar(title: const Text('Artifacts')),
      body: StreamBuilder(
        stream: artifactsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final artifacts = snapshot.data!;
          if (artifacts.isEmpty) {
            return const Center(child: Text('No artifacts yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: artifacts.length,
            itemBuilder: (context, index) {
              final artifact = artifacts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(title: artifact.title, subtitle: artifact.type.name),
              );
            },
          );
        },
      ),
    );
  }
}
