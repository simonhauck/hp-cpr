import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The completed guided Rhythmusanalyse.
class RhythmusanalyseAbschluss {
  const RhythmusanalyseAbschluss({
    required this.ergebnis,
    this.schockAbgegeben = false,
  });

  final RhythmusanalyseErgebnis ergebnis;
  final bool schockAbgegeben;
}

/// The guided selection of a Rhythmusanalyse result.
///
/// The flow branches from the rhythm category to the rhythm and, for a
/// shockable rhythm, to the shock confirmation. ROSC asks for confirmation
/// before it is recorded.
class RhythmusanalyseDialog extends StatefulWidget {
  const RhythmusanalyseDialog({super.key});

  @override
  State<RhythmusanalyseDialog> createState() => _RhythmusanalyseDialogState();
}

enum _Step { category, rhythm, shock }

class _RhythmusanalyseDialogState extends State<RhythmusanalyseDialog> {
  _Step _step = _Step.category;
  RhythmusanalyseKategorie? _kategorie;
  RhythmusanalyseErgebnis? _ergebnis;

  Future<void> _selectKategorie(RhythmusanalyseKategorie kategorie) async {
    switch (kategorie) {
      case RhythmusanalyseKategorie.rosc:
        final confirmed = await _confirmRosc();
        if (!mounted) return;
        if (confirmed == true) {
          _finish(RhythmusanalyseErgebnis.rosc);
        }
      case RhythmusanalyseKategorie.unklar:
        _finish(RhythmusanalyseErgebnis.unklar);
      case RhythmusanalyseKategorie.schockbar:
      case RhythmusanalyseKategorie.nichtSchockbar:
        setState(() {
          _kategorie = kategorie;
          _ergebnis = null;
          _step = _Step.rhythm;
        });
    }
  }

  Future<bool?> _confirmRosc() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.roscConfirmTitle),
        content: Text(l10n.roscConfirmDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.roscConfirmButton),
          ),
        ],
      ),
    );
  }

  void _selectRhythmus(RhythmusanalyseErgebnis ergebnis) {
    if (ergebnis.kategorie == RhythmusanalyseKategorie.schockbar) {
      setState(() {
        _ergebnis = ergebnis;
        _step = _Step.shock;
      });
      return;
    }

    _finish(ergebnis);
  }

  void _finish(
    RhythmusanalyseErgebnis ergebnis, {
    bool schockAbgegeben = false,
  }) {
    Navigator.of(context).pop(
      RhythmusanalyseAbschluss(
        ergebnis: ergebnis,
        schockAbgegeben: schockAbgegeben,
      ),
    );
  }

  void _back() {
    switch (_step) {
      case _Step.category:
        return;
      case _Step.rhythm:
        setState(() {
          _kategorie = null;
          _ergebnis = null;
          _step = _Step.category;
        });
      case _Step.shock:
        setState(() {
          _ergebnis = null;
          _step = _Step.rhythm;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      title: Row(
        children: [
          if (_step != _Step.category) ...[
            IconButton(
              onPressed: _back,
              tooltip: l10n.backButton,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: PageLayout.space4),
          ],
          Expanded(child: Text(l10n.rhythmusanalyseTitle)),
        ],
      ),
      content: _buildContent(l10n),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
      ],
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final stepLabel = switch (_step) {
      _Step.category => l10n.rhythmusanalyseStepKategorie,
      _Step.rhythm => l10n.rhythmusanalyseStepRhythmus,
      _Step.shock => null,
    };

    final body = switch (_step) {
      _Step.category => _buildKategorien(l10n),
      _Step.rhythm => _buildRhythmen(l10n),
      _Step.shock => _buildSchock(l10n),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stepLabel != null) ...[
          Text(
            stepLabel,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: PageLayout.space12),
        ],
        body,
      ],
    );
  }

  Widget _buildKategorien(AppLocalizations l10n) {
    return Wrap(
      spacing: PageLayout.space12,
      runSpacing: PageLayout.space12,
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
          emphasis: _ChoiceEmphasis.outlined,
        ),
        _choiceButton(
          label: l10n.rhythmusanalyseUnklar,
          onPressed: () => _selectKategorie(RhythmusanalyseKategorie.unklar),
          emphasis: _ChoiceEmphasis.outlined,
        ),
      ],
    );
  }

  Widget _buildRhythmen(AppLocalizations l10n) {
    final (options, unknownAedErgebnis) = switch (_kategorie!) {
      RhythmusanalyseKategorie.schockbar => (
        [
          (
            RhythmusanalyseErgebnis.kammerflimmern,
            l10n.rhythmusanalyseKammerflimmern,
          ),
          (
            RhythmusanalyseErgebnis.pulsloseKammertachykardie,
            l10n.rhythmusanalysePvt,
          ),
        ],
        RhythmusanalyseErgebnis.unbekanntAedSchockbar,
      ),
      RhythmusanalyseKategorie.nichtSchockbar => (
        [
          (RhythmusanalyseErgebnis.asystolie, l10n.rhythmusanalyseAsystolie),
          (RhythmusanalyseErgebnis.pea, l10n.rhythmusanalysePea),
        ],
        RhythmusanalyseErgebnis.unbekanntAedNichtSchockbar,
      ),
      RhythmusanalyseKategorie.rosc || RhythmusanalyseKategorie.unklar =>
        throw StateError('no rhythm options for $_kategorie'),
    };

    return Wrap(
      spacing: PageLayout.space12,
      runSpacing: PageLayout.space12,
      children: [
        for (final (ergebnis, label) in options)
          _choiceButton(
            label: label,
            onPressed: () => _selectRhythmus(ergebnis),
          ),
        _choiceButton(
          label: l10n.rhythmusanalyseUnbekanntAed,
          onPressed: () => _selectRhythmus(unknownAedErgebnis),
          emphasis: _ChoiceEmphasis.outlined,
        ),
      ],
    );
  }

  void _finishSchock(bool schockAbgegeben) {
    _finish(_ergebnis!, schockAbgegeben: schockAbgegeben);
  }

  Widget _buildSchock(AppLocalizations l10n) {
    const minimumSize = Size.fromHeight(PageLayout.dialogActionHeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.rhythmusanalyseSchockQuestion,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: PageLayout.space16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _finishSchock(true),
                style: FilledButton.styleFrom(minimumSize: minimumSize),
                child: Text(l10n.rhythmusanalyseYes),
              ),
            ),
            const SizedBox(width: PageLayout.space12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _finishSchock(false),
                style: OutlinedButton.styleFrom(minimumSize: minimumSize),
                child: Text(l10n.rhythmusanalyseNo),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _choiceButton({
    required String label,
    required VoidCallback onPressed,
    _ChoiceEmphasis emphasis = _ChoiceEmphasis.filled,
  }) {
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        const Size(PageLayout.dialogActionWidth, PageLayout.dialogActionHeight),
      ),
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.titleSmall),
    );

    return switch (emphasis) {
      _ChoiceEmphasis.filled => FilledButton.tonal(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      ),
      _ChoiceEmphasis.outlined => OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      ),
    };
  }
}

enum _ChoiceEmphasis { filled, outlined }
