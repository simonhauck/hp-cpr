/// An event with a stable identity and a case-relative time in the Protokoll.
abstract interface class ProtokollEreignis {
  String get id;
  Duration get zeitpunkt;
}
