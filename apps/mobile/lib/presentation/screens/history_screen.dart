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
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: Text('Not signed in.', style: TextStyle(color: AppColors.textPrimary))),
      );
    }

    final conversationsStream = ref.watch(conversationRepositoryProvider).watchConversations(ownerId);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: GeoMeshBackground()),
          StreamBuilder<List<ConversationEntity>>(
            stream: conversationsStream,
            builder: (context, snapshot) {
              final isLoading = snapshot.connectionState == ConnectionState.waiting;
              final hasError = snapshot.hasError;
              
              List<ConversationEntity> all = [];
              Map<String, List<ConversationEntity>> grouped = {};
              
              if (snapshot.hasData) {
                all = snapshot.data!;
                grouped = _groupAndFilter(all);
              }

              return CustomScrollView(
                slivers: [
                  _buildHeader(),
                  _buildSearchBar(),
                  if (isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
                    )
                  else if (hasError)
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Could not load conversations: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                        ),
                      ),
                    )
                  else if (all.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    )
                  else if (grouped.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No results for "$_query"', style: const TextStyle(color: AppColors.textMuted))),
                    )
                  else
                    _buildConversationList(grouped),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildHeader() {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('History', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Review and manage your past AI conversations.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
                    onTap: () {
                      ref.read(activeConversationIdProvider.notifier).state = null;
                      context.go('/chat');
                    },
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('New Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                InkWell(
                  onTap: () => setState(() {
                    _searchController.clear();
                    _query = '';
                  }),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  SliverList _buildConversationList(Map<String, List<ConversationEntity>> grouped) {
    final widgets = <Widget>[];

    for (final section in _sectionOrder) {
      if (grouped[section] != null && grouped[section]!.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                Text(
                  section.toUpperCase(),
                  style: const TextStyle(color: AppColors.accentBlue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 1, color: AppColors.border)),
              ],
            ),
          ),
        );

        for (final conversation in grouped[section]!) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: _ConversationCard(
                conversation: conversation,
                timeLabel: _timeLabel(conversation.updatedAt),
                onTap: () => _openConversation(conversation),
                onDelete: () => _confirmDelete(conversation),
              ),
            ),
          );
        }
      }
    }

    return SliverList(delegate: SliverChildListDelegate(widgets));
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
                child: const Icon(Icons.history_rounded, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text('No conversations yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Chats you start will automatically be saved here so you can pick up exactly where you left off.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(activeConversationIdProvider.notifier).state = null;
                context.go('/chat');
              },
              icon: const Icon(Icons.add_rounded, color: AppColors.accentBlue),
              label: const Text('Start a new chat', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ConversationEntity conversation;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationCard({
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
        return false; 
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15), 
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.accentBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.title.isNotEmpty ? conversation.title : 'New Conversation',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(timeLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
