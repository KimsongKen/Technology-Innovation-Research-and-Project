import 'package:flutter/material.dart';

import '../core/language/language_keys.dart';
import '../core/language/language_service.dart';
import '../core/theme/saca_colors.dart';
import '../models/triage_session.dart';
import '../services/speech_output_service.dart';
import '../state/saca_state_scope.dart';
import '../widgets/base_card.dart';
import '../widgets/speak_button.dart';

class ResultSummaryPage extends StatelessWidget {
  const ResultSummaryPage({
    super.key,
    required this.session,
    required this.speechOutputService,
  });

  final TriageSession session;
  final SpeechOutputService speechOutputService;

  @override
  Widget build(BuildContext context) {
    final language = SACAStateScope.of(context).selectedLanguage;
    final String painLocationText = session.painLocation.isEmpty
        ? LanguageService.get(language, L.noneSelected)
        : session.painLocation.join(', ');
    final String summaryText = <String>[
      '${LanguageService.get(language, L.chiefComplaint)}: ${_valueOrDash(session.chiefComplaint)}',
      '${LanguageService.get(language, L.onset)}: ${_valueOrDash(session.onset)}',
      '${LanguageService.get(language, L.worsening)}: ${session.isWorsening ? LanguageService.get(language, L.yes) : LanguageService.get(language, L.no)}',
      '${LanguageService.get(language, L.rapidlyWorsening)}: ${session.isRapidlyWorsening ? LanguageService.get(language, L.yes) : LanguageService.get(language, L.no)}',
      '${LanguageService.get(language, L.medications)}: ${_valueOrDash(session.medications)}',
      '${LanguageService.get(language, L.allergies)}: ${_valueOrDash(session.allergies)}',
      '${LanguageService.get(language, L.painLocation)}: $painLocationText',
    ].join('. ');

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.get(language, L.resultSummary)),
        actions: <Widget>[
          SpeakButton(
            text: summaryText,
            speechOutputService: speechOutputService,
            tooltip: LanguageService.get(language, L.readAloud),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BaseCard(
                active: false,
                accentColor: SACAColors.deepClinicalGreen,
                child: ListView(
                  children: <Widget>[
                    _summaryRow(
                      LanguageService.get(language, L.chiefComplaint),
                      session.chiefComplaint,
                    ),
                    _summaryRow(
                      LanguageService.get(language, L.onset),
                      session.onset,
                    ),
                    _summaryRow(
                      LanguageService.get(language, L.worsening),
                      session.isWorsening
                          ? LanguageService.get(language, L.yes)
                          : LanguageService.get(language, L.no),
                    ),
                    _summaryRow(
                      LanguageService.get(language, L.rapidlyWorsening),
                      session.isRapidlyWorsening
                          ? LanguageService.get(language, L.yes)
                          : LanguageService.get(language, L.no),
                    ),
                    _summaryRow(
                      LanguageService.get(language, L.medications),
                      session.medications,
                    ),
                    _summaryRow(
                      LanguageService.get(language, L.allergies),
                      session.allergies,
                    ),
                    _summaryRow(
                      LanguageService.get(language, L.painLocation),
                      painLocationText,
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: SACAColors.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _valueOrDash(value),
            style: const TextStyle(
              color: SACAColors.charcoal,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _valueOrDash(String value) {
    return value.isEmpty ? '-' : value;
  }
}
