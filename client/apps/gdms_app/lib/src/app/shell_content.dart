import 'package:flutter/material.dart';

import 'shell_banner.dart';
import 'shell_destination.dart';

/// Hosts the shared banner and section container for one shell destination.
class ShellContent extends StatelessWidget {
  const ShellContent({required this.destination, super.key});

  final ShellDestination destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: ShellBanner(sessionViewModel: destination.sessionViewModel),
        ),
        Expanded(
          child: Semantics(
            container: true,
            label: 'Seccion ${destination.label}',
            child: destination.child,
          ),
        ),
      ],
    );
  }
}
