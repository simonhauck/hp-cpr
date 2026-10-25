import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The two-step selection of a Rhythmusanalyse result.
///
/// The first step chooses the category; Schockbar and Nicht schockbar then
/// open a second step with the rhythm or AED advisory. ROSC and Unklar are
/// recorded directly.
class RhythmusanalyseDialog extends StatefulWidget {
  const RhythmusanalyseDialog({super.key});

  @override
  State<RhythmusanalyseDialog> createState() => _RhythmusanalyseDialogState();
}

class _RhythmusanalyseDialogState extends State<RhythmusanalyseDialog> {
  RhythmusanalyseKategorie? _kategorie;

  void _selectKategorie(RhythmusanalyseKategorie kategorie) {
    switch (kategorie) {
      case RhythmusanalyseKategorie.rosc:
        Navigator.of(context).pop(RhythmusanalyseErgebnis.rosc);
      case RhythmusanalyseKategorie.unklar:
        Navigator.of(context).pop(RhythmusanalyseErgebnis.unklar);
      case RhythmusanalyseKategorie.schockbar:
      case RhythmusanalyseKategorie.nichtSchockbar:
        setState(() => _kategorie = kategorie);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final kategorie = _kategorie;

    return AlertDialog(
      scrollable: true,
      title: Row(
        children: [
          if (kategorie != null) ...[
            IconButton(
              onPressed: () => setState(() => _kategorie = null),
              tooltip: l10n.backButton,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(child: Text(l10n.rhythmusanalyseTitle)),
        ],
      ),
      content: kategorie == null
          ? _buildKategorien(l10n)
          : _buildRhythmen(kategorie, l10n, theme),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
      ],
    );
  }

  Widget _buildKategorien(AppLocalizations l10n) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _choiceButton(
          label: l10n.rhythmusanalyseSchockbar,
          onPressed: () => _selectKategorie(RhythmusanalyseKategorie.schockbar),
        ),
        _choiceButton(
          label: l10n.rhythmusanalyseNichtSchockbar,
          onPressed: () =>
              _selectKategorie(RhythmusanalyseKategorie.nichtSchockbar),
        ),
        _choiceButton(
          label: l10n.rhythmusanalyseRosc,
          onPressed: () => _selectKategorie(RhythmusanalyseKategorie.rosc),
        ),
        _choiceButton(
          label: l10n.rhythmusanalyseUnklar,
          onPressed: () => _selectKategorie(RhythmusanalyseKategorie.unklar),
        ),
      ],
    );
  }

  Widget _buildRhythmen(
    RhythmusanalyseKategorie kategorie,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final options = switch (kategorie) {
      RhythmusanalyseKategorie.schockbar => [
        (
          RhythmusanalyseErgebnis.kammerflimmern,
          l10n.rhythmusanalyseKammerflimmern,
        ),
        (
          RhythmusanalyseErgebnis.pulsloseKammertachykardie,
          l10n.rhythmusanalysePvt,
        ),
        (
          RhythmusanalyseErgebnis.unbekanntAedSchockbar,
          l10n.rhythmusanalyseUnbekanntAed,
        ),
      ],
      RhythmusanalyseKategorie.nichtSchockbar => [
        (RhythmusanalyseErgebnis.asystolie, l10n.rhythmusanalyseAsystolie),
        (RhythmusanalyseErgebnis.pea, l10n.rhythmusanalysePea),
        (
          RhythmusanalyseErgebnis.unbekanntAedNichtSchockbar,
          l10n.rhythmusanalyseUnbekanntAed,
        ),
      ],
      RhythmusanalyseKategorie.rosc ||
      RhythmusanalyseKategorie.unklar => const [],
    };

    final kategorieLabel = switch (kategorie) {
      RhythmusanalyseKategorie.schockbar => l10n.rhythmusanalyseSchockbar,
      RhythmusanalyseKategorie.nichtSchockbar =>
        l10n.rhythmusanalyseNichtSchockbar,
      RhythmusanalyseKategorie.rosc => l10n.rhythmusanalyseRosc,
      RhythmusanalyseKategorie.unklar => l10n.rhythmusanalyseUnklar,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kategorieLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (ergebnis, label) in options)
              _choiceButton(
                label: label,
                onPressed: () => Navigator.of(context).pop(ergebnis),
              ),
          ],
        ),
      ],
    );
  }

  Widget _choiceButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(200, 56),
        textStyle: Theme.of(context).textTheme.titleSmall,
      ),
      child: Text(label),
    );
  }
}
