import 'package:flutter/material.dart';

import 'package:hp_cpr/features/messwerte/presentation/messwert_format.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// A validated measurement entered in [MesswertErfassenDialog].
sealed class MesswertEingabe {
  const MesswertEingabe({this.notiz});

  final String? notiz;
}

final class TemperaturEingabe extends MesswertEingabe {
  const TemperaturEingabe({required this.celsius, super.notiz});

  final double celsius;
}

final class BlutzuckerEingabe extends MesswertEingabe {
  const BlutzuckerEingabe({required this.mgDl, super.notiz});

  final int mgDl;
}

final class BlutdruckEingabe extends MesswertEingabe {
  const BlutdruckEingabe({
    required this.systolisch,
    required this.diastolisch,
    super.notiz,
  });

  final int systolisch;
  final int diastolisch;
}

final class HerzfrequenzEingabe extends MesswertEingabe {
  const HerzfrequenzEingabe({required this.proMinute, super.notiz});

  final int proMinute;
}

/// Validates the value for [typ] and returns a [MesswertEingabe].
class MesswertErfassenDialog extends StatefulWidget {
  const MesswertErfassenDialog({super.key, required this.typ});

  final MesswertTyp typ;

  @override
  State<MesswertErfassenDialog> createState() => _MesswertErfassenDialogState();
}

class _MesswertErfassenDialogState extends State<MesswertErfassenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    _diastolicController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final note = _noteController.text;
    final notiz = note.trim().isEmpty ? null : note;
    final eingabe = switch (widget.typ) {
      MesswertTyp.temperatur => TemperaturEingabe(
        celsius: double.parse(_valueController.text.replaceAll(',', '.')),
        notiz: notiz,
      ),
      MesswertTyp.blutzucker => BlutzuckerEingabe(
        mgDl: int.parse(_valueController.text),
        notiz: notiz,
      ),
      MesswertTyp.blutdruck => BlutdruckEingabe(
        systolisch: int.parse(_valueController.text),
        diastolisch: int.parse(_diastolicController.text),
        notiz: notiz,
      ),
      MesswertTyp.herzfrequenz => HerzfrequenzEingabe(
        proMinute: int.parse(_valueController.text),
        notiz: notiz,
      ),
    };
    Navigator.of(context).pop(eingabe);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typ = widget.typ;

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.messwertErfassenTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              messwertTypLabel(l10n, typ),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: PageLayout.space8),
            if (typ == MesswertTyp.blutdruck) ...[
              TextFormField(
                controller: _valueController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.messwertSystolischLabel,
                ),
                validator: (value) {
                  final systolic = int.tryParse(value ?? '');
                  final diastolic = int.tryParse(_diastolicController.text);
                  if (systolic == null || systolic <= 0) {
                    return l10n.messwertInvalid;
                  }
                  if (diastolic != null && systolic <= diastolic) {
                    return l10n.messwertBloodPressureInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: PageLayout.space8),
              TextFormField(
                controller: _diastolicController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.messwertDiastolischLabel,
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return l10n.messwertInvalid;
                  }
                  return null;
                },
              ),
            ] else
              TextFormField(
                controller: _valueController,
                autofocus: true,
                keyboardType: typ == MesswertTyp.temperatur
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
                decoration: InputDecoration(
                  labelText: switch (typ) {
                    MesswertTyp.temperatur => l10n.messwertTemperaturLabel,
                    MesswertTyp.blutzucker => l10n.messwertBlutzuckerLabel,
                    MesswertTyp.herzfrequenz => l10n.messwertHerzfrequenzLabel,
                    MesswertTyp.blutdruck => l10n.messwertSystolischLabel,
                  },
                ),
                validator: (value) {
                  if (typ == MesswertTyp.temperatur) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (parsed == null || !parsed.isFinite || parsed <= 0) {
                      return l10n.messwertInvalid;
                    }
                    return null;
                  }
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return l10n.messwertInvalid;
                  }
                  return null;
                },
              ),
            const SizedBox(height: PageLayout.space8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.noteOptionalLabel),
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
