import 'package:flutter/material.dart';

/// Renders a reusable section container for dashboard-like content.
class GdmsSectionCard extends StatelessWidget {
  const GdmsSectionCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: theme.textTheme.titleLarge),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(subtitle!, style: theme.textTheme.bodyMedium),
                ),
              const SizedBox(height: 18),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
