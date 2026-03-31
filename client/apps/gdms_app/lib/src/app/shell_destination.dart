import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';

/// Represents one top-level destination in the GDMS shell.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.child,
    required this.sessionViewModel,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
  final AppSessionViewModel sessionViewModel;
}
