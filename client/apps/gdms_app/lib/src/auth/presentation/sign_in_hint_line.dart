import 'package:flutter/material.dart';

/// Displays a compact environment hint within the sign-in flow.
class AuthHintLine extends StatelessWidget {
  const AuthHintLine({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        SelectableText(value),
      ],
    );
  }
}
