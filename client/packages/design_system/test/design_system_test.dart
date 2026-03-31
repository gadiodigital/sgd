import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:design_system/design_system.dart';

void main() {
  testWidgets('renders reusable design system widgets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GdmsTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              GdmsPageHeader(title: 'Header', subtitle: 'Subtitle'),
              GdmsMetricTile(label: 'Metric', value: '12', color: Colors.teal),
              GdmsStatusBadge(label: 'Activo', tone: GdmsStatusTone.success),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Metric'), findsOneWidget);
    expect(find.text('Activo'), findsOneWidget);
  });
}
