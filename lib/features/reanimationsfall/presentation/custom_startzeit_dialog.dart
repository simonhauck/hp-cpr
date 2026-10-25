import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// Asks for a custom number of minutes and seconds since the first compression.
class CustomStartzeitDialog extends StatefulWidget {
  const CustomStartzeitDialog({super.key});

  @override
  State<CustomStartzeitDialog> createState() => _CustomStartzeitDialogState();
}

class _CustomStartzeitDialogState extends State<CustomStartzeitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  int? _parseOrEmptyAsZero(String value) {
    if (value.isEmpty) return 0;
    return int.tryParse(value);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final minutes = _parseOrEmptyAsZero(_minutesController.text) ?? 0;
    final seconds = _parseOrEmptyAsZero(_secondsController.text) ?? 0;
    Navigator.of(context).pop(Duration(minutes: minutes, seconds: seconds));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.customStartzeitTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.customStartzeitDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: PageLayout.space16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minutesController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.minutesLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final minutes = _parseOrEmptyAsZero(value ?? '');
                      if (minutes == null) return l10n.invalidBackdateMessage;
                      final seconds =
                          _parseOrEmptyAsZero(_secondsController.text) ?? 0;
                      if (minutes == 0 && seconds == 0) {
                        return l10n.invalidBackdateMessage;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: PageLayout.space12),
                Expanded(
                  child: TextFormField(
                    controller: _secondsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.secondsLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      final seconds = _parseOrEmptyAsZero(value ?? '');
                      if (seconds == null || seconds > 59) {
                        return l10n.invalidSecondsMessage;
                      }
                      return null;
                    },
                  ),
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
        FilledButton(onPressed: _submit, child: Text(l10n.startCaseButton)),
      ],
    );
  }
}
