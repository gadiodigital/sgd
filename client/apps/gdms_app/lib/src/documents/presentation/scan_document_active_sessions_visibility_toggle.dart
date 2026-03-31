import 'package:flutter/material.dart';

class ScanDocumentActiveSessionsVisibilityToggle extends StatelessWidget {
  const ScanDocumentActiveSessionsVisibilityToggle({
    required this.totalCount,
    required this.isExpanded,
    required this.onToggleRequested,
    super.key,
  });

  final int totalCount;
  final bool isExpanded;
  final VoidCallback onToggleRequested;

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 6) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isExpanded
              ? 'Se muestran $totalCount sesiones filtradas.'
              : 'Se muestran 6 de $totalCount sesiones filtradas.',
        ),
        TextButton(
          onPressed: onToggleRequested,
          child: Text(isExpanded ? 'Ver menos' : 'Ver todas'),
        ),
      ],
    );
  }
}
