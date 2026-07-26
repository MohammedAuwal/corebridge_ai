import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/theme/app_theme.dart';

// A local state provider for the active folder filter
final _activeFolderProvider = StateProvider<String>((ref) => 'All Files');

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
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: Text('Not signed in.', style: TextStyle(color: AppColors.textPrimary))),
      );
    }

    final filesStream = ref.watch(fileRepositoryProvider).watchFiles(ownerId);
    final activeFolder = ref.watch(_activeFolderProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: StreamBuilder(
        stream: filesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
          }

          final allFiles = snapshot.data!;
          
          // Basic filter logic based on file extension
          final filteredFiles = activeFolder == 'All Files' 
              ? allFiles 
              : allFiles.where((f) {
                  final ext = f.name.split('.').last.toLowerCase();
                  if (activeFolder == 'Documents' && ['pdf', 'doc', 'docx', 'txt'].contains(ext)) return true;
                  if (activeFolder == 'Images' && ['png', 'jpg', 'jpeg', 'gif', 'svg'].contains(ext)) return true;
                  if (activeFolder == 'Code' && ['py', 'js', 'jsx', 'ts', 'json', 'html', 'css'].contains(ext)) return true;
                  if (activeFolder == 'Data' && ['xls', 'xlsx', 'csv'].contains(ext)) return true;
                  return false;
                }).toList();

          return CustomScrollView(
            slivers: [
              _buildHeader(context, ref, ownerId),
              _buildSearchBar(),
              _buildStatsRow(allFiles),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Sidebar: Folders
                      SizedBox(
                        width: 240,
                        child: _buildFoldersSidebar(ref, activeFolder, allFiles),
                      ),
                      const SizedBox(width: 24),
                      // Right Area: Table
                      Expanded(
                        child: _buildFilesTable(filteredFiles, activeFolder),
                      ),
                    ],
                  ),
                ),
              ),
              _buildDragDropZone(ref, ownerId),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(BuildContext context, WidgetRef ref, String ownerId) {
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
                const Text('Files', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Store, organize and access your files in one place.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.accentBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _pickAndUpload(ref, ownerId),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Upload Files', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                  borderRadius: BorderRadius.circular(8),
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
                          hintText: 'Search files...',
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
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_alt_outlined, color: AppColors.textSecondary, size: 20),
                onPressed: () {},
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
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                    padding: EdgeInsets.zero,
                  ),
                  Container(width: 1, height: 24, color: AppColors.border),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.textMuted, size: 18),
                    onPressed: () {},
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
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

  SliverToBoxAdapter _buildStatsRow(List<dynamic> files) {
    double totalStorageMB = files.fold(0.0, (sum, file) => sum + (file.sizeBytes / (1024 * 1024)));
    int imageCount = files.where((f) => ['png', 'jpg', 'jpeg', 'gif', 'svg'].contains(f.name.split('.').last.toLowerCase())).length;
    int docCount = files.where((f) => ['pdf', 'doc', 'docx', 'txt'].contains(f.name.split('.').last.toLowerCase())).length;
    int codeCount = files.where((f) => ['py', 'js', 'jsx', 'ts', 'json'].contains(f.name.split('.').last.toLowerCase())).length;

    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Row(
          children: [
            _statCard(icon: Icons.insert_drive_file, iconColor: Colors.blueAccent, value: files.length.toString(), label: 'Total Files', sub: 'Across all folders'),
            const SizedBox(width: 16),
            _statCard(icon: Icons.storage_rounded, iconColor: Colors.greenAccent, value: '${(totalStorageMB / 1024).toStringAsFixed(2)} GB', label: 'Total Storage', sub: 'Used of unlimited'),
            const SizedBox(width: 16),
            _statCard(icon: Icons.image_outlined, iconColor: Colors.purpleAccent, value: imageCount.toString(), label: 'Images', sub: 'JPG, PNG, GIF, SVG'),
            const SizedBox(width: 16),
            _statCard(icon: Icons.description_outlined, iconColor: Colors.redAccent, value: docCount.toString(), label: 'Documents', sub: 'PDF, DOCX, TXT, etc.'),
            const SizedBox(width: 16),
            _statCard(icon: Icons.code_rounded, iconColor: Colors.orangeAccent, value: codeCount.toString(), label: 'Code Files', sub: 'JS, PY, TS, JSON, etc.'),
          ],
        ),
      ),
    );
  }

  Widget _statCard({required IconData icon, required Color iconColor, required String value, required String label, required String sub}) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFoldersSidebar(WidgetRef ref, String active, List<dynamic> allFiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Folders', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.textMuted, size: 20),
              onPressed: () {},
            )
          ],
        ),
        const SizedBox(height: 8),
        _folderItem(ref, 'All Files', Icons.folder_copy_outlined, allFiles.length, active),
        _folderItem(ref, 'Documents', Icons.description_outlined, allFiles.where((f) => ['pdf', 'doc', 'docx', 'txt'].contains(f.name.split('.').last.toLowerCase())).length, active),
        _folderItem(ref, 'Images', Icons.image_outlined, allFiles.where((f) => ['png', 'jpg', 'jpeg', 'gif', 'svg'].contains(f.name.split('.').last.toLowerCase())).length, active),
        _folderItem(ref, 'Code', Icons.code_rounded, allFiles.where((f) => ['py', 'js', 'jsx', 'ts', 'json', 'html', 'css'].contains(f.name.split('.').last.toLowerCase())).length, active),
        _folderItem(ref, 'Data', Icons.data_object_rounded, allFiles.where((f) => ['xls', 'xlsx', 'csv'].contains(f.name.split('.').last.toLowerCase())).length, active),
        _folderItem(ref, 'Designs', Icons.draw_outlined, 0, active), // Mocked for UI parity
        _folderItem(ref, 'Reports', Icons.analytics_outlined, 0, active),
        _folderItem(ref, 'Notes', Icons.notes_rounded, 0, active),
        _folderItem(ref, 'Others', Icons.folder_outlined, 0, active),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New Folder'),
          style: TextButton.styleFrom(foregroundColor: AppColors.accentBlue),
        )
      ],
    );
  }

  Widget _folderItem(WidgetRef ref, String label, IconData icon, int count, String active) {
    final isSelected = label == active;
    return InkWell(
      onTap: () => ref.read(_activeFolderProvider.notifier).state = label,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)) : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.accentBlue : AppColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.2) : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(color: isSelected ? AppColors.accentBlue : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilesTable(List<dynamic> files, String activeFolder) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('$activeFolder (${files.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                  child: const Row(
                    children: [
                      Text('Sort by: Recent', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 16),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          
          // Table Columns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(width: 16, height: 16, decoration: BoxDecoration(border: Border.all(color: AppColors.textMuted), borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 24),
                const Expanded(flex: 4, child: Text('Name', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
                const Expanded(flex: 2, child: Text('Type', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
                const Expanded(flex: 2, child: Text('Size', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
                const Expanded(flex: 3, child: Text('Modified', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
                const SizedBox(width: 24), // For 3 dots
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Empty state or List
          if (files.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No files found.', style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) => _buildFileRow(files[index]),
            ),
            
          // Pagination Footer (Mocked visually)
          if (files.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Showing 1 to ${files.length} of ${files.length} files', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const Spacer(),
                  _paginationButton(Icons.chevron_left_rounded, false),
                  const SizedBox(width: 4),
                  _paginationNumber('1', true),
                  const SizedBox(width: 4),
                  _paginationNumber('2', false),
                  const SizedBox(width: 4),
                  _paginationNumber('3', false),
                  const SizedBox(width: 4),
                  const Text('...', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 4),
                  _paginationNumber('25', false),
                  const SizedBox(width: 4),
                  _paginationButton(Icons.chevron_right_rounded, false),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildFileRow(dynamic file) {
    final ext = file.name.split('.').last.toUpperCase();
    final fileGroup = _getFileGroup(ext);
    final color = _getColorForExt(ext);

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Container(width: 16, height: 16, decoration: BoxDecoration(border: Border.all(color: AppColors.textMuted), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 24),
            Expanded(
              flex: 4, 
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: Text(ext.length > 3 ? ext.substring(0,3) : ext, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(fileGroup, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2, 
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)),
                  child: Text(ext, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            Expanded(
              flex: 2, 
              child: Text(
                file.sizeBytes > 1024 * 1024 
                    ? '${(file.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB' 
                    : '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB', 
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)
              )
            ),
            Expanded(
              flex: 3, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('May 24, 2025', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('10:30 AM', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              )
            ),
            const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _paginationButton(IconData icon, bool active) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? AppColors.accentBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: active ? null : Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: active ? Colors.white : AppColors.textSecondary, size: 16),
    );
  }

  Widget _paginationNumber(String num, bool active) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? AppColors.accentBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: active ? null : Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(num, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
    );
  }

  SliverToBoxAdapter _buildDragDropZone(WidgetRef ref, String ownerId) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: InkWell(
          onTap: () => _pickAndUpload(ref, ownerId),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.canvas, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.cloud_upload_outlined, color: AppColors.accentBlue, size: 28),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Drag & drop files here', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('or click to browse your files', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    'Supports: PDF, DOCX, XLSX, PPTX, TXT,\nCSV, JSON, PNG, JPG, SVG, ZIP, code files\nand more.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helpers ---
  String _getFileGroup(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': case 'doc': case 'docx': case 'txt': return 'Documents';
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'svg': return 'Images';
      case 'py': case 'js': case 'jsx': case 'ts': case 'json': return 'Code';
      case 'xls': case 'xlsx': case 'csv': return 'Data';
      case 'fig': return 'Designs';
      default: return 'Others';
    }
  }

  Color _getColorForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return Colors.redAccent;
      case 'doc': case 'docx': return Colors.blueAccent;
      case 'xls': case 'xlsx': case 'csv': return Colors.greenAccent;
      case 'py': return Colors.indigoAccent;
      case 'js': case 'jsx': case 'json': return Colors.orangeAccent;
      case 'png': case 'jpg': case 'svg': return Colors.purpleAccent;
      case 'fig': return Colors.pinkAccent;
      default: return Colors.grey;
    }
  }
}
