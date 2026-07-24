import 'package:flutter/material.dart';

class PromptLibraryScreen extends StatelessWidget {
  const PromptLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prompt Library')),
      body: const Center(child: Text('Your saved and reusable prompts will appear here.')),
    );
  }
}
