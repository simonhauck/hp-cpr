import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';

/// An action that just became due and is signalled to the Zeitnehmer.
enum SignalAnlass {
  rhythmusanalyseFaellig,
  ersteAdrenalinGabeFaellig,
  adrenalinFaellig,
  adrenalinUeberfaellig,
  amiodaronHinweis,
}

/// Detects the transitions of a Reanimationsfall that must be signalled.
///
/// Edge-triggered: each call to [update] compares the given snapshot with the
/// previous one. The first snapshot only seeds the state, so a case that is
/// already due when it opens does not signal.
class SignalDetector {
  ReanimationsfallSnapshot? _previous;

  /// Returns the transitions that happened since the previous snapshot.
  List<SignalAnlass> update(ReanimationsfallSnapshot current) {
    final previous = _previous;
    _previous = current;
    if (previous == null || !current.vibrationEnabled || !current.istLaufend) {
      return const [];
    }

    final anlaesse = <SignalAnlass>[];
    if (current.isRhythmusanalyseDue && !previous.isRhythmusanalyseDue) {
      anlaesse.add(SignalAnlass.rhythmusanalyseFaellig);
    }
    if (current.istErsteAdrenalinGabeFaellig &&
        !previous.istErsteAdrenalinGabeFaellig) {
      anlaesse.add(SignalAnlass.ersteAdrenalinGabeFaellig);
    }
    final adrenalin = current.adrenalinZeitfensterZustand;
    if (adrenalin != previous.adrenalinZeitfensterZustand) {
      if (adrenalin == AdrenalinZeitfensterZustand.faellig) {
        anlaesse.add(SignalAnlass.adrenalinFaellig);
      } else if (adrenalin == AdrenalinZeitfensterZustand.ueberfaellig) {
        anlaesse.add(SignalAnlass.adrenalinUeberfaellig);
      }
    }
    if (current.amiodaronHinweis != AmiodaronHinweis.keine &&
        current.amiodaronHinweis != previous.amiodaronHinweis) {
      anlaesse.add(SignalAnlass.amiodaronHinweis);
    }
    return anlaesse;
  }
}
