import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The case-relative time fields used by the Protokoll edit dialogs.
class ProtokollZeitpunktFields extends StatefulWidget {
  const ProtokollZeitpunktFields({
    super.key,
    required this.startzeit,
    required this.maxZeitpunkt,
    required this.initial,
  });

  final DateTime startzeit;
  final Duration maxZeitpunkt;
  final Duration initial;

  @override
  State<ProtokollZeitpunktFields> createState() =>
      ProtokollZeitpunktFieldsState();
}

class ProtokollZeitpunktFieldsState extends State<ProtokollZeitpunktFields> {
  late final TextEditingController _minutes;
  late final TextEditingController _seconds;

  @override
  void initState() {
    super.initState();
    _minutes = TextEditingController(text: widget.initial.inMinutes.toString());
    _seconds = TextEditingController(
      text: widget.initial.inSeconds.remainder(60).toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  Duration get duration {
    final minutes = int.tryParse(_minutes.text) ?? 0;
    final seconds = int.tryParse(_seconds.text) ?? 0;
    return Duration(minutes: minutes, seconds: seconds);
  }

  String? _validateMinutes(AppLocalizations l10n) {
    final minutes = int.tryParse(_minutes.text);
    if (minutes == null || minutes < 0) return l10n.protokollTimeInvalid;
    final seconds = int.tryParse(_seconds.text) ?? 0;
    final total = Duration(minutes: minutes, seconds: seconds);
    if (total > widget.maxZeitpunkt) return l10n.protokollTimeInvalid;
    return null;
  }

  String? _validateSeconds(AppLocalizations l10n) {
    final seconds = int.tryParse(_seconds.text);
    if (seconds == null || seconds < 0 || seconds > 59) {
      return l10n.invalidSecondsMessage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.protokollCaseTime,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PageLayout.space8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.minutesLabel),
                onChanged: (_) => setState(() {}),
                validator: (_) => _validateMinutes(l10n),
              ),
            ),
            const SizedBox(width: PageLayout.space8),
            Expanded(
              child: TextFormField(
                controller: _seconds,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.secondsLabel),
                onChanged: (_) => setState(() {}),
                validator: (_) => _validateSeconds(l10n),
              ),
            ),
          ],
        ),
        const SizedBox(height: PageLayout.space8),
        Text(
          l10n.protokollWallTime(
            formatWallTime(widget.startzeit.add(duration)),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
