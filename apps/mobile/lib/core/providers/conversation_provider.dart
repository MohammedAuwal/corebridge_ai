import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Firestore conversation currently open in ChatScreen.
/// null means "no conversation yet" — one gets created on first send.
/// Set this to null before navigating to /chat to force a brand-new
/// conversation (e.g. tapping "Chat" in the drawer, or sending from Home).
/// Set it to an existing id when resuming from History.
final activeConversationIdProvider = StateProvider<String?>((ref) => null);
