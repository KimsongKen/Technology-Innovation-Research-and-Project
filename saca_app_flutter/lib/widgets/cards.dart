part of '../main.dart';

// ── Global quick-action bar ───────────────────────────────────────────────
class SACAQuickActions extends StatelessWidget {
  const SACAQuickActions({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final SACAAppState state   = SACAStateScope.of(context);
    final SACAColorScheme cs   = SACAColorScheme.of(context);
    final Color ic             = color ?? cs.charcoal;
    final bool isDark          = state.isDarkMode;
    final bool voiceOn         = state.isVoiceoverEnabled;
    final bool isWarlpiri      = state.selectedLanguage == AppLanguage.warlpiri;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _QBtn(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            color: ic,
            onTap: () => state.setDarkMode(!isDark),
          ),
          _QBtn(
            icon: Icons.translate_rounded,
            tooltip: isWarlpiri ? 'Switch to English' : 'Switch to Warlpiri',
            color: isWarlpiri ? SACAColors.warlpiriOrange : ic,
            onTap: () => state.setLanguage(
              isWarlpiri ? AppLanguage.english : AppLanguage.warlpiri,
            ),
          ),
          _QBtn(
            icon: voiceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            tooltip: voiceOn ? 'Mute voiceover' : 'Enable voiceover',
            color: voiceOn ? ic : ic.withValues(alpha: 0.35),
            onTap: () => state.setVoiceoverEnabled(!voiceOn),
          ),
          _QBtn(
            icon: Icons.settings_rounded,
            tooltip: 'Settings',
            color: ic,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _QBtn extends StatelessWidget {
  const _QBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData     icon;
  final String       tooltip;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

// ── Language selection card ───────────────────────────────────────────────
class LanguageCard extends StatelessWidget {
  const LanguageCard({
    super.key,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final Color     accentColor;
  final String    title;
  final String    subtitle;
  final IconData  icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs   = SACAColorScheme.of(context);
    final bool isDark          = Theme.of(context).brightness == Brightness.dark;

    return HoverScaleCard(
      onTap: onTap,
      builder: (bool active) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.cardBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: active
                  ? accentColor.withValues(alpha: 0.65)
                  : cs.subtleBorder,
              width: active ? 1.5 : 1.0,
            ),
            boxShadow: <BoxShadow>[
              if (active)
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  blurRadius: 36,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.07),
                blurRadius: isDark ? 28 : 18,
                offset: Offset(0, isDark ? 8 : 5),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxHeight < 220;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ── Glowing icon circle ───────────────────────────────────
                  Container(
                    width:  compact ? 50 : 62,
                    height: compact ? 50 : 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.13),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.30),
                        width: 1.0,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.18),
                          blurRadius: 18,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: compact ? 26 : 32,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 20),

                  // ── Language name ─────────────────────────────────────────
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.charcoal,
                      fontSize: compact ? 22 : 30,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle ──────────────────────────────────────────────
                  Text(
                    subtitle,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),

                  // ── Bottom accent bar ─────────────────────────────────────
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(
                        colors: <Color>[
                          accentColor,
                          accentColor.withValues(alpha: 0.30),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ── Reporting-method card ─────────────────────────────────────────────────
class ReportModeCard extends StatelessWidget {
  const ReportModeCard({super.key, required this.data, required this.onTap});

  final ReportModeCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs = SACAColorScheme.of(context);
    final bool isDark        = Theme.of(context).brightness == Brightness.dark;

    return HoverScaleCard(
      onTap: onTap,
      builder: (bool active) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cs.cardBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: active
                  ? data.accentColor.withValues(alpha: 0.65)
                  : cs.subtleBorder,
              width: active ? 1.5 : 1.0,
            ),
            boxShadow: <BoxShadow>[
              if (active)
                BoxShadow(
                  color: data.accentColor
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                  blurRadius: 32,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.38 : 0.06),
                blurRadius: isDark ? 24 : 16,
                offset: Offset(0, isDark ? 6 : 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxHeight < 220;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ── Recommended badge ─────────────────────────────────────
                  if (data.recommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: data.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: data.accentColor.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: data.accentColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            SACAStrings.tr(
                              context: context,
                              english: 'Recommended',
                              warlpiri: 'Recommended',
                            ),
                            style: TextStyle(
                              color:      data.accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize:   11,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (data.recommended) SizedBox(height: compact ? 8 : 12),

                  // ── Glowing icon ──────────────────────────────────────────
                  Hero(
                    tag: data.heroTag,
                    child: Container(
                      width:  compact ? 48 : 58,
                      height: compact ? 48 : 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: data.accentColor.withValues(alpha: 0.13),
                        border: Border.all(
                          color: data.accentColor.withValues(alpha: 0.28),
                          width: 1.0,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: data.accentColor.withValues(
                              alpha: active ? 0.25 : 0.10,
                            ),
                            blurRadius: active ? 20 : 12,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Icon(
                        data.icon,
                        color: data.accentColor,
                        size: compact ? 24 : 30,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 16),

                  // ── Title ─────────────────────────────────────────────────
                  Text(
                    data.title,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:      cs.charcoal,
                      fontSize:   compact ? 18 : 20,
                      height:     1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),

                  // ── Description ───────────────────────────────────────────
                  Text(
                    data.description,
                    maxLines: compact ? 2 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:    cs.secondaryText,
                      fontSize: compact ? 12 : 13,
                      height:   1.40,
                    ),
                  ),
                  const Spacer(),

                  // ── Bottom accent bar ─────────────────────────────────────
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: data.accentColor,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: data.accentColor.withValues(alpha: 0.40),
                          blurRadius: 8,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ── Hover/scale interaction wrapper ──────────────────────────────────────
class HoverScaleCard extends StatefulWidget {
  const HoverScaleCard({
    super.key,
    required this.onTap,
    required this.builder,
  });

  final VoidCallback onTap;
  final Widget Function(bool active) builder;

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _isHovered  = false;
  bool _isPressed  = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _isHovered || _isPressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale:    active ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve:    Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: widget.onTap,
            onHighlightChanged: (bool pressed) {
              if (_isPressed != pressed) setState(() => _isPressed = pressed);
            },
            child: widget.builder(active),
          ),
        ),
      ),
    );
  }
}

// ── Legacy base card (kept for any remaining usages) ──────────────────────
class _BaseCard extends StatelessWidget {
  const _BaseCard({
    required this.active,
    required this.accentColor,
    required this.child,
  });

  final bool  active;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs = SACAColorScheme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: active ? accentColor.withValues(alpha: 0.60) : cs.subtleBorder,
          width: active ? 1.5 : 1.0,
        ),
        boxShadow: <BoxShadow>[
          if (active)
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
              blurRadius: 32,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.07),
            blurRadius: isDark ? 24 : 16,
            offset: Offset(0, isDark ? 6 : 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
