import 'package:flutter/material.dart';

import 'package:hp_cpr/features/messwerte/presentation/messwert_erfassen_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/ereignisse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/protokoll.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/schock.dart';
import 'package:hp_cpr/ui/dialogs/protokoll_zeitpunkt_fields.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// Opens the type-specific editor for one Protokoll entry.
Future<ProtokollKorrektur?> showProtokollEditDialog(
  BuildContext context, {
  required ProtokollEintrag eintrag,
  required DateTime startzeit,
  required Duration maxZeitpunkt,
}) {
  final daten = eintrag.daten;

  return switch (daten) {
    SchockEreignis(:final energieJoule) => showDialog<ProtokollKorrektur>(
      context: context,
      builder: (_) => _SchockDialog(
        eintrag: eintrag,
        startzeit: startzeit,
        maxZeitpunkt: maxZeitpunkt,
        energieJoule: energieJoule,
      ),
    ),
    AdrenalinGabe(:final dosisMg) => showDialog<ProtokollKorrektur>(
      context: context,
      builder: (_) => _DoseDialog(
        eintrag: eintrag,
        startzeit: startzeit,
        maxZeitpunkt: maxZeitpunkt,
        dosisMg: dosisMg,
        isAdrenalin: true,
      ),
    ),
    AmiodaronGabe(:final dosisMg) => showDialog<ProtokollKorrektur>(
      context: context,
      builder: (_) => _DoseDialog(
        eintrag: eintrag,
        startzeit: startzeit,
        maxZeitpunkt: maxZeitpunkt,
        dosisMg: dosisMg,
        isAdrenalin: false,
      ),
    ),
    Messwert(:final typ) => _editMesswert(
      context,
      eintrag,
      typ,
      startzeit,
      maxZeitpunkt,
    ),
    ReanimationsfallNotiz(:final text) => showDialog<ProtokollKorrektur>(
      context: context,
      builder: (_) => _NotizDialog(
        eintrag: eintrag,
        startzeit: startzeit,
        maxZeitpunkt: maxZeitpunkt,
        text: text,
      ),
    ),
    RhythmusanalyseEintrag(:final ergebnis) => showDialog<ProtokollKorrektur>(
      context: context,
      builder: (_) => _RhythmusanalyseDialog(
        eintrag: eintrag,
        startzeit: startzeit,
        maxZeitpunkt: maxZeitpunkt,
        ergebnis: ergebnis,
      ),
    ),
    RhythmusanalyseUeberspringung() ||
    DruckphaseNeustart() ||
    RoscEreignis() ||
    Reanimationswiederbeginn() => showDialog<ProtokollKorrektur>(
      context: context,
      builder: (_) => _ZeitpunktDialog(
        eintrag: eintrag,
        startzeit: startzeit,
        maxZeitpunkt: maxZeitpunkt,
      ),
    ),
    _ => Future<ProtokollKorrektur?>.value(),
  };
}

Future<ProtokollKorrektur?> _editMesswert(
  BuildContext context,
  ProtokollEintrag eintrag,
  MesswertTyp typ,
  DateTime startzeit,
  Duration maxZeitpunkt,
) async {
  final original = eintrag.daten as Messwert;
  final eingabe = await showDialog<MesswertEingabe>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return MesswertErfassenDialog(
        typ: typ,
        initial: original,
        title: l10n.protokollEditMesswertTitle,
        initialZeitpunkt: eintrag.zeitpunkt,
        startzeit: startzeit,
        maxZeitpunkt: maxZeitpunkt,
      );
    },
  );
  if (eingabe == null) return null;

  return MesswertKorrigiert(
    ziel: eintrag.ref,
    ersatz: buildMesswertFromEingabe(original.id, eingabe),
  );
}

class _ZeitpunktDialog extends StatefulWidget {
  const _ZeitpunktDialog({
    required this.eintrag,
    required this.startzeit,
    required this.maxZeitpunkt,
  });

  final ProtokollEintrag eintrag;
  final DateTime startzeit;
  final Duration maxZeitpunkt;

  @override
  State<_ZeitpunktDialog> createState() => _ZeitpunktDialogState();
}

class _ZeitpunktDialogState extends State<_ZeitpunktDialog> {
  final _formKey = GlobalKey<FormState>();
  final _zeitpunktKey = GlobalKey<ProtokollZeitpunktFieldsState>();

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final zeitpunkt = _zeitpunktKey.currentState!.duration;
    final korrektur = widget.eintrag.daten is RoscEreignis
        ? RoscKorrigiert(ziel: widget.eintrag.ref, zeitpunkt: zeitpunkt)
        : ZeitpunktKorrigiert(ziel: widget.eintrag.ref, zeitpunkt: zeitpunkt);
    Navigator.of(context).pop(korrektur);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.protokollTimeTitle),
      content: Form(
        key: _formKey,
        child: ProtokollZeitpunktFields(
          key: _zeitpunktKey,
          startzeit: widget.startzeit,
          maxZeitpunkt: widget.maxZeitpunkt,
          initial: widget.eintrag.zeitpunkt,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}

class _SchockDialog extends StatefulWidget {
  const _SchockDialog({
    required this.eintrag,
    required this.startzeit,
    required this.maxZeitpunkt,
    this.energieJoule,
  });

  final ProtokollEintrag eintrag;
  final DateTime startzeit;
  final Duration maxZeitpunkt;
  final int? energieJoule;

  @override
  State<_SchockDialog> createState() => _SchockDialogState();
}

class _SchockDialogState extends State<_SchockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _zeitpunktKey = GlobalKey<ProtokollZeitpunktFieldsState>();
  late final TextEditingController _energie = TextEditingController(
    text: widget.energieJoule?.toString() ?? '',
  );

  @override
  void dispose() {
    _energie.dispose();
    super.dispose();
  }

  String? _validateEnergie(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return l10n.protokollEnergyInvalid;
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final energie = _energie.text.trim().isEmpty
        ? null
        : int.parse(_energie.text);
    Navigator.of(context).pop(
      SchockKorrigiert(
        ziel: widget.eintrag.ref,
        zeitpunkt: _zeitpunktKey.currentState!.duration,
        energieJoule: energie,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.protokollEditSchockTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProtokollZeitpunktFields(
              key: _zeitpunktKey,
              startzeit: widget.startzeit,
              maxZeitpunkt: widget.maxZeitpunkt,
              initial: widget.eintrag.zeitpunkt,
            ),
            const SizedBox(height: PageLayout.space12),
            TextFormField(
              controller: _energie,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.protokollEnergyLabel),
              validator: (value) => _validateEnergie(value, l10n),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}

class _DoseDialog extends StatefulWidget {
  const _DoseDialog({
    required this.eintrag,
    required this.startzeit,
    required this.maxZeitpunkt,
    required this.dosisMg,
    required this.isAdrenalin,
  });

  final ProtokollEintrag eintrag;
  final DateTime startzeit;
  final Duration maxZeitpunkt;
  final int dosisMg;
  final bool isAdrenalin;

  @override
  State<_DoseDialog> createState() => _DoseDialogState();
}

class _DoseDialogState extends State<_DoseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _zeitpunktKey = GlobalKey<ProtokollZeitpunktFieldsState>();
  late final TextEditingController _dosis = TextEditingController(
    text: widget.dosisMg.toString(),
  );

  @override
  void dispose() {
    _dosis.dispose();
    super.dispose();
  }

  String? _validateDosis(String? value, AppLocalizations l10n) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return l10n.protokollDoseInvalid;
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final zeitpunkt = _zeitpunktKey.currentState!.duration;
    final dosis = int.parse(_dosis.text);
    final korrektur = widget.isAdrenalin
        ? AdrenalinKorrigiert(
            ziel: widget.eintrag.ref,
            zeitpunkt: zeitpunkt,
            dosisMg: dosis,
          )
        : AmiodaronKorrigiert(
            ziel: widget.eintrag.ref,
            zeitpunkt: zeitpunkt,
            dosisMg: dosis,
          );
    Navigator.of(context).pop(korrektur);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.protokollDoseTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProtokollZeitpunktFields(
              key: _zeitpunktKey,
              startzeit: widget.startzeit,
              maxZeitpunkt: widget.maxZeitpunkt,
              initial: widget.eintrag.zeitpunkt,
            ),
            const SizedBox(height: PageLayout.space12),
            TextFormField(
              controller: _dosis,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.protokollDoseLabel),
              validator: (value) => _validateDosis(value, l10n),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}

class _NotizDialog extends StatefulWidget {
  const _NotizDialog({
    required this.eintrag,
    required this.startzeit,
    required this.maxZeitpunkt,
    required this.text,
  });

  final ProtokollEintrag eintrag;
  final DateTime startzeit;
  final Duration maxZeitpunkt;
  final String text;

  @override
  State<_NotizDialog> createState() => _NotizDialogState();
}

class _NotizDialogState extends State<_NotizDialog> {
  final _formKey = GlobalKey<FormState>();
  final _zeitpunktKey = GlobalKey<ProtokollZeitpunktFieldsState>();
  late final TextEditingController _text = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NotizKorrigiert(
        ziel: widget.eintrag.ref,
        zeitpunkt: _zeitpunktKey.currentState!.duration,
        text: _text.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.protokollEditNotizTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProtokollZeitpunktFields(
              key: _zeitpunktKey,
              startzeit: widget.startzeit,
              maxZeitpunkt: widget.maxZeitpunkt,
              initial: widget.eintrag.zeitpunkt,
            ),
            const SizedBox(height: PageLayout.space12),
            TextFormField(
              controller: _text,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.noteLabel),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return l10n.notizEmptyInvalid;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}

class _RhythmusanalyseDialog extends StatefulWidget {
  const _RhythmusanalyseDialog({
    required this.eintrag,
    required this.startzeit,
    required this.maxZeitpunkt,
    required this.ergebnis,
  });

  final ProtokollEintrag eintrag;
  final DateTime startzeit;
  final Duration maxZeitpunkt;
  final RhythmusanalyseErgebnis ergebnis;

  @override
  State<_RhythmusanalyseDialog> createState() => _RhythmusanalyseDialogState();
}

class _RhythmusanalyseDialogState extends State<_RhythmusanalyseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _zeitpunktKey = GlobalKey<ProtokollZeitpunktFieldsState>();
  late RhythmusanalyseErgebnis _ergebnis = widget.ergebnis;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      RhythmusanalyseKorrigiert(
        ziel: widget.eintrag.ref,
        zeitpunkt: _zeitpunktKey.currentState!.duration,
        ergebnis: _ergebnis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ergebnisse = RhythmusanalyseErgebnis.values
        .where(
          (ergebnis) => ergebnis.kategorie != RhythmusanalyseKategorie.rosc,
        )
        .toList();

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.protokollEditRhythmusanalyseTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProtokollZeitpunktFields(
              key: _zeitpunktKey,
              startzeit: widget.startzeit,
              maxZeitpunkt: widget.maxZeitpunkt,
              initial: widget.eintrag.zeitpunkt,
            ),
            const SizedBox(height: PageLayout.space12),
            Text(
              l10n.rhythmusanalyseStepRhythmus,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PageLayout.space8),
            Wrap(
              spacing: PageLayout.space8,
              runSpacing: PageLayout.space8,
              children: [
                for (final ergebnis in ergebnisse)
                  ChoiceChip(
                    label: Text(rhythmusanalyseErgebnisLabel(l10n, ergebnis)),
                    selected: _ergebnis == ergebnis,
                    onSelected: (_) => setState(() => _ergebnis = ergebnis),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}
