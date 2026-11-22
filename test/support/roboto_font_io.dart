import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the Roboto fonts that Material uses on Android and the web.
///
/// Widget tests use Ahem by default, whose glyphs are much wider than Roboto.
/// Layout tests that measure real text therefore need the real font.
Future<void> loadRobotoFont() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final flutterRoot = _flutterRoot();
  final fontDirectory = Directory(
    '${flutterRoot.path}/bin/cache/artifacts/material_fonts',
  );
  if (!fontDirectory.existsSync()) {
    throw StateError(
      'Roboto fonts not found at ${fontDirectory.path}. '
      'Run the layout tests through the Flutter tool.',
    );
  }

  final loader = FontLoader('Roboto');
  for (final name in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]) {
    final bytes = await File('${fontDirectory.path}/$name').readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Directory _flutterRoot() {
  final environmentRoot = Platform.environment['FLUTTER_ROOT'];
  if (environmentRoot != null && environmentRoot.isNotEmpty) {
    return Directory(environmentRoot);
  }

  // .../flutter/bin/cache/dart-sdk/bin/dart
  var directory = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 4; i++) {
    directory = directory.parent;
  }
  return directory;
}
