part of '../main.dart';

enum AppLanguage { warlpiri, english }

enum ReportMode { voice, selection, text }

class TriageSession {
  TriageSession({
    required this.chiefComplaint,
    required this.onset,
    required this.isWorsening,
    required this.medications,
    required this.allergies,
    required this.painLocation,
    this.painScore = 5,
    this.additionalConcerns = '',
  });

  String chiefComplaint;
  String onset;
  bool isWorsening;
  String medications;
  String allergies;
  List<String> painLocation;

  /// Numeric pain rating 1 (mild) – 10 (unbearable).
  int painScore;
  String additionalConcerns;
}

class TriageApiResult {
  TriageApiResult({
    required this.triageLevel,
    required this.topCondition,
    required this.transcriptFinal,
    required this.recommendation,
    this.confidence = 0.0,
    this.top3Symptoms = const <String>[],
    this.escalationTriggered = false,
    this.languageCode = 'en',
    this.warlpiriRawTranscript,
  });

  factory TriageApiResult.fromJson(Map<String, dynamic> json) {
    final dynamic top3Raw = json['top_3_symptoms'];
    final List<String> top3 = top3Raw is List
        ? top3Raw.map((dynamic e) => e.toString()).toList()
        : <String>[];
    final String? rawWp = json['warlpiri_raw_transcript']?.toString().trim();
    return TriageApiResult(
      triageLevel: (json['triage_level'] ?? 'Moderate').toString(),
      topCondition: (json['top_condition'] ?? json['predicted_disease'] ?? '-')
          .toString(),
      transcriptFinal:
          (json['transcript_final'] ??
                  json['transcript_final_text'] ??
                  json['transcript'] ??
                  '')
              .toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
      confidence: ((json['confidence'] ?? json['confidence_score'] ?? 0) as num).toDouble(),
      top3Symptoms: top3,
      escalationTriggered: (json['escalation_triggered'] ?? false) == true,
      languageCode: (json['language'] ?? 'en').toString(),
      warlpiriRawTranscript: rawWp != null && rawWp.isNotEmpty ? rawWp : null,
    );
  }

  final String triageLevel;
  final String topCondition;
  final String transcriptFinal;
  final String recommendation;
  final double confidence;
  final List<String> top3Symptoms;
  final bool escalationTriggered;
  final String languageCode;
  final String? warlpiriRawTranscript;
}

class WorkspaceConfig {
  const WorkspaceConfig({
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
}

class ReportModeCardData {
  const ReportModeCardData({
    required this.mode,
    required this.heroTag,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    this.recommended = false,
  });

  final ReportMode mode;
  final String heroTag;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final bool recommended;
}
