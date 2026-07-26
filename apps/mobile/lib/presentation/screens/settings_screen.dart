import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/providers/app_preferences_provider.dart';
import '../../core/providers/selected_model_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _displayName;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;
    final doc = await ref.read(firestoreProvider).collection('users').doc(uid).get();
    if (mounted) {
      setState(() {
        _displayName = doc.data()?['displayName'] as String?;
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: _displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: const Text('Edit profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Display name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (result != null) {
      final uid = ref.read(firebaseServiceProvider).currentUserId;
      if (uid == null) return;
      await ref.read(firestoreProvider).collection('users').doc(uid).set(
        {'displayName': result, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
        SetOptions(merge: true),
      );
      if (mounted) setState(() => _displayName = result);
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: const Text('Clear conversation history?'),
        content: const Text('This permanently deletes all your conversations. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete all', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;

    final conversations = await ref.read(conversationRepositoryProvider).watchConversations(uid).first;
    for (final conversation in conversations) {
      await ref.read(conversationRepositoryProvider).deleteConversation(conversation.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${conversations.length} conversation(s).')),
      );
    }
  }

  Future<void> _pickResponseStyle() async {
    final result = await _showOptionSheet(['Concise', 'Balanced', 'Detailed'], ref.read(responseStyleProvider));
    if (result != null) ref.read(responseStyleProvider.notifier).state = result;
  }

  Future<void> _pickContextLength() async {
    final result = await _showOptionSheet(['Short', 'Medium', 'Long'], ref.read(contextLengthProvider));
    if (result != null) ref.read(contextLengthProvider.notifier).state = result;
  }

  Future<String?> _showOptionSheet(List<String> options, String current) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((o) => ListTile(
            title: Text(o),
            trailing: o == current ? const Icon(Icons.check_rounded, color: AppColors.accentBlue) : null,
            onTap: () => Navigator.pop(sheetContext, o),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(firebaseServiceProvider).auth.currentUser?.email ?? '';
    final selectedModel = ref.watch(selectedModelProvider);
    final responseStyle = ref.watch(responseStyleProvider);
    final contextLength = ref.watch(contextLengthProvider);
    final codeMode = ref.watch(codeModeProvider);
    final privacyMode = ref.watch(privacyModeProvider);
    final emailNotif = ref.watch(emailNotificationsProvider);
    final inAppNotif = ref.watch(inAppNotificationsProvider);
    final tipsNotif = ref.watch(tipsNotificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionCard(
            title: 'Profile',
            subtitle: 'Manage your personal information.',
            trailing: TextButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
            ),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      (_displayName?.isNotEmpty == true ? _displayName![0] : (email.isNotEmpty ? email[0] : '?')).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingProfile ? '…' : (_displayName?.isNotEmpty == true ? _displayName! : email.split('@').first),
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          _sectionCard(
            title: 'Appearance',
            subtitle: 'Customize the look and feel of CoreBridge AI.',
            children: [
              _row(
                icon: Icons.wb_sunny_outlined,
                label: 'Theme',
                trailing: Container(
                  decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _themeChip('Light', selected: false, onTap: () => _showComingSoon('Light theme')),
                      _themeChip('Dark', selected: true, onTap: () {}),
                      _themeChip('System', selected: false, onTap: () => _showComingSoon('System theme')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _row(
                icon: Icons.palette_outlined,
                label: 'Accent Color',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _accentDot(AppColors.accentBlue, isSelected: true),
                    _accentDot(Colors.blueAccent, isSelected: false),
                    _accentDot(Colors.greenAccent.shade400, isSelected: false),
                    _accentDot(Colors.orangeAccent, isSelected: false),
                    _accentDot(Colors.pinkAccent, isSelected: false),
                  ],
                ),
              ),
            ],
          ),
          _sectionCard(
            title: 'AI Preferences',
            subtitle: 'Control how the AI behaves and responds.',
            children: [
              _row(
                icon: Icons.smart_toy_outlined,
                label: 'Default Model',
                subtitle: 'Choose the default AI model.',
                trailing: _chevronValue(selectedModel.label),
                onTap: null, // model is switched from the composer's model picker
              ),
              _row(
                icon: Icons.mood_outlined,
                label: 'Response Style',
                subtitle: 'Set the tone and style of AI responses.',
                trailing: _chevronValue(responseStyle),
                onTap: _pickResponseStyle,
              ),
              _row(
                icon: Icons.short_text_rounded,
                label: 'Context Length',
                subtitle: 'Maximum context length for conversations.',
                trailing: _chevronValue(contextLength),
                onTap: _pickContextLength,
              ),
              _row(
                icon: Icons.code_rounded,
                label: 'Code Mode',
                subtitle: 'Optimize responses for code and technical tasks.',
                trailing: Switch(
                  value: codeMode,
                  activeColor: AppColors.accentBlue,
                  onChanged: (v) => ref.read(codeModeProvider.notifier).state = v,
                ),
              ),
            ],
          ),
          _sectionCard(
            title: 'Data & Privacy',
            subtitle: 'Manage your data and privacy settings.',
            children: [
              _row(
                icon: Icons.storage_outlined,
                label: 'Data Control',
                subtitle: 'View and manage your data.',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () => _showComingSoon('Data control'),
              ),
              _row(
                icon: Icons.shield_outlined,
                label: 'Privacy Mode',
                subtitle: 'Hide history from being used for training.',
                trailing: Switch(
                  value: privacyMode,
                  activeColor: AppColors.accentBlue,
                  onChanged: (v) => ref.read(privacyModeProvider.notifier).state = v,
                ),
              ),
              _row(
                icon: Icons.delete_outline_rounded,
                label: 'Clear Conversation History',
                subtitle: 'Permanently delete all your conversations.',
                labelColor: Colors.redAccent,
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
                onTap: _clearHistory,
              ),
            ],
          ),
          _sectionCard(
            title: 'Notifications',
            subtitle: 'Manage how you receive notifications.',
            children: [
              _row(
                icon: Icons.mail_outline_rounded,
                label: 'Email Notifications',
                subtitle: 'Receive updates via email.',
                trailing: Switch(value: emailNotif, activeColor: AppColors.accentBlue, onChanged: (v) => ref.read(emailNotificationsProvider.notifier).state = v),
              ),
              _row(
                icon: Icons.notifications_none_rounded,
                label: 'In-App Notifications',
                subtitle: 'Receive notifications within the app.',
                trailing: Switch(value: inAppNotif, activeColor: AppColors.accentBlue, onChanged: (v) => ref.read(inAppNotificationsProvider.notifier).state = v),
              ),
              _row(
                icon: Icons.card_giftcard_rounded,
                label: 'Tips & Updates',
                subtitle: 'Get tips, product updates, and news.',
                trailing: Switch(value: tipsNotif, activeColor: AppColors.accentBlue, onChanged: (v) => ref.read(tipsNotificationsProvider.notifier).state = v),
              ),
            ],
          ),
          _sectionCard(
            title: 'Account',
            subtitle: 'Manage your account settings.',
            children: [
              _row(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                subtitle: 'Sign out from your account on this device.',
                labelColor: Colors.redAccent,
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
                onTap: () => ref.read(firebaseServiceProvider).signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  Widget _sectionCard({required String title, required String subtitle, Widget? trailing, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? labelColor,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: labelColor ?? AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: labelColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _chevronValue(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ],
    );
  }

  Widget _themeChip(String label, {required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _accentDot(Color color, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: () => _showComingSoon('Custom accent colors'),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          ),
        ),
      ),
    );
  }
}
