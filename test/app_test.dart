import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/app.dart';

void main() {
  testWidgets('zeigt das deutsche Grundgerüst der App', (tester) async {
    await tester.pumpWidget(const HpCprApp());
    await tester.pumpAndSettle();

    expect(find.text('HP-CPR'), findsOneWidget);
    expect(find.text('Reanimations-Tracker'), findsOneWidget);
    expect(find.text('Reanimationsdauer'), findsOneWidget);
    expect(find.text('Reanimation starten'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Projekt eingerichtet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Projekt eingerichtet'), findsOneWidget);
  });
}
