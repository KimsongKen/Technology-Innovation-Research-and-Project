part of '../main.dart';

// ── Settings page ─────────────────────────────────────────────────────────

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SACAAppState    state = SACAStateScope.of(context);
    final SACAColorScheme cs    = SACAColorScheme.of(context);

    return Scaffold(
      backgroundColor: cs.pageBackground,
      appBar: AppBar(
        backgroundColor: cs.pageBackground,
        foregroundColor: cs.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.charcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color:      cs.charcoal,
            fontSize:   19,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cs.subtleBorder),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: <Widget>[

          // ── Section: Appearance ──────────────────────────────────────
          _SettingsSectionLabel(label: 'Appearance', colors: cs),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Switch to a darker colour scheme to reduce eye strain',
            value: state.isDarkMode,
            onChanged: state.setDarkMode,
            colors: cs,
          ),
          const SizedBox(height: 24),

          // ── Section: Accessibility ────────────────────────────────────
          _SettingsSectionLabel(label: 'Accessibility', colors: cs),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.record_voice_over_rounded,
            title: 'Voiceover',
            subtitle:
                'Automatically read questions aloud in the voice recording section',
            value: state.isVoiceoverEnabled,
            onChanged: state.setVoiceoverEnabled,
            colors: cs,
          ),
          const SizedBox(height: 14),

          // ── Speed slider ───────────────────────────────────────────────
          _SpeedSlider(
            value: state.voiceoverSpeed,
            onChanged: state.setVoiceoverSpeed,
            colors: cs,
          ),
          const SizedBox(height: 24),

          // ── Section: Voice Engine ─────────────────────────────────────
          _SettingsSectionLabel(label: 'Voice Engine', colors: cs),
          const SizedBox(height: 10),
          const _KokoroModelTile(),
        ],
      ),
    );
  }
}

// ── Speed slider ──────────────────────────────────────────────────────────

class _SpeedSlider extends StatelessWidget {
  const _SpeedSlider({
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final SACAColorScheme colors;

  static const List<String> _labels = <String>[
    'Very Slow',
    'Slow',
    'Normal',
    'Fast',
    'Very Fast',
  ];

  String get _currentLabel => _labels[(value * 4).round()];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.subtleBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Header row ─────────────────────────────────────────────
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SACAColors.deepClinicalGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: SACAColors.deepClinicalGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Speaking Speed',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.charcoal,
                      ),
                    ),
                    Text(
                      'Adjust how quickly voiceover reads questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              // Current level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SACAColors.deepClinicalGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _currentLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SACAColors.deepClinicalGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Turtle ── slider ── Rabbit ─────────────────────────────
          Row(
            children: <Widget>[
              const Text('🐢', style: TextStyle(fontSize: 24)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: SACAColors.deepClinicalGreen,
                    inactiveTrackColor:
                        SACAColors.deepClinicalGreen.withValues(alpha: 0.18),
                    thumbColor: SACAColors.deepClinicalGreen,
                    overlayColor:
                        SACAColors.deepClinicalGreen.withValues(alpha: 0.12),
                    tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
                    activeTickMarkColor: Colors.white,
                    inactiveTickMarkColor:
                        SACAColors.deepClinicalGreen.withValues(alpha: 0.4),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: value,
                    min: 0.0,
                    max: 1.0,
                    divisions: 4,
                    onChanged: onChanged,
                  ),
                ),
              ),
              const Text('🐇', style: TextStyle(fontSize: 24)),
            ],
          ),

          // ── Tick labels ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _labels
                  .map(
                    (String l) => Text(
                      l,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: colors.secondaryText,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label, required this.colors});

  final String label;
  final SACAColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: colors.secondaryText,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Kokoro model download / status tile ───────────────────────────────────

class _KokoroModelTile extends StatelessWidget {
  const _KokoroModelTile();

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs = SACAColorScheme.of(context);
    return ValueListenableBuilder<KokoroState>(
      valueListenable: KokoroTtsService.stateNotifier,
      builder: (BuildContext ctx, KokoroState state, _) {
        return Container(
          decoration: BoxDecoration(
            color: cs.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.subtleBorder),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Header row ──────────────────────────────────────────────
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _iconColor(state).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _icon(state),
                      color: _iconColor(state),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Kokoro Neural Voice',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.charcoal,
                          ),
                        ),
                        Text(
                          _subtitle(state),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.secondaryText,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _iconColor(state).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _badge(state),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _iconColor(state),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Download progress bar ────────────────────────────────────
              if (state == KokoroState.downloading) ...<Widget>[
                const SizedBox(height: 14),
                ValueListenableBuilder<double>(
                  valueListenable: KokoroTtsService.progressNotifier,
                  builder: (BuildContext ctx2, double p, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: p,
                            minHeight: 6,
                            backgroundColor: SACAColors.deepClinicalGreen
                                .withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                SACAColors.deepClinicalGreen),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(p * 100).toStringAsFixed(0)}% of ~326 MB',
                          style: TextStyle(
                              fontSize: 11, color: cs.secondaryText),
                        ),
                      ],
                    );
                  },
                ),
              ],

              // ── Initialising spinner ─────────────────────────────────────
              if (state == KokoroState.initialising) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SACAColors.deepClinicalGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading voice engine…',
                      style:
                          TextStyle(fontSize: 12, color: cs.secondaryText),
                    ),
                  ],
                ),
              ],

              // ── Error message ────────────────────────────────────────────
              if (state == KokoroState.error &&
                  KokoroTtsService.lastError != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  KokoroTtsService.lastError!,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.redAccent),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // ── Action button ────────────────────────────────────────────
              if (state == KokoroState.notDownloaded ||
                  state == KokoroState.error) ...<Widget>[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: SACAColors.deepClinicalGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: KokoroTtsService.downloadAndInit,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      state == KokoroState.error
                          ? 'Retry Download'
                          : 'Download Model (~326 MB)',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static IconData _icon(KokoroState s) {
    switch (s) {
      case KokoroState.notDownloaded: return Icons.download_rounded;
      case KokoroState.downloading:   return Icons.cloud_download_rounded;
      case KokoroState.initialising:  return Icons.hourglass_top_rounded;
      case KokoroState.ready:         return Icons.check_circle_rounded;
      case KokoroState.error:         return Icons.error_outline_rounded;
    }
  }

  static Color _iconColor(KokoroState s) {
    switch (s) {
      case KokoroState.ready:  return SACAColors.deepClinicalGreen;
      case KokoroState.error:  return Colors.redAccent;
      default:                 return SACAColors.deepClinicalGreen;
    }
  }

  static String _badge(KokoroState s) {
    switch (s) {
      case KokoroState.notDownloaded: return 'Not installed';
      case KokoroState.downloading:   return 'Downloading';
      case KokoroState.initialising:  return 'Loading';
      case KokoroState.ready:         return 'Ready';
      case KokoroState.error:         return 'Error';
    }
  }

  static String _subtitle(KokoroState s) {
    switch (s) {
      case KokoroState.notDownloaded:
        return 'High-quality on-device neural voice. One-time download required.';
      case KokoroState.downloading:
        return 'Downloading Kokoro model — please keep the app open.';
      case KokoroState.initialising:
        return 'Setting up the voice engine, this takes a few seconds…';
      case KokoroState.ready:
        return 'Kokoro neural voice is active. Sounds great, works offline.';
      case KokoroState.error:
        return 'Something went wrong. Check your internet connection and retry.';
    }
  }
}

// ── Settings tiles ─────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final SACAColorScheme colors;

  @override
  Widget build(BuildContext context) {
    // The outer Container provides border + shadow via DecoratedBox.
    // The inner Material provides the background colour AND the ink-splash
    // surface that SwitchListTile (a ListTile) needs to paint correctly.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.subtleBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SACAColors.deepClinicalGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: SACAColors.deepClinicalGreen, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.charcoal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: colors.secondaryText,
            height: 1.35,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: SACAColors.deepClinicalGreen,
        activeTrackColor: SACAColors.deepClinicalGreen.withValues(alpha: 0.4),
      ),
        ),   // closes Material
    );       // closes Container
  }
}
