import 'package:flutter_test/flutter_test.dart';

import 'package:gdms_app/src/app/gdms_app.dart';

void main() {
  testWidgets('renders the sign-in flow', (tester) async {
    await tester.pumpWidget(const GdmsApp());
    await tester.pumpAndSettle();

    expect(find.text('Ingreso al GDMS'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);

    await tester.tap(find.text('Organización admin'));
    await tester.pumpAndSettle();

    expect(find.text('Crear administrador de organización'), findsOneWidget);
  });
}
