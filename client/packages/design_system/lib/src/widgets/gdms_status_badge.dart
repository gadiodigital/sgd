import 'package:flutter/material.dart';

/// Represents the visual tone for status badges.
enum GdmsStatusTone { neutral, info, success, warning, critical }

/// Renders a compact semantic status pill.
class GdmsStatusBadge extends StatelessWidget {
  const GdmsStatusBadge({
    required this.label,
    super.key,
    this.tone = GdmsStatusTone.neutral,
  });

  final String label;
  final GdmsStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _BadgeColors _toneColors(BuildContext context, GdmsStatusTone tone) {
    final scheme = Theme.of(context).colorScheme;

    return switch (tone) {
      GdmsStatusTone.info => _BadgeColors(
        background: scheme.primary.withValues(alpha: 0.12),
        border: scheme.primary.withValues(alpha: 0.2),
        foreground: scheme.primary,
      ),
      GdmsStatusTone.success => _BadgeColors(
        background: const Color(0xFF1E8A5B).withValues(alpha: 0.12),
        border: const Color(0xFF1E8A5B).withValues(alpha: 0.24),
        foreground: const Color(0xFF1E8A5B),
      ),
      GdmsStatusTone.warning => _BadgeColors(
        background: const Color(0xFFC4811C).withValues(alpha: 0.14),
        border: const Color(0xFFC4811C).withValues(alpha: 0.24),
        foreground: const Color(0xFFA5670E),
      ),
      GdmsStatusTone.critical => _BadgeColors(
        background: scheme.error.withValues(alpha: 0.12),
        border: scheme.error.withValues(alpha: 0.2),
        foreground: scheme.error,
      ),
      GdmsStatusTone.neutral => _BadgeColors(
        background: scheme.surfaceContainerHighest,
        border: scheme.outlineVariant,
        foreground: scheme.onSurfaceVariant,
      ),
    };
  }
}

final class _BadgeColors {
  const _BadgeColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
