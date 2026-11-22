import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/signal_detector.dart';

import 'support/fake_clock.dart';

void main() {
  late FakeClock clock;
  late Reanimationsfall fall;
  late SignalDetector detector;

  Reanimationsfall startFall({bool vibrationEnabled = true}) =>
      Reanimationsfall.start(clock: clock, vibrationEnabled: vibrationEnabled);

  List<SignalAnlass> check() => detector.update(fall.snapshot());

  setUp(() {
    clock = FakeClock();
    fall = startFall();
    detector = SignalDetector();
    check(); // seeds
  });

  test('the first snapshot only seeds and never signals', () {
    clock.advance(const Duration(minutes: 3));
    final late = startFall();
    clock.advance(const Duration(minutes: 3));
    expect(late.snapshot().isRhythmusanalyseDue, isTrue);

    expect(SignalDetector().update(late.snapshot()), isEmpty);
  });

  test('signals once when the Rhythmusanalyse becomes due', () {
    clock.advance(const Duration(seconds: 119));
    expect(check(), isEmpty);

    clock.advance(const Duration(seconds: 1));
    expect(check(), [SignalAnlass.rhythmusanalyseFaellig]);

    clock.advance(const Duration(seconds: 10));
    expect(check(), isEmpty);
    expect(check(), isEmpty);
  });

  test('does not signal when the pause exceeds the target', () {
    fall.enterAnalysephase();
    check();
    clock.advance(const Duration(seconds: 30));

    expect(fall.snapshot().isPauseOverdue, isTrue);
    expect(check(), isEmpty);
  });

  test('signals the first Adrenalin dose when it becomes due', () {
    fall.enterAnalysephase();
    check();
    fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.asystolie);

    expect(check(), [SignalAnlass.ersteAdrenalinGabeFaellig]);
    expect(check(), isEmpty);
  });

  test(
    'signals the Adrenalin Zeitfenster becoming faellig and ueberfaellig',
    () {
      fall.recordAdrenalin();
      check();

      // The Rhythmusanalyse is due at 2:00 as well; only look at Adrenalin.
      List<SignalAnlass> adrenalin() =>
          check().where((a) => a.name.startsWith("adrenalin")).toList();

      clock.advance(const Duration(minutes: 2, seconds: 59));
      expect(adrenalin(), isEmpty);

      clock.advance(const Duration(seconds: 1));
      expect(adrenalin(), [SignalAnlass.adrenalinFaellig]);
      expect(adrenalin(), isEmpty);

      clock.advance(const Duration(minutes: 2, seconds: 1));
      expect(adrenalin(), [SignalAnlass.adrenalinUeberfaellig]);
      expect(adrenalin(), isEmpty);
    },
  );

  test('signals when the Amiodaron hint becomes active', () {
    fall.recordSchock();
    fall.recordSchock();
    expect(check(), isEmpty);

    fall.recordSchock();
    expect(check(), [SignalAnlass.amiodaronHinweis]);
    expect(check(), isEmpty);
  });

  test('signals the second Amiodaron hint again', () {
    for (var i = 0; i < 3; i++) {
      fall.recordSchock();
    }
    check();
    fall.recordAmiodaron();
    expect(check(), isEmpty);

    for (var i = 0; i < 2; i++) {
      fall.recordSchock();
    }
    expect(check(), [SignalAnlass.amiodaronHinweis]);
  });

  test('does not signal when vibration is disabled for the case', () {
    fall = startFall(vibrationEnabled: false);
    detector = SignalDetector();
    check();

    clock.advance(const Duration(minutes: 2));
    expect(fall.snapshot().isRhythmusanalyseDue, isTrue);
    expect(check(), isEmpty);
  });

  test('does not signal during ROSC and does not catch up afterwards', () {
    fall.recordRosc();
    check();

    clock.advance(const Duration(minutes: 3));
    expect(check(), isEmpty);
  });

  test('does not signal after the case ended', () {
    fall.endReanimationsfall(Beendigungsgrund.uebergabe);
    check();

    clock.advance(const Duration(minutes: 3));
    expect(check(), isEmpty);
  });

  test('does not signal after the case was discarded', () {
    fall.discardReanimationsfall();
    check();

    clock.advance(const Duration(minutes: 3));
    expect(check(), isEmpty);
  });
}
