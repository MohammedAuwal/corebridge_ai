import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/theme/app_theme.dart';

// A local state provider to manage the active filter tab
final _activeFilterProvider = StateProvider<String>((ref) => 'All Artifacts');

class ArtifactsScreen extends ConsumerWidget {
  const ArtifactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerId = ref.watch(firebaseServiceProvider).currentUserId;
    if (ownerId == null) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: Text('Not signed in.', style: TextStyle(color: AppColors.textPrimary))),
      );
    }

    final artifactsStream = ref.watch(artifactRepositoryProvider).watchArtifacts(ownerId);
    final activeFilter = ref.watch(_activeFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: StreamBuilder(
        stream: artifactsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
          }

          final allArtifacts = snapshot.data!;
          
          // Filter logic
          final filteredArtifacts = activeFilter == 'All Artifacts'
              ? allArtifacts
              : allArtifacts.where((a) {
                  final type = a.type.name.toLowerCase();
                  if (activeFilter == 'Code' && type == 'code') return true;
                  if (activeFilter == 'Documents' && type == 'document') return true;
                  if (activeFilter == 'Visuals' && type == 'visual') return true;
                  if (activeFilter == 'Data' && type == 'data') return true;
                  if (activeFilter == 'Other' && !['code', 'document', 'visual', 'data'].contains(type)) return true;
                  return false;
                }).toList();

          return CustomScrollView(
            slivers: [
              _buildHeader(context),
              _buildSearchBar(),
              _buildStatsRow(allArtifacts), // Pass all so stats don't change on filter
              _buildFilterRow(ref, activeFilter),
              if (filteredArtifacts.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No artifacts found.', style: TextStyle(color: AppColors.textMuted))),
                )
              else
                _buildGrid(filteredArtifacts),
              _buildBottomPromo(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Artifacts', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Your AI-generated content, all in one place.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.accentBlue,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('New Artifact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search artifacts...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () {},
              ),
            )
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStatsRow(List<dynamic> artifacts) {
    int code = artifacts.where((a) => a.type.name.toLowerCase() == 'code').length;
    int docs = artifacts.where((a) => a.type.name.toLowerCase() == 'document').length;
    int visuals = artifacts.where((a) => a.type.name.toLowerCase() == 'visual').length;
    int other = artifacts.length - (code + docs + visuals);

    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Row(
          children: [
            _statCard(icon: Icons.auto_awesome_motion_rounded, iconColor: AppColors.accentBlue, count: artifacts.length, label: 'Total Artifacts', sub: 'All time'),
            const SizedBox(width: 16),
            _statCard(icon: Icons.code_rounded, iconColor: Colors.purpleAccent, count: code, label: 'Code', sub: '</>'),
            const SizedBox(width: 16),
            _statCard(icon: Icons.description_outlined, iconColor: Colors.blueAccent, count: docs, label: 'Documents', sub: ''),
            const SizedBox(width: 16),
            _statCard(icon: Icons.image_outlined, iconColor: Colors.orangeAccent, count: visuals, label: 'Visuals', sub: ''),
            const SizedBox(width: 16),
            _statCard(icon: Icons.category_outlined, iconColor: Colors.pinkAccent, count: other, label: 'Other', sub: ''),
          ],
        ),
      ),
    );
  }

  Widget _statCard({required IconData icon, required Color iconColor, required int count, required String label, required String sub}) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildFilterRow(WidgetRef ref, String active) {
    final filters = ['All Artifacts', 'Code', 'Documents', 'Visuals', 'Data', 'Other'];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: active == f,
                      onSelected: (val) => ref.read(_activeFilterProvider.notifier).state = f,
                      backgroundColor: Colors.transparent,
                      selectedColor: AppColors.surfaceRaised,
                      labelStyle: TextStyle(
                        color: active == f ? Colors.white : AppColors.textSecondary,
                        fontWeight: active == f ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(color: active == f ? AppColors.border : Colors.transparent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  )).toList(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: const Row(
                children: [
                  Text('Sort by: Recent', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 16),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded, color: AppColors.accentBlue, size: 18),
                    onPressed: () {},
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  Container(width: 1, height: 20, color: AppColors.border),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.textMuted, size: 18),
                    onPressed: () {},
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  SliverPadding _buildGrid(List<dynamic> artifacts) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 380,
          mainAxisExtent: 360,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ArtifactGridCard(artifact: artifacts[index]),
          childCount: artifacts.length,
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildBottomPromo() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.category_rounded, color: AppColors.accentBlue, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create something amazing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Artifacts help you save and organize AI-generated content so you can reuse and share it anytime.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('New Artifact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtifactGridCard extends StatelessWidget {
  final dynamic artifact;
  const _ArtifactGridCard({required this.artifact});

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'code': return Colors.purpleAccent;
      case 'document': return Colors.blueAccent;
      case 'visual': return Colors.greenAccent;
      case 'data': return Colors.orangeAccent;
      default: return Colors.pinkAccent;
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'code': return Icons.code_rounded;
      case 'document': return Icons.description_outlined;
      case 'visual': return Icons.image_outlined;
      case 'data': return Icons.data_object_rounded;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeName = artifact.type.name;
    final typeColor = _getColorForType(typeName);
    
    // Safely extract properties (fallback gracefully if your domain model differs)
    final title = artifact.title ?? 'Untitled';
    // Using try-catch or safe access in case 'description' isn't on your model yet.
    final description = (artifact as dynamic).toString().contains('description') ? artifact.description : 'Generated artifact content.';
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Area Header
          Container(
            height: 160,
            color: AppColors.surfaceRaised,
            width: double.infinity,
            child: Stack(
              children: [
                Center(
                  child: Icon(_getIconForType(typeName), size: 48, color: typeColor.withValues(alpha: 0.2)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Icon(Icons.star_border_rounded, color: AppColors.textMuted, size: 20),
                ),
              ],
            ),
          ),
          
          // Card Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_getIconForType(typeName), color: typeColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (typeName.toLowerCase() == 'document') ...[
                         const SizedBox(width: 8),
                         const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 18),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeName.toUpperCase(),
                          style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text('May 24, 2025', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
