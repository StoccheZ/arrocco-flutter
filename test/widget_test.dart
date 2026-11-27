import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:arrocco/app.dart';

void main() {
  testWidgets('La barra in basso cambia scheda', (WidgetTester tester) async {
    await tester.pumpWidget(const ArroccoApp());

    expect(find.text('Home in arrivo'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.extension));
    await tester.pumpAndSettle();

    expect(find.text('Puzzle del giorno in arrivo'), findsOneWidget);
  });
}
