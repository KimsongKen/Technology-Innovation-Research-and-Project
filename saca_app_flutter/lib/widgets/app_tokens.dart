part of '../main.dart';

class SACAColors {
  static const Color warlpiriOrange = Color(0xFFD17E2F);
  static const Color deepClinicalGreen = Color(0xFF1A5241);
  static const Color warningRedBrown = Color(0xFF9B4433);
  static const Color earthClay = Color(0xFFB15D2C);
  static const Color pageBackground = Color(0xFFFAF8F5);
  static const Color cardBackground = Colors.white;
  static const Color charcoal = Color(0xFF1F1F1F);
  static const Color secondaryText = Color(0xFF5E5A56);
  static const Color subtleBorder = Color(0xFFE8E2D8);
  static const Color triageCrimson = Color(0xFFB24A4A);
  static const Color triageMarigold = Color(0xFFC6922B);
  static const Color triageSafeGreen = Color(0xFF3E8A63);
}

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

/// Typography scale for workspace / triage questionnaire and related screens.
/// Smaller page chrome so in-card questions and inputs read as the focal point.
class SACATriageTypography {
  SACATriageTypography._();

  /// Title repeated under app bar (workspace, pre-result notes).
  static const double pageHeadline = 24;

  static const double pageSubtitle = 13;

  /// Bold question line inside the white triage card.
  static const double cardQuestion = 19;

  static const double cardHint = 12;

  /// Lead line outside the card (body map, pain pre-result headline).
  static const double sectionLead = 17;

  static const double sectionSub = 12;

  /// Voice step: "Tap to Speak" accent line.
  static const double voiceCta = 20;

  /// Voice step: spoken question line.
  static const double voiceQuestion = 18;

  static const double gridLabel = 15;

  static const double painPrompt = 13;
}
