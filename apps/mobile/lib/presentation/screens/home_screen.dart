import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/providers/conversation_provider.dart';
import '../widgets/geo_mesh_background.dart';
import '../widgets/chat_composer.dart';
import '../widgets/model_selector_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(firebaseServiceProvider).auth.currentUser?.email ?? '';
    final name = email.contains('@') ? email.split('@').first : 'there';

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GeoMeshBackground()),
          Column(
            children: [
              const ModelSelectorBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_greeting()}, $name! 👋', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text('What will you build or explore today?', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Spacer(),
              ChatComposer(
                isSending: false,
                onSend: (text) {
                  ref.read(activeConversationIdProvider.notifier).state = null;
                  ref.read(draftMessageProvider.notifier).state = text;
                  context.go('/chat');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
