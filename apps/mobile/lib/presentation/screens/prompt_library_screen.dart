import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

// Local state for the active category filter
final _activePromptCategoryProvider = StateProvider<String>((ref) => 'All Prompts');

class PromptLibraryScreen extends ConsumerWidget {
  const PromptLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCategory = ref.watch(_activePromptCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          _buildSearchBar(),
          _buildCategories(ref, activeCategory),
          _buildGrid(activeCategory),
          _buildCreatePromo(),
          _buildPopularCollections(),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
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
                const Text('Prompt Library', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Discover, use and save powerful prompts to get better results.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
                        Text('New Prompt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                          hintText: 'Search prompts...',
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
            _dropdownButton('All Categories'),
            const SizedBox(width: 12),
            _dropdownButton('Sort by: Popular'),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded, color: AppColors.accentViolet, size: 18),
                    onTap: () {},
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                    padding: EdgeInsets.zero,
                  ),
                  Container(width: 1, height: 24, color: AppColors.border),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.textMuted, size: 18),
                    onTap: () {},
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

  Widget _dropdownButton(String label) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildCategories(WidgetRef ref, String activeCategory) {
    final categories = [
      _Category('All Prompts', Icons.grid_view_rounded, 286, AppColors.accentViolet),
      _Category('Writing', Icons.edit_rounded, 64, AppColors.accentViolet),
      _Category('Code', Icons.code_rounded, 58, Colors.greenAccent),
      _Category('Business', Icons.work_rounded, 52, Colors.orangeAccent),
      _Category('Marketing', Icons.campaign_rounded, 38, Colors.pinkAccent),
      _Category('Education', Icons.school_rounded, 28, Colors.tealAccent),
    ];

    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Row(
          children: categories.map((cat) {
            final isActive = activeCategory == cat.name;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => ref.read(_activePromptCategoryProvider.notifier).state = cat.name,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isActive ? cat.color.withValues(alpha: 0.05) : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: isActive ? cat.color.withValues(alpha: 0.5) : AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isActive ? cat.color.withValues(alpha: 0.15) : AppColors.canvas,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: isActive ? cat.color : cat.color.withValues(alpha: 0.8), size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(cat.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(cat.count.toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  SliverPadding _buildGrid(String activeCategory) {
    // Filter logic placeholder for when you hook up the real stream
    final filteredPrompts = activeCategory == 'All Prompts' 
        ? _mockPrompts 
        : _mockPrompts.where((p) => p.category == activeCategory).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 350,
          mainAxisExtent: 280,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _PromptCard(prompt: filteredPrompts[index]),
          childCount: filteredPrompts.length,
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCreatePromo() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
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
                decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: AppColors.accentBlue, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create your own prompt', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Save your custom prompts and use them anytime you need.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, color: AppColors.accentViolet),
                label: const Text('Create Prompt', style: TextStyle(color: AppColors.accentViolet, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
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

  SliverToBoxAdapter _buildPopularCollections() {
    final collections = [
      _Collection('Content Creation Kit', '12 prompts', 'Everything you need for content creation', Icons.edit_rounded, AppColors.accentViolet),
      _Collection('Developer Toolkit', '15 prompts', 'Essential prompts for developers', Icons.code_rounded, Colors.greenAccent),
      _Collection('Marketing Mastery', '11 prompts', 'Marketing prompts that drive results', Icons.campaign_rounded, Colors.pinkAccent),
      _Collection('Business Essentials', '10 prompts', 'Core business prompts for success', Icons.work_rounded, Colors.orangeAccent),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 0, 0), // No right padding for scroll bleed
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Popular Collections', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('View all', style: TextStyle(color: AppColors.accentBlue))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: collections.map((col) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: col.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(col.icon, color: col.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(col.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(col.count, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Text(col.desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                          ],
                        )
                      ],
                    ),
                  ),
                )).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- Prompt Card Widget ---
class _PromptCard extends StatelessWidget {
  final _Prompt prompt;
  const _PromptCard({required this.prompt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: prompt.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(prompt.icon, color: prompt.color, size: 22),
              ),
              Icon(prompt.isStarred ? Icons.star_border_rounded : Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
          const Spacer(),
          Text(prompt.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            prompt.description,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: prompt.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(prompt.category, style: TextStyle(color: prompt.color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_outlined, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 6),
                  Text(prompt.views, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 14),
                    SizedBox(width: 6),
                    Text('Use', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

// --- Mock Data Models ---
class _Category {
  final String name;
  final IconData icon;
  final int count;
  final Color color;
  const _Category(this.name, this.icon, this.count, this.color);
}

class _Collection {
  final String title;
  final String count;
  final String desc;
  final IconData icon;
  final Color color;
  const _Collection(this.title, this.count, this.desc, this.icon, this.color);
}

class _Prompt {
  final String title;
  final String description;
  final String category;
  final String views;
  final IconData icon;
  final Color color;
  final bool isStarred;

  const _Prompt(this.title, this.description, this.category, this.views, this.icon, this.color, this.isStarred);
}

const _mockPrompts = [
  _Prompt(
    'Blog Post Writer',
    'Generate engaging, SEO-friendly blog posts on any topic with structured headings.',
    'Writing',
    '12.4K',
    Icons.description_rounded,
    AppColors.accentViolet,
    true,
  ),
  _Prompt(
    'Code Explainer',
    'Explain complex code in simple terms with examples and best practices.',
    'Code',
    '9.8K',
    Icons.code_rounded,
    Colors.greenAccent,
    true,
  ),
  _Prompt(
    'Business Plan Generator',
    'Create a complete business plan with market analysis, strategy and financial projections.',
    'Business',
    '7.6K',
    Icons.bar_chart_rounded,
    Colors.orangeAccent,
    true,
  ),
  _Prompt(
    'Social Media Post',
    'Create engaging social media posts tailored to different platforms and audiences.',
    'Marketing',
    '8.1K',
    Icons.campaign_rounded,
    Colors.pinkAccent,
    false,
  ),
  _Prompt(
    'Study Guide Creator',
    'Generate comprehensive study guides, summaries and practice questions.',
    'Education',
    Icons.school_rounded,
    '6.3K',
    Colors.tealAccent,
    false,
  ),
  _Prompt(
    'Email Writer',
    'Write professional emails for different scenarios and purposes.',
    'Writing',
    '5.7K',
    Icons.email_rounded,
    AppColors.accentViolet,
    false,
  ),
  _Prompt(
    'Idea Generator',
    'Generate creative ideas and solutions for any problem or challenge.',
    'Business',
    '5.2K',
    Icons.lightbulb_rounded,
    Colors.orangeAccent,
    false,
  ),
  _Prompt(
    'Content Outline',
    'Create detailed content outlines and structures for articles, reports or presentations.',
    'Writing',
    '4.9K',
    Icons.format_list_bulleted_rounded,
    AppColors.accentViolet,
    false,
  ),
  _Prompt(
    'Excel Formula Helper',
    'Generate and explain Excel formulas for data analysis and calculations.',
    'Code',
    '4.1K',
    Icons.grid_on_rounded,
    Colors.greenAccent,
    false,
  ),
];
