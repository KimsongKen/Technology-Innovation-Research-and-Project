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
  });

  String chiefComplaint;
  String onset;
  bool isWorsening;
  String medications;
  String allergies;
  List<String> painLocation;
}

class TriageApiResult {
  TriageApiResult({
    required this.triageLevel,
    required this.topCondition,
    required this.transcriptFinal,
    required this.recommendation,
  });

  factory TriageApiResult.fromJson(Map<String, dynamic> json) {
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
    );
  }

  final String triageLevel;
  final String topCondition;
  final String transcriptFinal;
  final String recommendation;
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
