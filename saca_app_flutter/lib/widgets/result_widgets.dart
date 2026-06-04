part of '../main.dart';

// ── WHOOP-style triage arc ring ───────────────────────────────────────────

class _TriageRingPainter extends CustomPainter {
  const _TriageRingPainter({
    required this.color,
    required this.progress,   // 0.0–1.0
  });

  final Color  color;
  final double progress;
  static const double strokeWidth = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide / 2) - strokeWidth / 2 - 2;

    // Track ring (dim background)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..color   = color.withValues(alpha: 0.15)
        ..style   = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Glow pass (wider, blurry)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color  = color.withValues(alpha: 0.35)
        ..style  = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap   = StrokeCap.round
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color       = color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TriageRingPainter old) =>
      old.color != color || old.progress != progress;
}

// ── Animated triage ring widget ───────────────────────────────────────────

class _AnimatedTriageRing extends StatefulWidget {
  const _AnimatedTriageRing({
    required this.color,
    required this.targetProgress,
    required this.sublabel,
    this.size = 170.0,
  });

  final Color  color;
  final double targetProgress;
  final String sublabel;
  final double size;

  @override
  State<_AnimatedTriageRing> createState() => _AnimatedTriageRingState();
}

class _AnimatedTriageRingState extends State<_AnimatedTriageRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)
        .drive(Tween<double>(begin: 0, end: widget.targetProgress));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs = SACAColorScheme.of(context);
    // Safe inner width: ring diameter minus two stroke widths minus glow margin.
    final double innerPad  = widget.size * 0.16;
    final double innerSize = widget.size - innerPad * 2;

    return SizedBox(
      width:  widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (BuildContext ctx, _) {
          // Show live % number — always 2–3 chars, never overflows.
          final int pct = (_anim.value * 100).round();

          return CustomPaint(
            painter: _TriageRingPainter(
              color:    widget.color,
              progress: _anim.value,
            ),
            child: Center(
              child: SizedBox(
                width:  innerSize,
                height: innerSize,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Percentage (animates live — always short)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$pct%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:         widget.color,
                          fontSize:      widget.size * 0.20,
                          fontWeight:    FontWeight.w900,
                          height:        1.0,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Fixed sublabel ("TRIAGE") — always short
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.sublabel.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:         cs.secondaryText,
                          fontSize:      widget.size * 0.082,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Pain intensity meter bar ──────────────────────────────────────────────
//
// Renders a smooth gradient bar (green → amber → red) with a positioned
// indicator arrow and a numeric readout.  Score is 1–10 (clamped).

class _PainMeterBar extends StatelessWidget {
  const _PainMeterBar({required this.score});

  final int score; // 1–10

  Color get _color {
    if (score <= 3) return SACAColors.triageSafe;
    if (score <= 6) return SACAColors.triageModerate;
    return SACAColors.triageCritical;
  }

  String get _label {
    if (score <= 3) return 'Low';
    if (score <= 6) return 'Moderate';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs = SACAColorScheme.of(context);
    // Normalised 0–1 position of the indicator (score 1 → far left, 10 → far right)
    final double pos = ((score.clamp(1, 10) - 1) / 9.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ── Header row ────────────────────────────────────────────────────
        Row(
          children: <Widget>[
            Icon(Icons.speed_rounded, size: 14, color: cs.secondaryText),
            const SizedBox(width: 6),
            Text(
              'PAIN INTENSITY',
              style: TextStyle(
                color:       cs.secondaryText,
                fontSize:    10,
                fontWeight:  FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            // Numeric score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _color.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${score.clamp(1, 10)}',
                    style: TextStyle(
                      color:      _color,
                      fontSize:   15,
                      fontWeight: FontWeight.w900,
                      height:     1.0,
                    ),
                  ),
                  Text(
                    ' / 10  ·  $_label',
                    style: TextStyle(
                      color:      _color,
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Gradient bar + marker ─────────────────────────────────────────
        LayoutBuilder(
          builder: (BuildContext ctx, BoxConstraints bc) {
            const double barH      = 12.0;
            const double thumbR    = 9.0;
            const double calloutH  = 24.0;
            const double calloutW  = 36.0;
            const double calloutGap = 6.0;
            final double thumbX    = pos * bc.maxWidth;
            final double calloutLeft =
                (thumbX - calloutW / 2).clamp(0.0, bc.maxWidth - calloutW);

            return Column(
              children: <Widget>[
                // Callout row — separate from bar so score never overlaps thumb
                SizedBox(
                  height: calloutH,
                  width:  double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: calloutLeft,
                        child: Container(
                          width:  calloutW,
                          height: calloutH,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:        _color,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: _color.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${score.clamp(1, 10)}',
                            style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   13,
                              fontWeight: FontWeight.w900,
                              height:     1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: calloutGap),
                SizedBox(
                  height: barH + thumbR,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left:   0,
                        right:  0,
                        top:    thumbR / 2,
                        height: barH,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(barH / 2),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  SACAColors.triageSafe,
                                  Color(0xFFB8D830),
                                  SACAColors.triageModerate,
                                  Color(0xFFFF6422),
                                  SACAColors.triageCritical,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left:   thumbX - 1.5,
                        top:    thumbR / 2,
                        height: barH,
                        width:  3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                      Positioned(
                        left: thumbX - thumbR,
                        top:  thumbR / 2 + barH / 2 - thumbR,
                        child: Container(
                          width:  thumbR * 2,
                          height: thumbR * 2,
                          decoration: BoxDecoration(
                            color:  Colors.white,
                            shape:  BoxShape.circle,
                            border: Border.all(color: _color, width: 2.5),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: _color.withValues(alpha: 0.55),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── LOW / HIGH labels ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'LOW',
                      style: TextStyle(
                        color:       SACAColors.triageSafe,
                        fontSize:    9,
                        fontWeight:  FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'HIGH',
                      style: TextStyle(
                        color:       SACAColors.triageCritical,
                        fontSize:    9,
                        fontWeight:  FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Triage header card ────────────────────────────────────────────────────

class _TriageHeader extends StatefulWidget {
  const _TriageHeader({
    required this.triageLevel,
    required this.topCondition,
    this.languageBadge,
    this.confidence  = 0.0,
    this.top3Symptoms = const <String>[],
    this.recommendation = '',
  });

  final String       triageLevel;
  final String       topCondition;
  final String?      languageBadge;
  final double       confidence;
  final List<String> top3Symptoms;
  final String       recommendation;

  @override
  State<_TriageHeader> createState() => _TriageHeaderState();
}

class _TriageHeaderState extends State<_TriageHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double>   _fadeIn;
  late final Animation<Offset>   _slideIn;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Severity class explanation popup ───────────────────────────────────────
  void _showSeverityInfo(BuildContext context) {
    final SACAColorScheme cs    = SACAColorScheme.of(context);
    final bool            isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (BuildContext ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color:        cs.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.subtleBorder, width: 1.2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: isDark ? 0.50 : 0.10),
                    blurRadius: 40,
                    offset:     const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.help_outline_rounded,
                          color: SACAColors.clinicalGreen,
                          size:  20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'How severity is classified',
                            style: TextStyle(
                              color:      cs.charcoal,
                              fontSize:   16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            width:  32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cs.inputFill,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size:  16,
                              color: cs.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: cs.subtleBorder),

                  // Explanation text
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: Text(
                      'The AI model analyses your symptoms and assigns a severity class. '
                      'The ring shows the model\'s confidence within that class — a higher % '
                      'means a more confident assessment.',
                      style: TextStyle(
                        color:    cs.secondaryText,
                        fontSize: 13,
                        height:   1.5,
                      ),
                    ),
                  ),

                  // Three tiers
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      children: <Widget>[
                        _severityRow(
                          cs:    cs,
                          color: SACAColors.triageSafe,
                          icon:  Icons.check_circle_outline_rounded,
                          level: 'MILD',
                          desc:  'Low concern. Symptoms are manageable at home. '
                                 'A routine clinic check-up is recommended but not urgent.',
                        ),
                        const SizedBox(height: 8),
                        _severityRow(
                          cs:    cs,
                          color: SACAColors.triageModerate,
                          icon:  Icons.warning_amber_rounded,
                          level: 'MODERATE',
                          desc:  'Moderate concern. You should attend a clinic within '
                                 '4 hours. Monitor symptoms closely for any worsening.',
                        ),
                        const SizedBox(height: 8),
                        _severityRow(
                          cs:    cs,
                          color: SACAColors.triageCritical,
                          icon:  Icons.emergency_rounded,
                          level: 'SEVERE / CRITICAL',
                          desc:  'High concern. Seek emergency medical care immediately. '
                                 'Alert the nearest medical officer and do not delay.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _severityRow({
    required SACAColorScheme cs,
    required Color    color,
    required IconData icon,
    required String   level,
    required String   desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  level,
                  style: TextStyle(
                    color:      color,
                    fontSize:   12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    color:    cs.charcoal,
                    fontSize: 12,
                    height:   1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    // ── Look up offline disease library ────────────────────────────────────
    final DiseaseInfo? info = DiseaseLibrary.lookup(widget.topCondition);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close details',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (BuildContext ctx, Animation<double> a1,
          Animation<double> a2, Widget _) {
        final double blur = 16 * a1.value;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: FadeTransition(
            opacity: a1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.93, end: 1.0).animate(
                CurvedAnimation(parent: a1, curve: Curves.easeOutCubic),
              ),
              child: _DiseaseDetailsSheet(
                topCondition:   widget.topCondition,
                triageLevel:    widget.triageLevel,
                top3Symptoms:   widget.top3Symptoms,
                recommendation: widget.recommendation,
                confidence:     widget.confidence,
                libraryInfo:    info,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs         = SACAColorScheme.of(context);
    final bool            isDark     = Theme.of(context).brightness == Brightness.dark;
    final Color           triageColor = TriagePresentation.colorForLevel(widget.triageLevel);
    // Confidence-driven ring fill: scales within the correct severity band so
    // the same disease at different confidence levels shows different arc fills.
    final double          ringFill   = TriagePresentation.ringFillDynamic(
      widget.triageLevel,
      widget.confidence,
    );
    final String          assessedAt = TimeOfDay.now().format(context);
    final bool showConf = widget.confidence > 0 && widget.confidence <= 1.0;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          decoration: BoxDecoration(
            color: cs.cardBackground,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: triageColor.withValues(alpha: isDark ? 0.25 : 0.20),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:       triageColor.withValues(alpha: isDark ? 0.18 : 0.12),
                blurRadius:  40,
                spreadRadius: -6,
                offset:      const Offset(0, 14),
              ),
              BoxShadow(
                color:      Colors.black.withValues(alpha: isDark ? 0.45 : 0.06),
                blurRadius: isDark ? 30 : 18,
                offset:     const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Row: ring left, details right ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // WHOOP-style arc ring — severity level inside
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _AnimatedTriageRing(
                        color:          triageColor,
                        targetProgress: ringFill,
                        sublabel: widget.triageLevel.split(' ').first.toUpperCase(),
                        size:     110,
                      ),
                      const SizedBox(height: 8),
                      // ── Severity info button ─────────────────────────────
                      GestureDetector(
                        onTap: () => _showSeverityInfo(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.inputFill,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: cs.subtleBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.help_outline_rounded,
                                size:  11,
                                color: cs.secondaryText,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                SACAStrings.tr(
                                  context: context,
                                  english:  'How this works',
                                  warlpiri: 'Nyiya-nyanu kuja',
                                ),
                                style: TextStyle(
                                  color:      cs.secondaryText,
                                  fontSize:   10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),

                  // Details column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Timestamp + read-aloud button
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                SACAStrings.tr(
                                  context: context,
                                  english:  'ASSESSED $assessedAt',
                                  warlpiri: 'YIMI-JARRI $assessedAt',
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:       cs.secondaryText,
                                  fontWeight:  FontWeight.w700,
                                  fontSize:    10,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            _TtsButton(
                              size: 30,
                              text:
                                  'Predicted condition: ${widget.topCondition}. '
                                  'Severity: ${widget.triageLevel}. '
                                  '${widget.recommendation.trim().isNotEmpty ? widget.recommendation.trim() : ''}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Badge row
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            if (widget.languageBadge != null &&
                                widget.languageBadge!.trim().isNotEmpty)
                              _SmallBadge(
                                label: widget.languageBadge!.trim(),
                                color: cs.secondaryText,
                                borderColor: cs.subtleBorder,
                              ),
                            if (showConf)
                              _ConfidenceBadge(
                                confidence:  widget.confidence,
                                accentColor: triageColor,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Section label
                        Text(
                          SACAStrings.tr(
                            context: context,
                            english:  'PREDICTED DISEASE',
                            warlpiri: 'WARLU-YIRRKARDU',
                          ),
                          style: TextStyle(
                            color:       cs.secondaryText,
                            fontSize:    10,
                            fontWeight:  FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Disease name — FittedBox prevents mid-word breaks
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.topCondition,
                            style: TextStyle(
                              color:      cs.charcoal,
                              fontSize:   20,
                              height:     1.25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // DETAILS button
                        GestureDetector(
                          onTap: () => _showDetails(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical:   9,
                            ),
                            decoration: BoxDecoration(
                              color: triageColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: triageColor.withValues(alpha: 0.32),
                                width: 1.1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: triageColor,
                                  size:  15,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  SACAStrings.tr(
                                    context: context,
                                    english:  'DETAILS',
                                    warlpiri: 'YIMI-KARI',
                                  ),
                                  style: TextStyle(
                                    color:       triageColor,
                                    fontSize:    12,
                                    letterSpacing: 0.9,
                                    fontWeight:  FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Disease details full-screen sheet ────────────────────────────────────
//
// Shown by _showDetails(). Uses DiseaseLibrary for offline content and
// falls back gracefully to API-returned data when the disease is not in the
// library.

class _DiseaseDetailsSheet extends StatelessWidget {
  const _DiseaseDetailsSheet({
    required this.topCondition,
    required this.triageLevel,
    required this.top3Symptoms,
    required this.recommendation,
    required this.confidence,
    this.libraryInfo,
  });

  final String       topCondition;
  final String       triageLevel;
  final List<String> top3Symptoms;
  final String       recommendation;
  final double       confidence;
  final DiseaseInfo? libraryInfo;

  // ── Section header helper ─────────────────────────────────────────────────
  Widget _sectionLabel(String text, SACAColorScheme cs) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            color:       cs.secondaryText,
            fontSize:    10,
            fontWeight:  FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
      );

  // ── Symptom chip ──────────────────────────────────────────────────────────
  Widget _symptomChip(
    String label,
    Color accent,
    SACAColorScheme cs, {
    bool fromLibrary = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: fromLibrary
            ? accent.withValues(alpha: 0.08)
            : cs.inputFill,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: fromLibrary
              ? accent.withValues(alpha: 0.25)
              : cs.subtleBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            fromLibrary ? Icons.circle : Icons.person_outline_rounded,
            size:  fromLibrary ? 6 : 11,
            color: fromLibrary ? accent : cs.secondaryText,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label.trim(),
              style: TextStyle(
                color:      fromLibrary ? cs.charcoal : cs.secondaryText,
                fontSize:   13,
                fontWeight: FontWeight.w600,
                height:     1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs    = SACAColorScheme.of(context);
    final bool            isDark = Theme.of(context).brightness == Brightness.dark;
    final Color           triage = TriagePresentation.colorForLevel(triageLevel);
    final IconData?       sevIcon = TriagePresentation.severityIcon(triageLevel);
    final bool            hasLibrary  = libraryInfo != null;
    final bool            hasApiSyms  = top3Symptoms.isNotEmpty;
    final bool            hasRec      = recommendation.trim().isNotEmpty;
    final double          screenH     = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:  720,
          maxHeight: screenH * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Material(
            color:        Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                color:        cs.cardBackground,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: triage.withValues(alpha: isDark ? 0.28 : 0.18),
                  width: 1.3,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color:       triage.withValues(alpha: isDark ? 0.20 : 0.12),
                    blurRadius:  60,
                    spreadRadius: -8,
                    offset:      const Offset(0, 22),
                  ),
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: isDark ? 0.55 : 0.10),
                    blurRadius: isDark ? 45 : 24,
                    offset:     const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[

                    // ── Top accent bar ───────────────────────────────────────
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[triage, triage.withValues(alpha: 0.40)],
                        ),
                      ),
                    ),

                    // ── Sticky header ────────────────────────────────────────
                    Container(
                      color: cs.cardBackground,
                      padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'DISEASE DETAILS',
                                  style: TextStyle(
                                    color:       cs.secondaryText,
                                    fontSize:    10,
                                    fontWeight:  FontWeight.w800,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  topCondition,
                                  style: TextStyle(
                                    color:      cs.charcoal,
                                    fontSize:   24,
                                    fontWeight: FontWeight.w900,
                                    height:     1.15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Severity + confidence badges
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 11, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: triage.withValues(alpha: 0.11),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: triage.withValues(alpha: 0.35),
                                          width: 1.1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          if (sevIcon != null) ...<Widget>[
                                            Icon(sevIcon, color: triage, size: 12),
                                            const SizedBox(width: 5),
                                          ],
                                          Text(
                                            triageLevel.toUpperCase(),
                                            style: TextStyle(
                                              color:      triage,
                                              fontSize:   11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (confidence > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 11, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: cs.inputFill,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${(confidence * 100).round()}% model confidence',
                                          style: TextStyle(
                                            color:      cs.secondaryText,
                                            fontSize:   11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (hasLibrary)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 11, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: SACAColors.clinicalGreen
                                              .withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(
                                              Icons.offline_pin_rounded,
                                              size:  11,
                                              color: SACAColors.clinicalGreen,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Offline library',
                                              style: TextStyle(
                                                color:      SACAColors.clinicalGreen,
                                                fontSize:   11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ── X close button ───────────────────────────────
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width:  36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cs.inputFill,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size:  18,
                                color: cs.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Divider ──────────────────────────────────────────────
                    Container(height: 1, color: cs.subtleBorder),

                    // ── Scrollable body ──────────────────────────────────────
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[

                            // ── What is this disease? (library) ─────────────
                            if (hasLibrary) ...<Widget>[
                              _sectionLabel('WHAT IS ${topCondition.toUpperCase()}?', cs),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.inputFill,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cs.subtleBorder),
                                ),
                                child: Text(
                                  libraryInfo!.overview,
                                  style: TextStyle(
                                    color:    cs.charcoal,
                                    fontSize: 14,
                                    height:   1.60,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                            ],

                            // ── Key fact callout (library) ───────────────────
                            if (hasLibrary &&
                                libraryInfo!.keyFact.isNotEmpty) ...<Widget>[
                              Container(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                                decoration: BoxDecoration(
                                  color: triage.withValues(alpha: isDark ? 0.12 : 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: triage.withValues(alpha: 0.28),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      Icons.lightbulb_rounded,
                                      color: triage,
                                      size:  18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        libraryInfo!.keyFact,
                                        style: TextStyle(
                                          color:    cs.charcoal,
                                          fontSize: 13.5,
                                          height:   1.50,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                            ],

                            // ── Common symptoms (library) ────────────────────
                            if (hasLibrary &&
                                libraryInfo!.commonSymptoms.isNotEmpty) ...<Widget>[
                              _sectionLabel('COMMON SYMPTOMS OF THIS DISEASE', cs),
                              Wrap(
                                spacing:    8,
                                runSpacing: 8,
                                children: libraryInfo!.commonSymptoms
                                    .map((String s) =>
                                        _symptomChip(s, triage, cs))
                                    .toList(),
                              ),
                              const SizedBox(height: 22),
                            ],

                            // ── Divider between library and patient data ─────
                            if (hasLibrary && hasApiSyms) ...<Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Container(height: 1, color: cs.subtleBorder),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'THIS PATIENT',
                                      style: TextStyle(
                                        color:      cs.secondaryText,
                                        fontSize:   9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(height: 1, color: cs.subtleBorder),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                            ],

                            // ── Patient-reported symptoms (API) ──────────────
                            if (hasApiSyms) ...<Widget>[
                              _sectionLabel('REPORTED BY THIS PATIENT', cs),
                              Wrap(
                                spacing:    8,
                                runSpacing: 8,
                                children: top3Symptoms
                                    .map((String s) =>
                                        _symptomChip(s, triage, cs, fromLibrary: false))
                                    .toList(),
                              ),
                              const SizedBox(height: 22),
                            ],

                            // ── Clinical recommendation (API) ────────────────
                            if (hasRec) ...<Widget>[
                              _sectionLabel('CLINICAL RECOMMENDATION', cs),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.inputFill,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cs.subtleBorder),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      Icons.medical_services_outlined,
                                      color: triage,
                                      size:  18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        recommendation.trim(),
                                        style: TextStyle(
                                          color:    cs.charcoal,
                                          fontSize: 14,
                                          height:   1.55,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // ── Fallback when nothing is available ───────────
                            if (!hasLibrary && !hasApiSyms && !hasRec)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'No additional information is available for this condition.',
                                  style: TextStyle(
                                    color:    cs.secondaryText,
                                    fontSize: 13,
                                    height:   1.5,
                                  ),
                                ),
                              ),

                            // ── Offline notice at bottom ─────────────────────
                            if (hasLibrary) ...<Widget>[
                              const SizedBox(height: 20),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size:  13,
                                    color: cs.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Disease information is stored on-device and available offline. Source: public health references (WHO, Mayo Clinic, MedlinePlus).',
                                      style: TextStyle(
                                        color:    cs.secondaryText,
                                        fontSize: 11,
                                        height:   1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Symptom image asset lookup ────────────────────────────────────────────
//
// Maps clinical symptom names (lowercase) to Image83 asset paths.
// Includes common API aliases alongside the canonical filenames.

class _SymptomImages {
  _SymptomImages._();

  static const Map<String, String> _map = <String, String>{
    'headache':                                        'assets/Image83/1.Headache.jpg',
    'head injury or bump':                             'assets/Image83/2.Head injury or bump.jpg',
    'head injury':                                     'assets/Image83/2.Head injury or bump.jpg',
    'neck pain or stiffness':                          'assets/Image83/3.Neck pain or stiffness.jpg',
    'neck pain':                                       'assets/Image83/3.Neck pain or stiffness.jpg',
    'neck stiffness':                                  'assets/Image83/3.Neck pain or stiffness.jpg',
    'jaw pain':                                        'assets/Image83/4.Jaw_pain.jpg',
    'facial swelling or bruising':                     'assets/Image83/5.Facial swelling or bruising.jpg',
    'facial swelling':                                 'assets/Image83/5.Facial swelling or bruising.jpg',
    'eye injury or pain':                              'assets/Image83/6.Eye injury or pain.jpg',
    'eye pain':                                        'assets/Image83/6.Eye injury or pain.jpg',
    'ear pain':                                        'assets/Image83/7.Ear Pain.jpg',
    'earache':                                         'assets/Image83/7.Ear Pain.jpg',
    'toothache or mouth pain':                         'assets/Image83/8.Toothache or mouth pain.jpg',
    'toothache':                                       'assets/Image83/8.Toothache or mouth pain.jpg',
    'mouth pain':                                      'assets/Image83/8.Toothache or mouth pain.jpg',
    'sore throat':                                     'assets/Image83/9.Sore throat.jpg',
    'throat pain':                                     'assets/Image83/9.Sore throat.jpg',
    'difficulty swallowing':                           'assets/Image83/10.Difficulty swallowing.jpg',
    'dysphagia':                                       'assets/Image83/10.Difficulty swallowing.jpg',
    'facial numbness or tingling':                     'assets/Image83/11.Facial numbness or tingling.jpg',
    'facial numbness':                                 'assets/Image83/11.Facial numbness or tingling.jpg',
    'sharp chest pain':                                'assets/Image83/12.Sharp chest pain.jpg',
    'chest pain':                                      'assets/Image83/12.Sharp chest pain.jpg',
    'burning chest pain':                              'assets/Image83/13.Burning chest pain.jpg',
    'rib pain or tenderness':                          'assets/Image83/14.Rib pain or tenderness.jpg',
    'rib pain':                                        'assets/Image83/14.Rib pain or tenderness.jpg',
    'heartburn':                                       'assets/Image83/15.Heartburn.jpg',
    'acid reflux':                                     'assets/Image83/15.Heartburn.jpg',
    'upper abdominal pain':                            'assets/Image83/16.Upper abdominal pain.jpg',
    'epigastric pain':                                 'assets/Image83/16.Upper abdominal pain.jpg',
    'abdominal pain':                                  'assets/Image83/16.Upper abdominal pain.jpg',
    'lower abdominal pain':                            'assets/Image83/17.Lower abdominal pain.jpg',
    'side or flank pain':                              'assets/Image83/18.Side or flank pain.jpg',
    'flank pain':                                      'assets/Image83/18.Side or flank pain.jpg',
    'stomach bloating or cramping':                    'assets/Image83/19.Stomach bloating or cramping.jpg',
    'stomach bloating':                                'assets/Image83/19.Stomach bloating or cramping.jpg',
    'bloating':                                        'assets/Image83/19.Stomach bloating or cramping.jpg',
    'stomach cramping':                                'assets/Image83/19.Stomach bloating or cramping.jpg',
    'groin or pelvic pain':                            'assets/Image83/20.Groin or pelvic pain.jpg',
    'pelvic pain':                                     'assets/Image83/20.Groin or pelvic pain.jpg',
    'upper back pain':                                 'assets/Image83/21.Upper back pain.jpg',
    'lower back pain':                                 'assets/Image83/22.Lower back pain.jpg',
    'back pain':                                       'assets/Image83/22.Lower back pain.jpg',
    'blood in stool or black stool':                   'assets/Image83/23.Blood in stool or black stool.jpg',
    'blood in stool':                                  'assets/Image83/23.Blood in stool or black stool.jpg',
    'black stool':                                     'assets/Image83/23.Blood in stool or black stool.jpg',
    'vomiting blood':                                  'assets/Image83/24.Vomiting blood.jpg',
    'haematemesis':                                    'assets/Image83/24.Vomiting blood.jpg',
    'blood in urine':                                  'assets/Image83/25.Blood in urine.jpg',
    'haematuria':                                      'assets/Image83/25.Blood in urine.jpg',
    'painful urination':                               'assets/Image83/26.Painful urination.jpg',
    'dysuria':                                         'assets/Image83/26.Painful urination.jpg',
    'frequent urination':                              'assets/Image83/26-1.Frequent urination.jpg',
    'polyuria':                                        'assets/Image83/26-1.Frequent urination.jpg',
    'arm pain':                                        'assets/Image83/27.Arm pain.jpg',
    'shoulder pain or injury':                         'assets/Image83/28.Shoulder pain or injury.jpg',
    'shoulder pain':                                   'assets/Image83/28.Shoulder pain or injury.jpg',
    'elbow pain or injury':                            'assets/Image83/29.Elbow pain or injury.jpg',
    'elbow pain':                                      'assets/Image83/29.Elbow pain or injury.jpg',
    'wrist pain or sprain':                            'assets/Image83/30.Wrist pain or sprain.jpg',
    'wrist pain':                                      'assets/Image83/30.Wrist pain or sprain.jpg',
    'hand or finger pain':                             'assets/Image83/31.Hand or finger pain.jpg',
    'hand pain':                                       'assets/Image83/31.Hand or finger pain.jpg',
    'finger pain':                                     'assets/Image83/31.Hand or finger pain.jpg',
    'arm or hand swelling':                            'assets/Image83/32.Arm or hand swelling.jpg',
    'arm swelling':                                    'assets/Image83/32.Arm or hand swelling.jpg',
    'suspected fracture (arm)':                        'assets/Image83/33.Suspected fracture (arm).jpg',
    'arm fracture':                                    'assets/Image83/33.Suspected fracture (arm).jpg',
    'arm numbness or tingling':                        'assets/Image83/34.Arm numbness or tingling.jpg',
    'arm numbness':                                    'assets/Image83/34.Arm numbness or tingling.jpg',
    'leg pain':                                        'assets/Image83/35.Leg pain.jpg',
    'knee pain or injury':                             'assets/Image83/36.Knee pain or injury.jpg',
    'knee pain':                                       'assets/Image83/36.Knee pain or injury.jpg',
    'ankle pain or sprain':                            'assets/Image83/37.Ankle pain or sprain.jpg',
    'ankle pain':                                      'assets/Image83/37.Ankle pain or sprain.jpg',
    'hip pain':                                        'assets/Image83/38.Hip pain.jpg',
    'foot or toe pain':                                'assets/Image83/39.Foot or toe pain.jpg',
    'foot pain':                                       'assets/Image83/39.Foot or toe pain.jpg',
    'leg or ankle swelling':                           'assets/Image83/40.Leg or ankle swelling.jpg',
    'leg swelling':                                    'assets/Image83/40.Leg or ankle swelling.jpg',
    'ankle swelling':                                  'assets/Image83/40.Leg or ankle swelling.jpg',
    'calf tightness or pain':                          'assets/Image83/41.Calf tightness or pain.jpg',
    'calf pain':                                       'assets/Image83/41.Calf tightness or pain.jpg',
    'suspected fracture (leg)':                        'assets/Image83/42.Suspected fracture (leg).jpg',
    'leg fracture':                                    'assets/Image83/42.Suspected fracture (leg).jpg',
    'leg numbness or tingling':                        'assets/Image83/43.Leg numbness or tingling.jpg',
    'leg numbness':                                    'assets/Image83/43.Leg numbness or tingling.jpg',
    'fever or high temperature':                       'assets/Image83/44.Fever or high temperature.jpg',
    'fever':                                           'assets/Image83/44.Fever or high temperature.jpg',
    'high temperature':                                'assets/Image83/44.Fever or high temperature.jpg',
    'pyrexia':                                         'assets/Image83/44.Fever or high temperature.jpg',
    'chills or shivering':                             'assets/Image83/45.Chills or shivering.jpg',
    'chills':                                          'assets/Image83/45.Chills or shivering.jpg',
    'shivering':                                       'assets/Image83/45.Chills or shivering.jpg',
    'rigors':                                          'assets/Image83/45.Chills or shivering.jpg',
    'body aches all over':                             'assets/Image83/46.Body aches all over.jpg',
    'body aches':                                      'assets/Image83/46.Body aches all over.jpg',
    'myalgia':                                         'assets/Image83/46.Body aches all over.jpg',
    'runny or blocked nose':                           'assets/Image83/47.Runny or blocked nose.jpg',
    'runny nose':                                      'assets/Image83/47.Runny or blocked nose.jpg',
    'blocked nose':                                    'assets/Image83/47.Runny or blocked nose.jpg',
    'nasal congestion':                                'assets/Image83/47.Runny or blocked nose.jpg',
    'sneezing':                                        'assets/Image83/48.Sneezing.jpg',
    'cough':                                           'assets/Image83/49.Cough.jpg',
    'coughing':                                        'assets/Image83/49.Cough.jpg',
    'dry cough':                                       'assets/Image83/49.Cough.jpg',
    'wet cough':                                       'assets/Image83/49.Cough.jpg',
    'coughing up blood':                               'assets/Image83/50.Coughing up blood.jpg',
    'haemoptysis':                                     'assets/Image83/50.Coughing up blood.jpg',
    'wheezing':                                        'assets/Image83/51.Wheezing.jpg',
    'shortness of breath':                             'assets/Image83/52.Shortness of breath.jpg',
    'dyspnoea':                                        'assets/Image83/52.Shortness of breath.jpg',
    'breathlessness':                                  'assets/Image83/52.Shortness of breath.jpg',
    'difficulty breathing':                            'assets/Image83/52.Shortness of breath.jpg',
    'itchy or watery eyes':                            'assets/Image83/53.Itchy or watery eyes.jpg',
    'watery eyes':                                     'assets/Image83/53.Itchy or watery eyes.jpg',
    'itchy eyes':                                      'assets/Image83/53.Itchy or watery eyes.jpg',
    'hives or skin welts':                             'assets/Image83/54.Hives or skin welts.jpg',
    'hives':                                           'assets/Image83/54.Hives or skin welts.jpg',
    'skin welts':                                      'assets/Image83/54.Hives or skin welts.jpg',
    'urticaria':                                       'assets/Image83/54.Hives or skin welts.jpg',
    'itchy skin':                                      'assets/Image83/55.Itchy skin.jpg',
    'pruritus':                                        'assets/Image83/55.Itchy skin.jpg',
    'skin rash':                                       'assets/Image83/55-1.Skin rash.jpg',
    'rash':                                            'assets/Image83/55-1.Skin rash.jpg',
    'dry or peeling skin':                             'assets/Image83/56.Dry or peeling skin.jpg',
    'dry skin':                                        'assets/Image83/56.Dry or peeling skin.jpg',
    'nausea':                                          'assets/Image83/57.Nausea.jpg',
    'vomiting':                                        'assets/Image83/58.Vomiting.jpg',
    'diarrhoea':                                       'assets/Image83/59.Diarrhoea.jpg',
    'diarrhea':                                        'assets/Image83/59.Diarrhoea.jpg',
    'loss of appetite':                                'assets/Image83/60.Loss of appetite.jpg',
    'anorexia':                                        'assets/Image83/60.Loss of appetite.jpg',
    'chest tightness or pressure':                     'assets/Image83/61.Chest tightness or pressure.jpg',
    'chest tightness':                                 'assets/Image83/61.Chest tightness or pressure.jpg',
    'chest pressure':                                  'assets/Image83/61.Chest tightness or pressure.jpg',
    'racing heart or palpitations':                    'assets/Image83/62.Racing heart or palpitations.jpg',
    'palpitations':                                    'assets/Image83/62.Racing heart or palpitations.jpg',
    'heart palpitations':                              'assets/Image83/62.Racing heart or palpitations.jpg',
    'racing heart':                                    'assets/Image83/62.Racing heart or palpitations.jpg',
    'increased heart rate':                            'assets/Image83/62.Racing heart or palpitations.jpg',
    'tachycardia':                                     'assets/Image83/62.Racing heart or palpitations.jpg',
    'fainting or near-fainting':                       'assets/Image83/63.Fainting or near-fainting.jpg',
    'fainting':                                        'assets/Image83/63.Fainting or near-fainting.jpg',
    'syncope':                                         'assets/Image83/63.Fainting or near-fainting.jpg',
    'unexpected sweating':                             'assets/Image83/64.Unexpected sweating.jpg',
    'sweating':                                        'assets/Image83/64.Unexpected sweating.jpg',
    'diaphoresis':                                     'assets/Image83/64.Unexpected sweating.jpg',
    'trembling or shaking':                            'assets/Image83/65.Trembling or shaking.jpg',
    'trembling':                                       'assets/Image83/65.Trembling or shaking.jpg',
    'shaking':                                         'assets/Image83/65.Trembling or shaking.jpg',
    'tremors':                                         'assets/Image83/65.Trembling or shaking.jpg',
    'sudden intense fear (panic attack)':              'assets/Image83/66.Sudden intense fear (panic attack).jpg',
    'panic attack':                                    'assets/Image83/66.Sudden intense fear (panic attack).jpg',
    'rapid shallow breathing':                         'assets/Image83/67.Rapid shallow breathing.jpg',
    'hyperventilation':                                'assets/Image83/67.Rapid shallow breathing.jpg',
    'insomnia or trouble sleeping':                    'assets/Image83/68.Insomnia or trouble sleeping.jpg',
    'insomnia':                                        'assets/Image83/68.Insomnia or trouble sleeping.jpg',
    'trouble sleeping':                                'assets/Image83/68.Insomnia or trouble sleeping.jpg',
    'excessive daytime sleepiness':                    'assets/Image83/69.Excessive daytime sleepiness.jpg',
    'sleepiness':                                      'assets/Image83/69.Excessive daytime sleepiness.jpg',
    'loud snoring or stopping breathing in sleep':     'assets/Image83/70.Loud snoring or stopping breathing in sleep.jpg',
    'snoring':                                         'assets/Image83/70.Loud snoring or stopping breathing in sleep.jpg',
    'fatigue or tiredness':                            'assets/Image83/71.Fatigue or tiredness.jpg',
    'fatigue':                                         'assets/Image83/71.Fatigue or tiredness.jpg',
    'tiredness':                                       'assets/Image83/71.Fatigue or tiredness.jpg',
    'general weakness':                                'assets/Image83/72.General weakness.jpg',
    'weakness':                                        'assets/Image83/72.General weakness.jpg',
    'dizziness or lightheadedness':                    'assets/Image83/73.Dizziness or lightheadedness.jpg',
    'dizziness':                                       'assets/Image83/73.Dizziness or lightheadedness.jpg',
    'lightheadedness':                                 'assets/Image83/73.Dizziness or lightheadedness.jpg',
    'vertigo':                                         'assets/Image83/73.Dizziness or lightheadedness.jpg',
    'confusion or disorientation':                     'assets/Image83/74.Confusion or disorientation.jpg',
    'confusion':                                       'assets/Image83/74.Confusion or disorientation.jpg',
    'disorientation':                                  'assets/Image83/74.Confusion or disorientation.jpg',
    'numbness or tingling (body-wide)':                'assets/Image83/75.Numbness or tingling (body-wide).jpg',
    'numbness or tingling':                            'assets/Image83/75.Numbness or tingling (body-wide).jpg',
    'tingling':                                        'assets/Image83/75.Numbness or tingling (body-wide).jpg',
    'numbness':                                        'assets/Image83/75.Numbness or tingling (body-wide).jpg',
    'involuntary or abnormal movements':               'assets/Image83/76.Involuntary or abnormal movements.jpg',
    'abnormal movements':                              'assets/Image83/76.Involuntary or abnormal movements.jpg',
    'difficulty with coordination or walking':         'assets/Image83/77.Difficulty with coordination or walking.jpg',
    'difficulty walking':                              'assets/Image83/77.Difficulty with coordination or walking.jpg',
    'poor coordination':                               'assets/Image83/77.Difficulty with coordination or walking.jpg',
    'seizures':                                        'assets/Image83/78.Seizures.jpg',
    'seizure':                                         'assets/Image83/78.Seizures.jpg',
    'convulsions':                                     'assets/Image83/78.Seizures.jpg',
    'excessive thirst':                                'assets/Image83/79.Excessive thirst.jpg',
    'polydipsia':                                      'assets/Image83/79.Excessive thirst.jpg',
    'shakiness or trembling when hungry':              'assets/Image83/80.Shakiness or trembling when hungry.jpg',
    'shakiness when hungry':                           'assets/Image83/80.Shakiness or trembling when hungry.jpg',
    'feeling faint after skipping meals':              'assets/Image83/81.Feeling faint after skipping meals.jpg',
  };

  /// Returns an asset path for [symptom], or null if no match.
  /// Four-level fallback: exact → query-contains-key → key-contains-query → word overlap.
  static String? lookup(String symptom) {
    final String q = symptom.toLowerCase().trim();
    if (q.isEmpty) return null;
    final String? exact = _map[q];
    if (exact != null) return exact;
    for (final MapEntry<String, String> e in _map.entries) {
      if (q.contains(e.key)) return e.value;
    }
    for (final MapEntry<String, String> e in _map.entries) {
      if (e.key.contains(q)) return e.value;
    }
    final List<String> qWords =
        q.split(' ').where((String w) => w.length > 3).toList();
    if (qWords.isNotEmpty) {
      String? best;
      int     bestScore = 0;
      for (final MapEntry<String, String> e in _map.entries) {
        final int score =
            qWords.where((String w) => e.key.contains(w)).length;
        if (score > bestScore) {
          bestScore = score;
          best = e.value;
        }
      }
      if (bestScore >= 1) return best;
    }
    return null;
  }
}

// ── Read-aloud button ─────────────────────────────────────────────────────
//
// Circular speaker icon that plays/stops TTS for a given text snippet.
// Manages its own playing state and shows a pulsing animation while speaking.

class _TtsButton extends StatefulWidget {
  const _TtsButton({required this.text, this.size = 32.0});

  /// Text to be read aloud.
  final String text;

  /// Diameter of the circular button.
  final double size;

  @override
  State<_TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<_TtsButton>
    with SingleTickerProviderStateMixin {
  bool _playing = false;
  late final AnimationController _pulse;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _toggle(BuildContext context) {
    if (_playing) {
      KokoroTtsService.stop();
      if (mounted) setState(() => _playing = false);
    } else {
      final AppLanguage lang = SACAStateScope.of(context).selectedLanguage;
      setState(() => _playing = true);
      KokoroTtsService.speak(widget.text, language: lang).whenComplete(() {
        if (mounted) setState(() => _playing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs = SACAColorScheme.of(context);

    return GestureDetector(
      onTap: () => _toggle(context),
      child: Container(
        width:  widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _playing
              ? SACAColors.clinicalGreen.withValues(alpha: 0.13)
              : cs.inputFill,
          shape: BoxShape.circle,
          border: Border.all(
            color: _playing
                ? SACAColors.clinicalGreen.withValues(alpha: 0.45)
                : cs.subtleBorder,
            width: 1.2,
          ),
        ),
        child: Center(
          child: _playing
              ? AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, _) => Icon(
                    Icons.volume_up_rounded,
                    size:  widget.size * 0.46,
                    color: SACAColors.clinicalGreen
                        .withValues(alpha: _pulseAnim.value),
                  ),
                )
              : Icon(
                  Icons.volume_up_outlined,
                  size:  widget.size * 0.46,
                  color: cs.secondaryText,
                ),
        ),
      ),
    );
  }
}

// ── Small badge (language / info) ─────────────────────────────────────────

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    required this.color,
    required this.borderColor,
  });

  final String label;
  final Color  color;
  final Color  borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      color,
          fontWeight: FontWeight.w600,
          fontSize:   11,
        ),
      ),
    );
  }
}

// ── Confidence badge ──────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({
    required this.confidence,
    required this.accentColor,
  });

  final double confidence;
  final Color  accentColor;

  @override
  Widget build(BuildContext context) {
    final int pct = (confidence * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color:        accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.verified_rounded, size: 11, color: accentColor),
          const SizedBox(width: 4),
          Text(
            '$pct% confidence',
            style: TextStyle(
              color:      accentColor,
              fontWeight: FontWeight.w700,
              fontSize:   11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Assessment details expansion tile ────────────────────────────────────

class _AssessmentDetailsTile extends StatelessWidget {
  const _AssessmentDetailsTile({
    required this.transcript,
    this.rawTranscript,
    this.painScore = 0,
    this.symptoms  = const <String>[],
  });

  final String       transcript;
  final String?      rawTranscript;
  /// 1–10 pain score from the session (0 = not recorded).
  final int          painScore;
  /// API-identified symptoms used to show visual image cards.
  final List<String> symptoms;

  Widget _sectionTitle(SACAColorScheme cs, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color:       cs.secondaryText,
            fontWeight:  FontWeight.w700,
            fontSize:    10,
            letterSpacing: 0.8,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs    = SACAColorScheme.of(context);
    final bool            isDark = Theme.of(context).brightness == Brightness.dark;

    // Choose the best transcript to display as the patient input.
    // rawTranscript = what the voice model heard verbatim (most authentic).
    // transcript    = cleaned/enriched version built from session fields.
    final String displayTranscript = (rawTranscript != null &&
            rawTranscript!.trim().isNotEmpty)
        ? rawTranscript!.trim()
        : transcript.trim();
    final bool hasTranscript = displayTranscript.isNotEmpty;

    // Show the enriched session narrative if it differs from the display.
    final String? enrichedText =
        (rawTranscript != null && rawTranscript!.trim().isNotEmpty)
            ? transcript.trim()
            : null;
    final bool hasEnriched =
        enrichedText != null && enrichedText.isNotEmpty;

    // Resolve which symptom images are available.
    final List<MapEntry<String, String?>> symImages = symptoms
        .map((String s) => MapEntry<String, String?>(s, _SymptomImages.lookup(s)))
        .toList();

    return Container(
      decoration: BoxDecoration(
        // colour lives on ExpansionTile (backgroundColor / collapsedBackgroundColor)
        // — if we also set it here the ListTile paints on the wrong layer.
        borderRadius: BorderRadius.circular(22),
        border:       Border.all(color: cs.subtleBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:      Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: isDark ? 20 : 14,
            offset:     const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor:          cs.cardBackground,
          collapsedBackgroundColor: cs.cardBackground,
          tilePadding:     const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          collapsedIconColor: cs.secondaryText,
          iconColor:          SACAColors.clinicalGreen,
          title: Row(
            children: <Widget>[
              Icon(
                Icons.fact_check_outlined,
                size:  18,
                color: SACAColors.clinicalGreen,
              ),
              const SizedBox(width: 10),
              Text(
                SACAStrings.tr(
                  context: context,
                  english:  'View Assessment Details',
                  warlpiri: 'Yimi Jaru Karlipa',
                ),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                  color:      cs.charcoal,
                ),
              ),
            ],
          ),
          children: <Widget>[

            // ── Pain intensity meter ───────────────────────────────────────
            if (painScore > 0) ...<Widget>[
              _sectionTitle(cs, SACAStrings.tr(
                context: context,
                english:  'Pain intensity',
                warlpiri: 'Warlu nyinami',
              )),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                decoration: BoxDecoration(
                  color:        cs.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: cs.subtleBorder),
                ),
                child: _PainMeterBar(score: painScore),
              ),
              const SizedBox(height: 18),
            ],

            // ── Symptom image cards ────────────────────────────────────────
            if (symImages.isNotEmpty) ...<Widget>[
              _SymptomImageRow(symImages: symImages),
              const SizedBox(height: 18),
            ],

            // ── Patient input transcript ───────────────────────────────────
            _sectionTitle(cs, SACAStrings.tr(
              context: context,
              english:  'Patient input',
              warlpiri: 'Yimi ngarrka-jarri',
            )),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        cs.inputFill,
                borderRadius: BorderRadius.circular(14),
                border:       Border.all(color: cs.subtleBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:        SACAColors.clinicalGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      size:  14,
                      color: SACAColors.clinicalGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasTranscript ? displayTranscript : '—',
                      style: TextStyle(
                        color:      cs.charcoal,
                        fontSize:   13.5,
                        height:     1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Enriched session narrative (if voice input used) ──────────
            if (hasEnriched) ...<Widget>[
              const SizedBox(height: 14),
              _sectionTitle(cs, SACAStrings.tr(
                context: context,
                english:  'Clinical session summary',
                warlpiri: 'Yimi jaru',
              )),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        cs.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: cs.subtleBorder),
                ),
                child: Text(
                  enrichedText,
                  style: TextStyle(
                    color:    cs.secondaryText,
                    fontSize: 13,
                    height:   1.45,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

// ── Symptom image row with label toggle ──────────────────────────────────
//
// Renders a horizontal scrollable row of patient symptom image cards.
// A pill button in the header lets the user show/hide the English labels
// under each image (the image itself is always visible).

class _SymptomImageRow extends StatefulWidget {
  const _SymptomImageRow({required this.symImages});

  final List<MapEntry<String, String?>> symImages;

  @override
  State<_SymptomImageRow> createState() => _SymptomImageRowState();
}

class _SymptomImageRowState extends State<_SymptomImageRow> {
  bool _showLabels = true;

  Widget _symFallback(SACAColorScheme cs) => Container(
        width:  110,
        height: 110,
        decoration: BoxDecoration(
          color:        cs.inputFill,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: cs.subtleBorder),
        ),
        child: Center(
          child: Icon(
            Icons.medical_services_outlined,
            size:  36,
            color: cs.secondaryText.withValues(alpha: 0.50),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs = SACAColorScheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[

        // ── Header row: title + toggle pill ───────────────────────────────
        Row(
          children: <Widget>[
            Text(
              SACAStrings.tr(
                context: context,
                english:  'PATIENT SYMPTOMS',
                warlpiri: 'WARLU-KARI',
              ),
              style: TextStyle(
                color:        cs.secondaryText,
                fontWeight:   FontWeight.w700,
                fontSize:     10,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _showLabels = !_showLabels),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        cs.inputFill,
                  borderRadius: BorderRadius.circular(99),
                  border:       Border.all(color: cs.subtleBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      _showLabels
                          ? Icons.label_off_outlined
                          : Icons.label_outline_rounded,
                      size:  11,
                      color: cs.secondaryText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _showLabels
                          ? SACAStrings.tr(
                              context: context,
                              english:  'Hide labels',
                              warlpiri: 'Yimi wantija',
                            )
                          : SACAStrings.tr(
                              context: context,
                              english:  'Show labels',
                              warlpiri: 'Yimi nyinami',
                            ),
                      style: TextStyle(
                        color:      cs.secondaryText,
                        fontSize:   10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Scrollable image cards ─────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.symImages.map((MapEntry<String, String?> e) {
              final String  label   = e.key;
              final String? imgPath = e.value;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 110,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Image is ALWAYS visible
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imgPath != null
                            ? Image.asset(
                                imgPath,
                                width:  110,
                                height: 110,
                                fit:    BoxFit.cover,
                                errorBuilder: (_, _, _) => _symFallback(cs),
                              )
                            : _symFallback(cs),
                      ),
                      // Label fades + collapses when hidden
                      AnimatedCrossFade(
                        firstChild: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            textAlign:  TextAlign.center,
                            maxLines:   2,
                            overflow:   TextOverflow.ellipsis,
                            style: TextStyle(
                              color:      cs.charcoal,
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              height:     1.3,
                            ),
                          ),
                        ),
                        secondChild: const SizedBox(width: 110, height: 0),
                        crossFadeState: _showLabels
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 220),
                        sizeCurve: Curves.easeOutCubic,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Action plan box ───────────────────────────────────────────────────────

class _ActionPlanBox extends StatelessWidget {
  const _ActionPlanBox({
    required this.triageLevel,
    required this.recommendation,
  });

  final String triageLevel;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs   = SACAColorScheme.of(context);
    final bool            isDark = Theme.of(context).brightness == Brightness.dark;
    final Color           tone  = TriagePresentation.colorForLevel(triageLevel);
    final IconData?       sevIcon = TriagePresentation.severityIcon(triageLevel);
    final String resolvedRec = recommendation.trim().isNotEmpty
        ? recommendation
        : TriagePresentation.recommendationForLevel(triageLevel);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color:        cs.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border:       Border.all(color: cs.subtleBorder),
          boxShadow: <BoxShadow>[
            if (isDark)
              BoxShadow(
                color:      tone.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: -4,
                offset:     const Offset(0, 8),
              ),
            BoxShadow(
              color:      Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: isDark ? 20 : 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize:       MainAxisSize.min,
          children: <Widget>[
            // Accent top bar with glow
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[tone, tone.withValues(alpha: 0.50)],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color:      tone.withValues(alpha: 0.50),
                    blurRadius: 8,
                    spreadRadius: -1,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (sevIcon != null) ...<Widget>[
                        Icon(sevIcon, color: tone, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        SACAStrings.tr(
                          context: context,
                          english: 'Recommended actions',
                          warlpiri: 'Yimi nyampuju kiji',
                        ),
                        style: TextStyle(
                          color:       tone,
                          fontSize:    16,
                          fontWeight:  FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    resolvedRec,
                    style: TextStyle(
                      color:    cs.charcoal,
                      fontSize: 14,
                      height:   1.50,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Escalation banner ─────────────────────────────────────────────────────

class _EscalationBanner extends StatelessWidget {
  const _EscalationBanner();

  @override
  Widget build(BuildContext context) {
    const Color red = Color(0xFFFF453A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: red.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.emergency_rounded, color: red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              SACAStrings.tr(
                context: context,
                english:  'ESCALATION TRIGGERED — Immediate clinical review required.',
                warlpiri: 'KARLIPA WURNA — Clinical yimi manu, yirrarni.',
              ),
              style: const TextStyle(
                color:       red,
                fontWeight:  FontWeight.w800,
                fontSize:    13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result action bar ─────────────────────────────────────────────────────

class _ResultActionBar extends StatelessWidget {
  const _ResultActionBar({
    required this.triageColor,
    required this.onAlertClinic,
    required this.onReturnHome,
  });

  final Color        triageColor;
  final VoidCallback onAlertClinic;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    final SACAColorScheme cs    = SACAColorScheme.of(context);
    final bool            isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Fade-out gradient
          IgnorePointer(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: <Color>[
                    cs.pageBackground.withValues(alpha: 0),
                    cs.pageBackground,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: <Widget>[
                // New assessment (outline)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReturnHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.secondaryText,
                      side: BorderSide(color: cs.subtleBorder, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      SACAStrings.tr(
                        context: context,
                        english:  'NEW ASSESSMENT',
                        warlpiri: 'YIMI NYURRU',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Alert clinic (filled, glowing)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color:      triageColor.withValues(alpha: isDark ? 0.35 : 0.22),
                          blurRadius: 20,
                          spreadRadius: -3,
                          offset:     const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: triageColor,
                        foregroundColor: Colors.white,
                        elevation:       0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: onAlertClinic,
                      child: Text(
                        SACAStrings.tr(
                          context: context,
                          english:  'ALERT CLINIC',
                          warlpiri: 'CLINIC-KU WANGKA',
                        ),
                        style: const TextStyle(
                          fontWeight:  FontWeight.w800,
                          fontSize:    13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
