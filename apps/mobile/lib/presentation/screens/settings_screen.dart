import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../data/repositories_impl/user_settings_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _claudeController = TextEditingController();
  final _openaiController = TextEditingController();
  final _geminiController = TextEditingController();
  final _qwenController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;

    final repo = UserSettingsRepository(ref.read(firestoreProvider));
    final keys = await repo.getApiKeys(uid);

    setState(() {
      _claudeController.text = keys.claude ?? '';
      _openaiController.text = keys.openai ?? '';
      _geminiController.text = keys.gemini ?? '';
      _qwenController.text = keys.qwen ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveKeys() async {
    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;

    setState(() => _isSaving = true);

    final repo = UserSettingsRepository(ref.read(firestoreProvider));
    await repo.saveApiKeys(
      uid,
      UserApiKeys(
        claude: _claudeController.text.trim(),
        openai: _openaiController.text.trim(),
        gemini: _geminiController.text.trim(),
        qwen: _qwenController.text.trim(),
      ),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API keys saved.')),
      );
    }
  }

  @override
  void dispose() {
    _claudeController.dispose();
    _openaiController.dispose();
    _geminiController.dispose();
    _qwenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('AI Providers', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Add your own API keys. They\'re stored privately on your account '
                  'and sent only to that provider when you chat.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _claudeController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Anthropic (Claude)',
                    hintText: 'sk-ant-...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _openaiController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'OpenAI',
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _geminiController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Google Gemini',
                    hintText: 'AIza...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qwenController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Qwen (Alibaba)',
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveKeys,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save keys'),
                ),
                const Divider(height: 40),
                ListTile(
                  title: const Text('Sign out'),
                  leading: const Icon(Icons.logout),
                  onTap: () => ref.read(firebaseServiceProvider).signOut(),
                ),
              ],
            ),
    );
  }
}
