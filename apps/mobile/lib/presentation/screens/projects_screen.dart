import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../widgets/app_card.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerId = ref.watch(firebaseServiceProvider).currentUserId;
    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }

    final projectsStream = ref.watch(projectRepositoryProvider).watchProjects(ownerId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context, ref, ownerId),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: projectsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return const Center(child: Text('No projects yet. Tap + to create one.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(title: project.name, subtitle: project.description),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, String ownerId) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(projectRepositoryProvider).createProject(
                    ownerId: ownerId,
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
