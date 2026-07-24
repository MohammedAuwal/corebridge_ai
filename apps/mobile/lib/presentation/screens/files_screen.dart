import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../widgets/app_card.dart';

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  Future<void> _pickAndUpload(WidgetRef ref, String ownerId) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    await ref.read(fileRepositoryProvider).uploadFile(
          ownerId: ownerId,
          fileName: file.name,
          bytes: file.bytes!,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerId = ref.watch(firebaseServiceProvider).currentUserId;
    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }

    final filesStream = ref.watch(fileRepositoryProvider).watchFiles(ownerId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _pickAndUpload(ref, ownerId),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: filesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final files = snapshot.data!;
          if (files.isEmpty) {
            return const Center(child: Text('No files yet. Tap the upload icon.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  title: file.name,
                  subtitle: '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
