part of '../main.dart';

// ── Triage-level presentation ─────────────────────────────────────────────
class TriagePresentation {
  TriagePresentation._();

  static Color colorForLevel(String level) {
    final String n = level.toLowerCase();
    if (n.contains('severe') || n.contains('high') || n.contains('critical')) {
      return SACAColors.triageCritical;
    }
    if (n.contains('moderate') || n.contains('medium')) {
      return SACAColors.triageModerate;
    }
    return SACAColors.triageSafe;
  }

  static String recommendationForLevel(String level) {
    final String n = level.toLowerCase();
    if (n.contains('severe') || n.contains('high') || n.contains('critical')) {
      return 'Evacuate immediately. Alert the nearest medical officer. '
          'Monitor vitals every 5 minutes.';
    }
    if (n.contains('moderate') || n.contains('medium')) {
      return 'Schedule clinic visit within 4 hours. Keep patient hydrated. '
          'Monitor for worsening symptoms.';
    }
    return 'Routine check-up recommended. Provide home care instructions. '
        'Follow up if symptoms persist.';
  }

  /// Icon for high / moderate triage only; null for safe/routine.
  static IconData? severityIcon(String level) {
    final String n = level.toLowerCase();
    if (n.contains('severe') || n.contains('high') || n.contains('critical')) {
      return Icons.emergency_rounded;
    }
    if (n.contains('moderate') || n.contains('medium')) {
      return Icons.warning_amber_rounded;
    }
    return null;
  }

  /// 0–1 ring fill for the triage arc ring (higher = more severe).
  /// Fallback when no confidence score is available.
  static double ringFill(String level) {
    final String n = level.toLowerCase();
    if (n.contains('severe') || n.contains('high') || n.contains('critical')) {
      return 0.92;
    }
    if (n.contains('moderate') || n.contains('medium')) {
      return 0.58;
    }
    return 0.24;
  }

  /// Dynamic ring fill driven by the ML model's confidence score.
  ///
  /// Each severity band occupies a fixed range of the ring so that Critical
  /// always fills more arc than Moderate, which always fills more than Mild.
  /// Within each band the confidence value (0–1) scales the fill, making every
  /// assessment visually unique even for the same disease.
  ///
  /// Band ranges (chosen so adjacent bands never overlap):
  ///   Critical  → 0.72 – 0.99
  ///   Moderate  → 0.42 – 0.71
  ///   Mild/Safe → 0.12 – 0.41
  ///
  /// Falls back to the centre of each band when confidence is 0 (offline /
  /// fallback mode).
  static double ringFillDynamic(String level, double confidence) {
    // Clamp to a valid probability; use band midpoint when unavailable.
    final double c =
        (confidence > 0.0 && confidence <= 1.0) ? confidence : 0.5;
    final String n = level.toLowerCase();
    if (n.contains('severe') || n.contains('high') || n.contains('critical')) {
      return 0.72 + c * 0.27; // 0.72 – 0.99
    }
    if (n.contains('moderate') || n.contains('medium')) {
      return 0.42 + c * 0.29; // 0.42 – 0.71
    }
    return 0.12 + c * 0.29; // 0.12 – 0.41
  }
}

// ── WHOOP-inspired colour palette ─────────────────────────────────────────
class SACAColors {
  // ── Triage severity (vibrant — work on both light and dark surfaces) ──────
  static const Color triageCritical = Color(0xFFFF453A);  // vivid red
  static const Color triageModerate = Color(0xFFFF9F0A);  // vivid amber
  static const Color triageSafe     = Color(0xFF30D158);  // vivid green

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color clinicalGreen  = Color(0xFF30D158);  // primary action
  static const Color warlpiriOrange = Color(0xFFFF7D3F);  // warm cultural tone

  // ── Legacy aliases (kept for compatibility across all part files) ──────────
  static const Color deepClinicalGreen = clinicalGreen;
  static const Color earthClay        = warlpiriOrange;
  static const Color warningRedBrown  = triageCritical;
  static const Color triageCrimson    = triageCritical;
  static const Color triageMarigold   = triageModerate;
  static const Color triageSafeGreen  = triageSafe;

  // ── Light-mode static fallbacks (prefer SACAColorScheme.of in widgets) ─────
  static const Color pageBackground = Color(0xFFF2F2F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color charcoal       = Color(0xFF1C1C1E);
  static const Color secondaryText  = Color(0xFF6C6C70);
  static const Color subtleBorder   = Color(0xFFE5E5EA);
}

// ── Adaptive colour scheme (dark / light) ────────────────────────────────
class SACAColorScheme extends ThemeExtension<SACAColorScheme> {
  const SACAColorScheme({
    required this.pageBackground,
    required this.cardBackground,
    required this.charcoal,
    required this.secondaryText,
    required this.subtleBorder,
    required this.inputFill,
  });

  final Color pageBackground;
  final Color cardBackground;
  final Color charcoal;
  final Color secondaryText;
  final Color subtleBorder;
  final Color inputFill;

  // ── Light palette ─────────────────────────────────────────────────────────
  static const SACAColorScheme light = SACAColorScheme(
    pageBackground: Color(0xFFF2F2F7),   // iOS system background
    cardBackground: Color(0xFFFFFFFF),
    charcoal:       Color(0xFF1C1C1E),
    secondaryText:  Color(0xFF6C6C70),
    subtleBorder:   Color(0xFFE5E5EA),
    inputFill:      Color(0xFFF2F2F7),
  );

  // ── Dark palette (WHOOP-style near-black) ─────────────────────────────────
  static const SACAColorScheme dark = SACAColorScheme(
    pageBackground: Color(0xFF0D0D0F),   // near-black base
    cardBackground: Color(0xFF1C1C1E),   // elevated dark surface
    charcoal:       Color(0xFFF0F0F0),   // near-white text
    secondaryText:  Color(0xFF8E8E93),   // muted secondary
    subtleBorder:   Color(0xFF38383A),   // dark separator
    inputFill:      Color(0xFF2C2C2E),   // dark input surface
  );

  static SACAColorScheme of(BuildContext context) =>
      Theme.of(context).extension<SACAColorScheme>() ?? light;

  @override
  SACAColorScheme copyWith({
    Color? pageBackground,
    Color? cardBackground,
    Color? charcoal,
    Color? secondaryText,
    Color? subtleBorder,
    Color? inputFill,
  }) =>
      SACAColorScheme(
        pageBackground: pageBackground ?? this.pageBackground,
        cardBackground: cardBackground ?? this.cardBackground,
        charcoal:       charcoal       ?? this.charcoal,
        secondaryText:  secondaryText  ?? this.secondaryText,
        subtleBorder:   subtleBorder   ?? this.subtleBorder,
        inputFill:      inputFill      ?? this.inputFill,
      );

  @override
  SACAColorScheme lerp(covariant SACAColorScheme? other, double t) {
    if (other == null) return this;
    return SACAColorScheme(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      charcoal:       Color.lerp(charcoal,       other.charcoal,       t)!,
      secondaryText:  Color.lerp(secondaryText,  other.secondaryText,  t)!,
      subtleBorder:   Color.lerp(subtleBorder,   other.subtleBorder,   t)!,
      inputFill:      Color.lerp(inputFill,       other.inputFill,      t)!,
    );
  }

  // ── ThemeData factory ─────────────────────────────────────────────────────
  static ThemeData buildTheme({required bool isDark}) {
    final SACAColorScheme cs = isDark ? dark : light;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: cs.pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SACAColors.clinicalGreen,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        surface:   cs.cardBackground,
        onSurface: cs.charcoal,
      ),
      cardColor:    cs.cardBackground,
      dividerColor: cs.subtleBorder,
      appBarTheme: AppBarTheme(
        backgroundColor:         cs.pageBackground,
        foregroundColor:         cs.charcoal,
        elevation:               0,
        scrolledUnderElevation:  0,
        titleTextStyle: TextStyle(
          color:      cs.charcoal,
          fontSize:   17,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: cs.charcoal),
      ),
      extensions: <ThemeExtension<dynamic>>[cs],
    );
  }
}

// ── Localisation helper ───────────────────────────────────────────────────
class SACAStrings {
  static String tr({
    required BuildContext context,
    required String english,
    required String warlpiri,
  }) {
    final AppLanguage language = SACAStateScope.of(context).selectedLanguage;
    return language == AppLanguage.english ? english : warlpiri;
  }
}

/// Typography scale for workspace / triage questionnaire.
class SACATriageTypography {
  SACATriageTypography._();

  static const double pageHeadline  = 24;
  static const double pageSubtitle  = 13;
  static const double cardQuestion  = 19;
  static const double cardHint      = 12;
  static const double sectionLead   = 17;
  static const double sectionSub    = 12;
  static const double voiceCta      = 20;
  static const double voiceQuestion = 18;
  static const double gridLabel     = 15;
  static const double painPrompt    = 13;
}
