import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// Asks for a free-text note and returns its trimmed text.
class NotizErfassenDialog extends StatefulWidget {
  const NotizErfassenDialog({super.key});

  @override
  State<NotizErfassenDialog> createState() => _NotizErfassenDialogState();
}

class _NotizErfassenDialogState extends State<NotizErfassenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.notizErfassenTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.noteLabel),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return l10n.notizEmptyInvalid;
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
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size(PageLayout.space0, PageLayout.space40),
          ),
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
