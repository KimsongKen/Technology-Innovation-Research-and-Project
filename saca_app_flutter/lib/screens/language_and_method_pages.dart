part of '../main.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key, required this.triageService});

  final TriageService triageService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 620) {
              return _MobileLanguageSelection(triageService: triageService);
            }
            return _DesktopLanguageSelection(triageService: triageService);
          },
        ),
      ),
    );
  }
}

// ── Desktop language selection ────────────────────────────────────────────

class _DesktopLanguageSelection extends StatelessWidget {
  const _DesktopLanguageSelection({required this.triageService});

  final TriageService triageService;

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs    = SACAColorScheme.of(context);
    final bool            isDark = Theme.of(context).brightness == Brightness.dark;

    // Subtle full-page gradient so the colourful cards pop.
    final Color bgTop = isDark
        ? const Color(0xFF0A0F0C)
        : const Color(0xFFEFF5F2);
    final Color bgBot = isDark
        ? const Color(0xFF060908)
        : const Color(0xFFE3EDE8);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: <Color>[bgTop, bgBot],
        ),
      ),
      child: Stack(
        children: <Widget>[
          // ── Decorative blurred glow orbs (background depth) ───────────────
          Positioned(
            top: -80, left: -60,
            child: _GlowOrb(
              color: SACAColors.warlpiriOrange.withValues(alpha: isDark ? 0.12 : 0.08),
              size:  360,
            ),
          ),
          Positioned(
            bottom: -80, right: -60,
            child: _GlowOrb(
              color: SACAColors.clinicalGreen.withValues(alpha: isDark ? 0.14 : 0.10),
              size:  380,
            ),
          ),

          // ── Quick-action bar ───────────────────────────────────────────────
          Positioned(
            top:   16,
            right: 20,
            child: SACAQuickActions(
              color: isDark ? Colors.white.withValues(alpha: 0.75) : cs.charcoal,
            ),
          ),

          // ── Main centered content ──────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[

                      // ── Brand lockup: title + trailing shield ────────────────
                      _SACABrandLockup(
                        titleColor: cs.charcoal,
                        subtitleColor: cs.secondaryText,
                        titleSize: 56,
                        badgeSize: 52,
                        subtitleSize: 15,
                      ),
                      const SizedBox(height: 36),

                      // ── Separator with label ─────────────────────────────────
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: 1,
                              color: cs.subtleBorder,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'SELECT YOUR LANGUAGE',
                              style: TextStyle(
                                color: cs.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: cs.subtleBorder,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Language cards ───────────────────────────────────────
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints box) {
                          final bool stackCards = box.maxWidth < 620;
                          final Widget warlpiriCard = _DeskLangCard(
                            title: 'Warlpiri',
                            subtitle: 'Wayi!  Yuendumu',
                            description:
                                'Indigenous language mode for remote communities',
                            icon: Icons.record_voice_over_rounded,
                            accentColor: SACAColors.warlpiriOrange,
                            accentDark: const Color(0xFF7A2D00),
                            onTap: () => _openReportingMethod(
                              context, triageService, AppLanguage.warlpiri,
                            ),
                          );
                          final Widget englishCard = _DeskLangCard(
                            title: 'English',
                            subtitle: 'Hello!  Clinical mode',
                            description:
                                'Standard clinical interface for healthcare workers',
                            icon: Icons.language_rounded,
                            accentColor: SACAColors.clinicalGreen,
                            accentDark: const Color(0xFF0A5C28),
                            onTap: () => _openReportingMethod(
                              context, triageService, AppLanguage.english,
                            ),
                          );

                          if (stackCards) {
                            return Column(
                              children: <Widget>[
                                warlpiriCard,
                                const SizedBox(height: 20),
                                englishCard,
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              warlpiriCard,
                              const SizedBox(width: 24),
                              englishCard,
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 28),
                      Text(
                        'Tap a card to begin your clinical session',
                        style: TextStyle(
                          color: cs.secondaryText.withValues(alpha: 0.70),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SACA brand lockup (title + trailing shield) ───────────────────────────

class _SACABrandLockup extends StatelessWidget {
  const _SACABrandLockup({
    required this.titleColor,
    required this.subtitleColor,
    this.titleSize = 48,
    this.badgeSize = 44,
    this.subtitleSize = 13.5,
    this.alignStart = false,
    this.subtitle,
  });

  final Color  titleColor;
  final Color  subtitleColor;
  final double titleSize;
  final double badgeSize;
  final double subtitleSize;
  final bool   alignStart;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final CrossAxisAlignment crossAlign = alignStart
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;

    return Column(
      crossAxisAlignment: crossAlign,
      children: <Widget>[
        Row(
          mainAxisSize: alignStart ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'SACA',
              style: TextStyle(
                color: titleColor,
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -2.2,
                height: 1.0,
              ),
            ),
            SizedBox(width: badgeSize * 0.22),
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF1B8C42),
                    SACAColors.clinicalGreen,
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: SACAColors.clinicalGreen.withValues(alpha: 0.38),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: badgeSize * 0.52,
              ),
            ),
          ],
        ),
        SizedBox(height: subtitleSize * 0.45),
        Text(
          subtitle ?? 'Smart Adaptive Clinical Assistant',
          style: TextStyle(
            color: subtitleColor,
            fontSize: subtitleSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

// ── Blurred glow orb (page background decoration) ────────────────────────

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color  color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, Colors.transparent],
          stops:  const <double>[0.0, 1.0],
        ),
      ),
    );
  }
}

// ── Desktop language card (full-gradient, hover-animated) ─────────────────

class _DeskLangCard extends StatefulWidget {
  const _DeskLangCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.accentDark,
    required this.onTap,
  });

  final String     title;
  final String     subtitle;
  final String     description;
  final IconData   icon;
  final Color      accentColor;
  final Color      accentDark;
  final VoidCallback onTap;

  @override
  State<_DeskLangCard> createState() => _DeskLangCardState();
}

class _DeskLangCardState extends State<_DeskLangCard> {
  bool _hovered = false;

  static const double _cardWidth  = 280;
  static const double _cardHeight = 320;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale:    _hovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve:    Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve:    Curves.easeOutCubic,
            width:    _cardWidth,
            height:   _cardHeight,
            padding:  const EdgeInsets.fromLTRB(24, 26, 24, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: <Color>[
                  widget.accentColor,
                  widget.accentDark,
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.accentColor
                      .withValues(alpha: _hovered ? 0.50 : 0.28),
                  blurRadius:   _hovered ? 48 : 28,
                  spreadRadius: -4,
                  offset:       Offset(0, _hovered ? 16 : 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: _hovered ? 0.22 : 0.12),
                  blurRadius: _hovered ? 24 : 14,
                  offset:     const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width:  56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:        Colors.white,
                    fontSize:     28,
                    fontWeight:   FontWeight.w900,
                    height:       1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:      Colors.white.withValues(alpha: 0.80),
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:  Colors.white.withValues(alpha: 0.58),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: _hovered ? 0.24 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Tap to begin',
                        style: TextStyle(
                          color:      Colors.white,
                          fontSize:   13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSlide(
                        offset: _hovered
                            ? const Offset(0.15, 0)
                            : Offset.zero,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size:  15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportingMethodPage extends StatelessWidget {
  const ReportingMethodPage({super.key, required this.triageService});

  final TriageService triageService;

  @override
  Widget build(BuildContext context) {
    final List<ReportModeCardData> methods = _reportMethods(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 620) {
              return _MobileReportingMethod(
                methods: methods,
                triageService: triageService,
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _PageBackButton(
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          const SACAQuickActions(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _WindowHeader(
                        icon: Icons.assignment_rounded,
                        title: SACAStrings.tr(
                          context: context,
                          english: 'How to report',
                          warlpiri: 'Report nyampu',
                        ),
                        subtitle: SACAStrings.tr(
                          context: context,
                          english: 'Choose one clinical input method',
                          warlpiri: 'Clinical input nyampu pina',
                        ),
                      ),
                      const SizedBox(height: 22),
                      Expanded(
                        child: LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final int columns = constraints.maxWidth >= 980
                                    ? 3
                                    : 1;
                                return GridView.builder(
                                  itemCount: methods.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: 18,
                                        mainAxisSpacing: 18,
                                        childAspectRatio: columns == 3
                                            ? 1.03
                                            : 1.7,
                                      ),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final ReportModeCardData data =
                                            methods[index];
                                        return ReportModeCard(
                                          data: data,
                                          onTap: () => _openWorkspace(
                                            context,
                                            triageService,
                                            data,
                                          ),
                                        );
                                      },
                                );
                              },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileLanguageSelection extends StatelessWidget {
  const _MobileLanguageSelection({required this.triageService});

  final TriageService triageService;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: <Widget>[
        Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? <Color>[const Color(0xFF0F2318), const Color(0xFF081410)]
                      : <Color>[const Color(0xFF1B8C42), SACAColors.clinicalGreen],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: SACAColors.clinicalGreen.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.18
                        : 0.28,
                  ),
                ),
              ),
              child: _SACABrandLockup(
                titleColor: Colors.white,
                subtitleColor: Colors.white.withValues(alpha: 0.72),
                titleSize: 34,
                badgeSize: 38,
                subtitleSize: 12.5,
                alignStart: true,
                subtitle: 'Choose language / Pina yimi',
              ),
            ),
            const Positioned(
              top: 4,
              right: 0,
              child: SACAQuickActions(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 176,
          child: LanguageCard(
            accentColor: SACAColors.warlpiriOrange,
            title: 'Warlpiri',
            subtitle: 'Wayi! Yuendumu',
            icon: Icons.record_voice_over_rounded,
            onTap: () => _openReportingMethod(
              context,
              triageService,
              AppLanguage.warlpiri,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 176,
          child: LanguageCard(
            accentColor: SACAColors.deepClinicalGreen,
            title: 'English',
            subtitle: 'Hello! Clinical mode',
            icon: Icons.language_rounded,
            onTap: () => _openReportingMethod(
              context,
              triageService,
              AppLanguage.english,
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileReportingMethod extends StatelessWidget {
  const _MobileReportingMethod({
    required this.methods,
    required this.triageService,
  });

  final List<ReportModeCardData> methods;
  final TriageService triageService;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            _PageBackButton(onPressed: () => Navigator.of(context).pop()),
            const Spacer(),
            const SACAQuickActions(),
          ],
        ),
        const SizedBox(height: 10),
        _MobileHeader(
          icon: Icons.assignment_rounded,
          title: SACAStrings.tr(
            context: context,
            english: 'How to report',
            warlpiri: 'Report nyampu',
          ),
          subtitle: SACAStrings.tr(
            context: context,
            english: 'Choose one clinical input method',
            warlpiri: 'Clinical input nyampu pina',
          ),
        ),
        const SizedBox(height: 18),
        for (final ReportModeCardData data in methods) ...<Widget>[
          _MobileReportMethodCard(
            data: data,
            onTap: () => _openWorkspace(context, triageService, data),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _WindowHeader extends StatelessWidget {
  const _WindowHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions,
  });

  final IconData icon;
  final String   title;
  final String   subtitle;
  final Widget?  actions;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: isDark
              ? <Color>[const Color(0xFF0F2318), const Color(0xFF081410)]
              : <Color>[const Color(0xFF1B8C42), SACAColors.clinicalGreen],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SACAColors.clinicalGreen.withValues(alpha: isDark ? 0.18 : 0.30),
          width: 1.0,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SACAColors.clinicalGreen.withValues(alpha: isDark ? 0.10 : 0.18),
            blurRadius: 32,
            spreadRadius: -5,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Icon circle with glow
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1.0,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: SACAColors.clinicalGreen.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   30,
                    fontWeight: FontWeight.w800,
                    height:     1.05,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:    Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    height:   1.30,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null) ...<Widget>[
            const SizedBox(width: 12),
            actions!,
          ],
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions,
  });

  final IconData icon;
  final String   title;
  final String   subtitle;
  final Widget?  actions;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: isDark
              ? <Color>[const Color(0xFF0F2318), const Color(0xFF081410)]
              : <Color>[const Color(0xFF1B8C42), SACAColors.clinicalGreen],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: SACAColors.clinicalGreen.withValues(alpha: isDark ? 0.18 : 0.28),
          width: 1.0,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SACAColors.clinicalGreen.withValues(alpha: isDark ? 0.10 : 0.16),
            blurRadius: 28,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   24,
                    fontWeight: FontWeight.w800,
                    height:     1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:    Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    height:   1.30,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null) ...<Widget>[
            const SizedBox(width: 8),
            actions!,
          ],
        ],
      ),
    );
  }
}

class _MobileReportMethodCard extends StatelessWidget {
  const _MobileReportMethodCard({required this.data, required this.onTap});

  final ReportModeCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs = SACAColorScheme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.subtleBorder),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: isDark ? 20 : 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Hero(
                tag: data.heroTag,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: data.accentColor.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: data.accentColor.withValues(alpha: 0.26),
                      width: 1.0,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: data.accentColor.withValues(alpha: 0.14),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(data.icon, color: data.accentColor, size: 27),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            data.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:      cs.charcoal,
                              fontSize:   18,
                              fontWeight: FontWeight.w800,
                              height:     1.15,
                            ),
                          ),
                        ),
                        if (data.recommended) ...<Widget>[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.verified_rounded,
                            color: data.accentColor,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:    cs.secondaryText,
                        fontSize: 13,
                        height:   1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: data.accentColor,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageBackButton extends StatelessWidget {
  const _PageBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: SACAColors.clinicalGreen,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_rounded, size: 20),
      label: Text(
        SACAStrings.tr(context: context, english: 'Back', warlpiri: 'Rete'),
      ),
    );
  }
}

void _openReportingMethod(
  BuildContext context,
  TriageService triageService,
  AppLanguage language,
) {
  SACAStateScope.of(context).setLanguage(language);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReportingMethodPage(triageService: triageService),
    ),
  );
}

void _openWorkspace(
  BuildContext context,
  TriageService triageService,
  ReportModeCardData data,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WorkspacePage(
        mode: data.mode,
        heroTag: data.heroTag,
        triageService: triageService,
      ),
    ),
  );
}

List<ReportModeCardData> _reportMethods(BuildContext context) {
  return <ReportModeCardData>[
    ReportModeCardData(
      mode: ReportMode.voice,
      heroTag: 'mode-voice',
      icon: Icons.mic_rounded,
      accentColor: SACAColors.deepClinicalGreen,
      title: SACAStrings.tr(
        context: context,
        english: 'Voice / Spoken',
        warlpiri: 'Yarn / Speak',
      ),
      description: SACAStrings.tr(
        context: context,
        english: 'Record speech for rapid triage notes',
        warlpiri: 'Wangka-ku record marda triage notes',
      ),
      recommended: true,
    ),
    ReportModeCardData(
      mode: ReportMode.selection,
      heroTag: 'mode-selection',
      icon: Icons.touch_app_rounded,
      accentColor: SACAColors.earthClay,
      title: SACAStrings.tr(
        context: context,
        english: 'Selection Symptoms',
        warlpiri: 'Point-kurra Picture-kurra',
      ),
      description: SACAStrings.tr(
        context: context,
        english: 'Use visual picklists and body-map prompts',
        warlpiri: 'Picture picklist and body-map prompt',
      ),
    ),
    ReportModeCardData(
      mode: ReportMode.text,
      heroTag: 'mode-text',
      icon: Icons.edit_note_rounded,
      accentColor: SACAColors.warningRedBrown,
      title: SACAStrings.tr(
        context: context,
        english: 'Type Symptom',
        warlpiri: 'Type symptom',
      ),
      description: SACAStrings.tr(
        context: context,
        english: 'Enter structured clinical notes by keyboard',
        warlpiri: 'Keyboard-kurra clinical notes type',
      ),
    ),
  ];
}
