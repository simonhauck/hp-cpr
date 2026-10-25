import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';

/// The result of the note dialog; null means the dialog was cancelled.
class RhythmusanalyseNotizEdit {
  const RhythmusanalyseNotizEdit(this.notiz);

  final String? notiz;
}

/// Adds or edits the optional free-text note of a Rhythmusanalyse result.
class RhythmusanalyseNotizDialog extends StatefulWidget {
  const RhythmusanalyseNotizDialog({super.key, this.initialNotiz});

  final String? initialNotiz;

  @override
  State<RhythmusanalyseNotizDialog> createState() =>
      _RhythmusanalyseNotizDialogState();
}

class _RhythmusanalyseNotizDialogState
    extends State<RhythmusanalyseNotizDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNotiz,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(RhythmusanalyseNotizEdit(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.rhythmusanalyseNoteTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.rhythmusanalyseNoteLabel,
          border: const OutlineInputBorder(),
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
