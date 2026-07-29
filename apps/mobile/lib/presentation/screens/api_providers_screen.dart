import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/ai_models.dart';
import '../../core/di/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_api_keys.dart';

class ApiProvidersScreen extends ConsumerStatefulWidget {
  const ApiProvidersScreen({super.key});

  @override
  ConsumerState<ApiProvidersScreen> createState() => _ApiProvidersScreenState();
}

class _ProviderMeta {
  final String key;
  final String name;
  final Color color;
  final IconData icon;
  const _ProviderMeta(this.key, this.name, this.color, this.icon);
}

class _ApiProvidersScreenState extends ConsumerState<ApiProvidersScreen> {
  UserApiKeys _keys = const UserApiKeys();
  bool _isLoading = true;
  String? _detectingProvider;

  static const _providers = [
    _ProviderMeta('claude', 'Anthropic (Claude)', Color(0xFFD97757), Icons.auto_awesome_rounded),
    _ProviderMeta('openai', 'OpenAI', Color(0xFF10A37F), Icons.bubble_chart_rounded),
    _ProviderMeta('gemini', 'Google Gemini', Color(0xFF4285F4), Icons.diamond_rounded),
    _ProviderMeta('qwen', 'Qwen (Alibaba)', Color(0xFF6236FF), Icons.hub_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;
    final keys = await ref.read(userSettingsRepositoryProvider).getApiKeys(uid);
    if (mounted) setState(() {
      _keys = keys;
      _isLoading = false;
    });
  }

  String? _keyFor(String provider) => _keys.forProvider(provider);

  Future<void> _save(UserApiKeys updated) async {
    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;
    await ref.read(userSettingsRepositoryProvider).saveApiKeys(uid, updated);
    if (mounted) setState(() => _keys = updated);
  }

  /// Persists which provider Chat should open with. Read once per app
  /// session by ChatScreen (see defaultProviderAppliedProvider) so it
  /// doesn't fight with manual switches made later in the same session.
  Future<void> _setDefault(String providerKey) async {
    await _save(_keys.copyWith(defaultProvider: providerKey));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_providers.firstWhere((p) => p.key == providerKey).name} set as your default')),
      );
    }
  }

  Future<void> _autoDetectModel(String providerKey, String apiKey) async {
    if (apiKey.trim().isEmpty) return;

    setState(() => _detectingProvider = providerKey);
    try {
      final models = await ref.read(aiRouterClientProvider).listModels(
            provider: providerKey,
            apiKey: apiKey,
          );

      if (models.isEmpty) return;

      final updated = _applyModel(providerKey, models.first);
      await _save(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detected model for this key: ${models.first}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't auto-detect a model for this key. Using the default — you can set one manually via \"Edit model\" if it doesn't work.")),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingProvider = null);
    }
  }

  Future<void> _showKeyDialog(_ProviderMeta provider, {bool isEdit = false}) async {
    final controller = TextEditingController(text: isEdit ? (_keyFor(provider.key) ?? '') : '');

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: Text(isEdit ? 'Update ${provider.name} key' : 'Connect ${provider.name}'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Paste your API key'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      var updated = _applyKey(provider.key, result);
      // First-ever connected provider becomes the default automatically
      // — most users only ever connect one, and this way "def is the
      // one in the chat screen" holds true without an extra tap.
      final hadNoDefault = (_keys.defaultProvider ?? '').isEmpty;
      if (hadNoDefault) {
        updated = updated.copyWith(defaultProvider: provider.key);
      }
      await _save(updated);
      unawaited(_autoDetectModel(provider.key, result));
    }
  }

  Future<void> _showModelDialog(_ProviderMeta provider) async {
    final currentDefault = AiModels.defaultFor(provider.key);
    final controller = TextEditingController(text: _keys.modelFor(provider.key) == currentDefault ? '' : _keys.modelFor(provider.key));

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: Text('${provider.name} model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the exact model string your API key works with. Leave blank to use auto-detection / the current default ($currentDefault).',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: currentDefault),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final updated = _applyModel(provider.key, result);
      await _save(updated);
    }
  }

  Future<void> _removeKey(_ProviderMeta provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: Text('Remove ${provider.name} key?'),
        content: const Text('You will need to add it again to use this provider.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      var updated = _applyKey(provider.key, '');
      updated = _applyModel(provider.key, updated);
      // Clear the default if this provider WAS the default — leaving a
      // default pointing at a removed key would silently break Chat.
      if (_keys.defaultProvider == provider.key) {
        updated = updated.copyWith(defaultProvider: '');
      }
      await _save(updated);
    }
  }

  UserApiKeys _applyKey(String providerKey, String value) {
    switch (providerKey) {
      case 'claude':
        return _keys.copyWith(claude: value);
      case 'openai':
        return _keys.copyWith(openai: value);
      case 'gemini':
        return _keys.copyWith(gemini: value);
      case 'qwen':
        return _keys.copyWith(qwen: value);
      default:
        return _keys;
    }
  }

  UserApiKeys _applyModel(String providerKey, [String value = '']) {
    switch (providerKey) {
      case 'claude':
        return _keys.copyWith(claudeModel: value);
      case 'openai':
        return _keys.copyWith(openaiModel: value);
      case 'gemini':
        return _keys.copyWith(geminiModel: value);
      case 'qwen':
        return _keys.copyWith(qwenModel: value);
      default:
        return _keys;
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _providers.where((p) => (_keyFor(p.key) ?? '').isNotEmpty).toList();
    final available = _providers.where((p) => (_keyFor(p.key) ?? '').isEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('API Providers')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Connect your AI provider API keys. We automatically detect which model works with your key, and your default provider is the one Chat opens with.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Connected Providers', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    if (available.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _showAddProviderSheet(available),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Provider'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (connected.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No providers connected yet.', style: Theme.of(context).textTheme.bodyMedium),
                  )
                else
                  ...connected.map((p) => _buildProviderTile(p, isDefault: p.key == _keys.defaultProvider)),
                if (available.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Available Providers', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...available.map((p) => _buildAvailableTile(p)),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.accentBlue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your keys are safe and secure', style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 2),
                            Text(
                              'Keys are stored in your private Firestore user profile and only ever leave your account to reach the provider you chose, via CoreBridge\'s Edge Function router.',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProviderTile(_ProviderMeta provider, {required bool isDefault}) {
    final resolvedModel = _keys.modelFor(provider.key);
    final isDetecting = _detectingProvider == provider.key;

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
            decoration: BoxDecoration(color: provider.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadii.sm)),
            alignment: Alignment.center,
            child: Icon(provider.icon, color: provider.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(provider.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Default', style: TextStyle(color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                if (isDetecting)
                  const Text('Detecting your model…', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                else
                  Text('Model: $resolvedModel', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (isDetecting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.greenAccent),
                  SizedBox(width: 4),
                  Text('Connected', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 18),
            color: AppColors.surfaceRaised,
            onSelected: (value) {
              if (value == 'edit') _showKeyDialog(provider, isEdit: true);
              if (value == 'model') _showModelDialog(provider);
              if (value == 'redetect') _autoDetectModel(provider.key, _keyFor(provider.key) ?? '');
              if (value == 'setDefault') _setDefault(provider.key);
              if (value == 'remove') _removeKey(provider);
            },
            itemBuilder: (context) => [
              if (!isDefault) const PopupMenuItem(value: 'setDefault', child: Text('Set as default')),
              const PopupMenuItem(value: 'edit', child: Text('Edit key')),
              const PopupMenuItem(value: 'model', child: Text('Edit model')),
              const PopupMenuItem(value: 'redetect', child: Text('Re-detect model')),
              const PopupMenuItem(value: 'remove', child: Text('Remove key')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTile(_ProviderMeta provider) {
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
            decoration: BoxDecoration(color: provider.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.sm)),
            alignment: Alignment.center,
            child: Icon(provider.icon, color: provider.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(provider.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => _showKeyDialog(provider),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showAddProviderSheet(List<_ProviderMeta> available) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: available.map((p) => ListTile(
            leading: Icon(p.icon, color: p.color),
            title: Text(p.name),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.pop(sheetContext);
              _showKeyDialog(p);
            },
          )).toList(),
        ),
      ),
    );
  }
}
