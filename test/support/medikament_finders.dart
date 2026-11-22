import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Both medication cards use the same "Gabe erfassen" label; Adrenalin is
/// laid out above Amiodaron.
final adrenalinGabe = find.text('Gabe erfassen').first;
final amiodaronGabe = find.text('Gabe erfassen').last;

bool isButtonEnabled(WidgetTester tester, Finder label) {
  final button = tester.widget<FilledButton>(
    find.ancestor(of: label, matching: find.byType(FilledButton)),
  );
  return button.onPressed != null;
}
