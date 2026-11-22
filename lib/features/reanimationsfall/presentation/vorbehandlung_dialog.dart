import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/format/wall_time_format.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The values of one save of the Vorbehandlung form.
///
/// This slice holds the time fields only; the Vorbehandlung counts and the
/// Notiz are added here and in [VorbehandlungKorrigiert] alongside them.
class VorbehandlungEingabe {
  const VorbehandlungEingabe({
    required this.uebernahme,
    required this.laufzeitBeiUebernahme,
  });

  /// The wall-clock time the team took over.
  final DateTime uebernahme;

  /// How long the resuscitation had been running at the [uebernahme].
  final Duration laufzeitBeiUebernahme;
}

/// Opens the Vorbehandlung form prefilled from [snapshot].
Future<VorbehandlungEingabe?> showVorbehandlungDialog(
  BuildContext context, {
  required ReanimationsfallSnapshot snapshot,
}) {
  return showDialog<VorbehandlungEingabe>(
    context: context,
    builder: (_) => VorbehandlungDialog(
      uebernahme: snapshot.uebernahme,
      laufzeitBeiUebernahme: snapshot.laufzeitBeiUebernahme,
      spaetesteUebernahme: snapshot.spaetesteUebernahme,
    ),
  );
}

/// The Vorbehandlung form: how long the resuscitation had been running at the
/// Übernahme, and the Übernahme as a clock time.
///
/// The duration is relative to the Übernahme, not to now. It is chosen from
/// presets, typed in minutes, or derived from a Startzeit picked as a clock
/// time. The form blocks values that break
/// `Startzeit ≤ Übernahme ≤ first event recorded in the app`.
class VorbehandlungDialog extends StatefulWidget {
  const VorbehandlungDialog({
    super.key,
    required this.uebernahme,
    required this.laufzeitBeiUebernahme,
    required this.spaetesteUebernahme,
  });

  final DateTime uebernahme;
  final Duration laufzeitBeiUebernahme;

  /// The first event recorded in the app, now, or the end of the case.
  final DateTime spaetesteUebernahme;

  /// The "Lief bei Übernahme seit" presets in minutes.
  static const laufzeitPresets = [1, 2, 3, 5, 8, 10];

  @override
  State<VorbehandlungDialog> createState() => _VorbehandlungDialogState();
}

class _VorbehandlungDialogState extends State<VorbehandlungDialog> {
  late DateTime _uebernahme = widget.uebernahme;
  late Duration _laufzeit = widget.laufzeitBeiUebernahme;
  late final TextEditingController _minutenController = TextEditingController(
    text: _isCustomMinutes(_laufzeit) ? '${_laufzeit.inMinutes}' : '',
  );
  bool _minutenUngueltig = false;

  @override
  void dispose() {
    _minutenController.dispose();
    super.dispose();
  }

  static bool _isCustomMinutes(Duration laufzeit) =>
      laufzeit > Duration.zero &&
      laufzeit.inSeconds % 60 == 0 &&
      !VorbehandlungDialog.laufzeitPresets.contains(laufzeit.inMinutes);

  DateTime get _startzeit => _uebernahme.subtract(_laufzeit);

  String? _fehler(AppLocalizations l10n) {
    if (_laufzeit.isNegative) {
      return l10n.vorbehandlungStartzeitNachUebernahme;
    }
    if (_uebernahme.isAfter(widget.spaetesteUebernahme)) {
      return l10n.vorbehandlungUebernahmeZuSpaet(
        formatWallTime(widget.spaetesteUebernahme),
      );
    }
    return null;
  }

  void _selectPreset(int minutes) {
    setState(() {
      _laufzeit = Duration(minutes: minutes);
      _minutenController.clear();
      _minutenUngueltig = false;
    });
  }

  void _onMinutenChanged(String text) {
    final minutes = int.tryParse(text.trim());
    setState(() {
      _minutenUngueltig = text.trim().isNotEmpty && minutes == null;
      if (minutes != null) _laufzeit = Duration(minutes: minutes);
    });
  }

  Future<void> _pickStartzeit() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startzeit),
    );
    if (time == null || !mounted) return;
    final startzeit = _closestDateTime(time, _uebernahme);
    setState(() {
      _laufzeit = _uebernahme.difference(startzeit);
      _minutenController.clear();
      _minutenUngueltig = false;
    });
  }

  Future<void> _pickUebernahme() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_uebernahme),
    );
    if (time == null || !mounted) return;
    setState(() => _uebernahme = _closestDateTime(time, _uebernahme));
  }

  /// The instant with the clock [time] closest to [reference], so a pick
  /// across midnight lands on the neighbouring day.
  static DateTime _closestDateTime(TimeOfDay time, DateTime reference) {
    DateTime onDay(int dayOffset) => DateTime(
      reference.year,
      reference.month,
      reference.day + dayOffset,
      time.hour,
      time.minute,
    );
    final candidates = [onDay(-1), onDay(0), onDay(1)];
    candidates.sort(
      (a, b) => a
          .difference(reference)
          .abs()
          .compareTo(b.difference(reference).abs()),
    );
    return candidates.first;
  }

  void _save() {
    Navigator.of(context).pop(
      VorbehandlungEingabe(
        uebernahme: _uebernahme,
        laufzeitBeiUebernahme: _laufzeit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fehler = _fehler(l10n);
    final canSave = fehler == null && !_minutenUngueltig;
    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.vorbehandlungTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.vorbehandlungLaufzeitLabel, style: labelStyle),
          const SizedBox(height: PageLayout.space8),
          Wrap(
            spacing: PageLayout.space8,
            runSpacing: PageLayout.space8,
            children: [
              for (final minutes in VorbehandlungDialog.laufzeitPresets)
                ChoiceChip(
                  label: Text(l10n.vorbehandlungLaufzeitChip(minutes)),
                  selected:
                      _minutenController.text.isEmpty &&
                      _laufzeit == Duration(minutes: minutes),
                  onSelected: (_) => _selectPreset(minutes),
                ),
            ],
          ),
          const SizedBox(height: PageLayout.space12),
          TextField(
            key: const ValueKey('vorbehandlung-laufzeit-minuten'),
            controller: _minutenController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.vorbehandlungLaufzeitMinuten,
              errorText: _minutenUngueltig
                  ? l10n.vorbehandlungLaufzeitInvalid
                  : null,
            ),
            onChanged: _onMinutenChanged,
          ),
          const SizedBox(height: PageLayout.space12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.vorbehandlungStartzeitValue(formatWallTime(_startzeit)),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: PageLayout.space8),
              TextButton.icon(
                onPressed: _pickStartzeit,
                icon: const Icon(Icons.schedule),
                label: Text(l10n.vorbehandlungStartzeitWaehlen),
              ),
            ],
          ),
          const SizedBox(height: PageLayout.space16),
          Text(l10n.vorbehandlungUebernahmeLabel, style: labelStyle),
          const SizedBox(height: PageLayout.space8),
          OutlinedButton.icon(
            key: const ValueKey('vorbehandlung-uebernahme'),
            onPressed: _pickUebernahme,
            icon: const Icon(Icons.schedule),
            label: Text(l10n.wallTimeValue(formatWallTime(_uebernahme))),
          ),
          if (fehler != null) ...[
            const SizedBox(height: PageLayout.space12),
            Text(
              fehler,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
