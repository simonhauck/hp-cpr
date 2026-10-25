import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_store.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';

import 'support/fake_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves, replaces, loads, and deletes a stored state', () async {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    final store = const SharedPreferencesReanimationsfallStore(key: 'test');

    await store.save(reanimationsfall.exportState());
    var loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, reanimationsfall.id);

    clock.advance(const Duration(seconds: 30));
    reanimationsfall.recordAdrenalin();
    await store.save(reanimationsfall.exportState());

    loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.adrenalinGaben, hasLength(1));

    await store.delete(reanimationsfall.id);
    expect(await store.load(), isEmpty);
  });

  test('ignores a damaged store', () async {
    SharedPreferences.setMockInitialValues({'test': 'not json'});
    final store = const SharedPreferencesReanimationsfallStore(key: 'test');

    expect(await store.load(), isEmpty);
  });
}
