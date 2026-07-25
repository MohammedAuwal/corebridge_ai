import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single GlobalKey shared by AppShell's Scaffold and any screen that
/// needs to open the drawer. Using a key instead of Scaffold.of(context)
/// avoids the common bug where a screen wraps itself in its own nested
/// Scaffold, which shadows the outer one that actually owns the drawer.
final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});
