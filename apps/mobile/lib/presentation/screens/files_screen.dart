import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/theme/app_theme.dart';

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
      body: StreamBuilder(
        stream: filesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final files = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text('Files', style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      _GradientIconButton(
                        icon: Icons.upload_rounded,
                        onTap: () => _pickAndUpload(ref, ownerId),
                      ),
                    ],
                  ),
                ),
              ),
              if (files.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accentBlue.withValues(alpha: 0.15),
                                  AppColors.accentViolet.withValues(alpha: 0.15),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: ShaderMask(
                              shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                              child: const Icon(Icons.folder_copy_rounded, size: 40, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No files yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Upload documents, code, or images to get started.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _pickAndUpload(ref, ownerId),
                            icon: const Icon(Icons.upload_rounded, size: 18),
                            label: const Text('Upload a file'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final file = files[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.insert_drive_file_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(file.name, style: Theme.of(context).textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${(file.sizeBytes / 1024).toStringAsFixed(1)} KB', style: Theme.of(context).textTheme.labelSmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: files.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GradientIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
