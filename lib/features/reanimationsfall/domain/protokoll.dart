import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';

/// The kind of an entry in a [Protokoll].
enum ProtokollEintragTyp {
  fallStart,
  schock,
  adrenalin,
  amiodaron,
  rhythmusanalyse,
  ueberspringung,
  druckphaseNeustart,
  rosc,
  wiederbeginn,
  messwert,
  notiz,
  fallEnde,
  fallVerworfen;

  /// Whether the entry changes the running case state and is therefore locked
  /// while the case is open.
  bool get istStrukturell => switch (this) {
    rhythmusanalyse ||
    ueberspringung ||
    druckphaseNeustart ||
    rosc ||
    wiederbeginn => true,
    _ => false,
  };

  /// Whether the entry belongs to the case lifecycle rather than clinical data.
  bool get istLebenszyklus => switch (this) {
    fallStart || fallEnde || fallVerworfen => true,
    _ => false,
  };

  /// Whether this is a record-only clinical entry.
  bool get istAufzeichnung => !istStrukturell && !istLebenszyklus;
}

/// A stable reference to one original entry in a [Protokoll].
class ProtokollEintragRef {
  const ProtokollEintragRef({required this.typ, required this.id});

  final ProtokollEintragTyp typ;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is ProtokollEintragRef && other.typ == typ && other.id == id;

  @override
  int get hashCode => Object.hash(typ, id);

  @override
  String toString() => 'ProtokollEintragRef(${typ.name}, $id)';
}

/// An append-only correction to one original Protokoll entry.
sealed class ProtokollKorrektur {
  const ProtokollKorrektur({required this.ziel});

  final ProtokollEintragRef ziel;
}

/// Hides an entry from the default Protokoll without deleting it.
final class ProtokollEintragEntfernt extends ProtokollKorrektur {
  const ProtokollEintragEntfernt({required super.ziel});
}

/// Restores a previously removed entry.
final class ProtokollEintragWiederhergestellt extends ProtokollKorrektur {
  const ProtokollEintragWiederhergestellt({required super.ziel});
}

/// Replaces a Schock's time and optional energy.
final class SchockKorrigiert extends ProtokollKorrektur {
  const SchockKorrigiert({
    required super.ziel,
    required this.zeitpunkt,
    this.energieJoule,
  });

  final Duration zeitpunkt;
  final int? energieJoule;
}

/// Replaces an Adrenalin dose's time and dose.
final class AdrenalinKorrigiert extends ProtokollKorrektur {
  const AdrenalinKorrigiert({
    required super.ziel,
    required this.zeitpunkt,
    required this.dosisMg,
  });

  final Duration zeitpunkt;
  final int dosisMg;
}

/// Replaces an Amiodaron dose's time and dose.
final class AmiodaronKorrigiert extends ProtokollKorrektur {
  const AmiodaronKorrigiert({
    required super.ziel,
    required this.zeitpunkt,
    required this.dosisMg,
  });

  final Duration zeitpunkt;
  final int dosisMg;
}

/// Replaces a Messwert's time, value, and note.
final class MesswertKorrigiert extends ProtokollKorrektur {
  const MesswertKorrigiert({required super.ziel, required this.ersatz});

  final Messwert ersatz;
}

/// Replaces a note's time and text.
final class NotizKorrigiert extends ProtokollKorrektur {
  const NotizKorrigiert({
    required super.ziel,
    required this.zeitpunkt,
    required this.text,
  });

  final Duration zeitpunkt;
  final String text;
}

/// Replaces a Rhythmusanalyse's time and result.
final class RhythmusanalyseKorrigiert extends ProtokollKorrektur {
  const RhythmusanalyseKorrigiert({
    required super.ziel,
    required this.zeitpunkt,
    required this.ergebnis,
  });

  final Duration zeitpunkt;
  final RhythmusanalyseErgebnis ergebnis;
}

/// Replaces the time of a time-only structural entry.
final class ZeitpunktKorrigiert extends ProtokollKorrektur {
  const ZeitpunktKorrigiert({required super.ziel, required this.zeitpunkt});

  final Duration zeitpunkt;
}

/// Replaces the time of a ROSC entry and its paired Rhythmusanalyse.
final class RoscKorrigiert extends ProtokollKorrektur {
  const RoscKorrigiert({required super.ziel, required this.zeitpunkt});

  final Duration zeitpunkt;
}

/// One entry in the effective Protokoll timeline.
///
/// [daten] is the effective event after corrections; [originalDaten] keeps the
/// originally recorded event for the Änderungsverlauf.
class ProtokollEintrag {
  const ProtokollEintrag({
    required this.ref,
    required this.typ,
    required this.zeitpunkt,
    required this.originalZeitpunkt,
    required this.daten,
    required this.originalDaten,
    required this.istEntfernt,
    required this.istKorrigiert,
    required this.istBearbeitbar,
    required this.istWiederherstellbar,
    required this.order,
    this.nummer,
  });

  final ProtokollEintragRef ref;
  final ProtokollEintragTyp typ;
  final Duration zeitpunkt;
  final Duration originalZeitpunkt;
  final Object daten;
  final Object originalDaten;
  final bool istEntfernt;
  final bool istKorrigiert;
  final bool istBearbeitbar;
  final bool istWiederherstellbar;

  /// The stable recording order used as a tie-breaker for equal times.
  final int order;

  /// The chronological shock number for a Schock entry, otherwise null.
  final int? nummer;

  bool get istLebenszyklus => typ.istLebenszyklus;

  ProtokollEintrag withNummer(int? nummer) {
    return ProtokollEintrag(
      ref: ref,
      typ: typ,
      zeitpunkt: zeitpunkt,
      originalZeitpunkt: originalZeitpunkt,
      daten: daten,
      originalDaten: originalDaten,
      istEntfernt: istEntfernt,
      istKorrigiert: istKorrigiert,
      istBearbeitbar: istBearbeitbar,
      istWiederherstellbar: istWiederherstellbar,
      order: order,
      nummer: nummer,
    );
  }
}

/// The effective and audit views of one Reanimationsfall's Protokoll.
class Protokoll {
  const Protokoll({required this.eintraege, required this.alleEintraege});

  /// The visible timeline: every non-removed entry, sorted by effective time.
  final List<ProtokollEintrag> eintraege;

  /// Every entry, including removed and corrected originals, sorted by time.
  final List<ProtokollEintrag> alleEintraege;
}
