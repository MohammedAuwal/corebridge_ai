import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI-level preferences. These are currently in-memory only (reset on
/// app restart) — persisting them to Firestore is a follow-up task,
/// not wired yet, so behavior here is intentionally scoped to what's
/// real: the controls work and update immediately in this session,
/// but nothing is silently faked as "saved forever" yet.
final responseStyleProvider = StateProvider<String>((ref) => 'Balanced');
final contextLengthProvider = StateProvider<String>((ref) => 'Long');
final codeModeProvider = StateProvider<bool>((ref) => true);
final privacyModeProvider = StateProvider<bool>((ref) => false);
final emailNotificationsProvider = StateProvider<bool>((ref) => true);
final inAppNotificationsProvider = StateProvider<bool>((ref) => true);
final tipsNotificationsProvider = StateProvider<bool>((ref) => false);
