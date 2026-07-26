import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/di/providers.dart';
import '../../core/providers/conversation_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/conversation_entity.dart';
import '../widgets/geo_mesh_background.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _sectionFor(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff <= 7) return 'Previous 7 days';
    if (diff <= 30) return 'Previous 30 days';
    return 'Older';
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return DateFormat.jm().format(dt);
    return DateFormat.MMMd().format(dt);
  }

  Map<String, List<ConversationEntity>> _groupAndFilter(List<ConversationEntity> conversations) {
    final filtered = _query.trim().isEmpty
        ? conversations
        : conversations.where((c) => c.title.toLowerCase().contains(_query.trim().toLowerCase())).toList();

    final grouped = <String, List<ConversationEntity>>{};
    for (final conversation in filtered) {
      final section = _sectionFor(conversation.updatedAt);
      grouped.putIfAbsent(section, () => []).add(conversation);
    }
    return grouped;
  }

  static const _sectionOrder = ['Today', 'Yesterday', 'Previous 7 days', 'Previous 30 days', 'Older'];

  void _openConversation(ConversationEntity conversation) {
    ref.read(activeConversationIdProvider.notifier).state = conversation.id;
    context.go('/chat');
  }

  void _confirmDelete(ConversationEntity conversation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: const Text('Delete conversation?'),
        content: Text('"${conversation.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(conversationRepositoryProvider).deleteConversation(conversation.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = ref.watch(firebaseServiceProvider).currentUserId;
    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }

    final conversationsStream = ref.watch(conversationRepositoryProvider).watchConversations(ownerId);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GeoMeshBackground()),
          StreamBuilder<List<ConversationEntity>>(
            stream: conversationsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load conversations: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                  ),
                );
              }

              final all = snapshot.data ?? [];
              final grouped = _groupAndFilter(all);

              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Text('History', style: Theme.of(context).textTheme.headlineMedium),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentBlue),
                            tooltip: 'New chat',
                            onPressed: () {
                              ref.read(activeConversationIdProvider.notifier).state = null;
                              context.go('/chat');
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() => _query = value),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Search conversations',
                                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              InkWell(
                                onTap: () => setState(() {
                                  _searchController.clear();
                                  _query = '';
                                }),
                                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: all.isEmpty
                          ? _buildEmptyState(context)
                          : grouped.isEmpty
                              ? Center(
                                  child: Text('No results for "$_query"', style: const TextStyle(color: AppColors.textMuted)),
                                )
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                                  children: [
                                    for (final section in _sectionOrder)
                                      if (grouped[section] != null) ...[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                                          child: Text(
                                            section,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                        ...grouped[section]!.map((c) => _ConversationRow(
                                              conversation: c,
                                              timeLabel: _timeLabel(c.updatedAt),
                                              onTap: () => _openConversation(c),
                                              onDelete: () => _confirmDelete(c),
                                            )),
                                      ],
                                  ],
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.accentBlue.withValues(alpha: 0.15),
                  AppColors.accentViolet.withValues(alpha: 0.15),
                ]),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ShaderMask(
                shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                child: const Icon(Icons.history_rounded, size: 38, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text('No conversations yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Chats you start will show up here automatically.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final ConversationEntity conversation;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationRow({
    required this.conversation,
    required this.timeLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // deletion is handled by the confirm dialog + Firestore stream removing it
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadii.md)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  conversation.title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(timeLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
