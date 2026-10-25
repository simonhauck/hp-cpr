/// The supported Messwerte types.
enum MesswertTyp { temperatur, blutzucker, blutdruck, herzfrequenz }

/// A timestamped patient observation recorded during a Reanimationsfall.
sealed class Messwert {
  const Messwert({required this.zeitpunkt, this.notiz});

  /// The elapsed time since the Startzeit when the value was recorded.
  final Duration zeitpunkt;

  /// The optional note recorded with the value.
  final String? notiz;

  MesswertTyp get typ;
}

/// A temperature in degrees Celsius.
final class TemperaturMesswert extends Messwert {
  const TemperaturMesswert({
    required super.zeitpunkt,
    required this.celsius,
    super.notiz,
  });

  final double celsius;

  @override
  MesswertTyp get typ => MesswertTyp.temperatur;
}

/// A blood sugar value in mg/dL.
final class BlutzuckerMesswert extends Messwert {
  const BlutzuckerMesswert({
    required super.zeitpunkt,
    required this.mgDl,
    super.notiz,
  });

  final int mgDl;

  @override
  MesswertTyp get typ => MesswertTyp.blutzucker;
}

/// A blood pressure in mmHg.
final class BlutdruckMesswert extends Messwert {
  const BlutdruckMesswert({
    required super.zeitpunkt,
    required this.systolisch,
    required this.diastolisch,
    super.notiz,
  });

  final int systolisch;
  final int diastolisch;

  @override
  MesswertTyp get typ => MesswertTyp.blutdruck;
}

/// A heart rate in beats per minute.
final class HerzfrequenzMesswert extends Messwert {
  const HerzfrequenzMesswert({
    required super.zeitpunkt,
    required this.proMinute,
    super.notiz,
  });

  final int proMinute;

  @override
  MesswertTyp get typ => MesswertTyp.herzfrequenz;
}

/// A free-text note recorded during a Reanimationsfall.
class ReanimationsfallNotiz {
  const ReanimationsfallNotiz({required this.zeitpunkt, required this.text});

  /// The elapsed time since the Startzeit when the note was recorded.
  final Duration zeitpunkt;

  final String text;
}
