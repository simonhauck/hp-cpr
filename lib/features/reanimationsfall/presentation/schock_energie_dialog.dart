import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';

/// Asks for the optional energy of a recorded Schock.
class SchockEnergieDialog extends StatefulWidget {
  const SchockEnergieDialog({super.key, this.initialEnergie});

  final int? initialEnergie;

  @override
  State<SchockEnergieDialog> createState() => _SchockEnergieDialogState();
}

class _SchockEnergieDialogState extends State<SchockEnergieDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.initialEnergie?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(int.parse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.schockEnergyTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.schockEnergyLabel,
            border: const OutlineInputBorder(),
          ),
          onFieldSubmitted: (_) => _submit(),
          validator: (value) {
            final energie = int.tryParse(value ?? '');
            if (energie == null || energie <= 0) {
              return l10n.schockEnergyInvalid;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.saveButton)),
      ],
    );
  }
}
