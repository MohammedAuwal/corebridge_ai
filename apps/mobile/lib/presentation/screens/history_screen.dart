import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerId = ref.watch(firebaseServiceProvider).currentUserId;
    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }

    final conversationsStream = ref.watch(conversationRepositoryProvider).watchConversations(ownerId);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder(
        stream: conversationsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final conversations = snapshot.data!;
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                title: Text(conversation.title),
                subtitle: Text(conversation.updatedAt.toLocal().toString()),
              );
            },
          );
        },
      ),
    );
  }
}
