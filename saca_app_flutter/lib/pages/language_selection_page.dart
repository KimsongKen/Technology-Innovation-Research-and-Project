import 'package:flutter/material.dart';

import '../core/enums/app_language.dart';
import '../core/language/language_keys.dart';
import '../core/language/language_service.dart';
import '../core/theme/saca_colors.dart';
import '../services/speech_input_service.dart';
import '../services/speech_output_service.dart';
import '../services/triage_service.dart';
import '../state/saca_state_scope.dart';
import '../widgets/language_card.dart';
import 'reporting_method_page.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({
    super.key,
    required this.triageService,
    required this.speechInputService,
    required this.speechOutputService,
  });

  final TriageService triageService;
  final SpeechInputService speechInputService;
  final SpeechOutputService speechOutputService;

  @override
  Widget build(BuildContext context) {
    final AppLanguage selectedLanguage =
        SACAStateScope.of(context).selectedLanguage;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    LanguageService.get(selectedLanguage, L.appTitle),
                    style: const TextStyle(
                      color: SACAColors.charcoal,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${LanguageService.get(AppLanguage.english, L.chooseLanguage)} / '
                    '${LanguageService.get(AppLanguage.warlpiri, L.chooseLanguage)}',
                    style: const TextStyle(
                      color: SACAColors.secondaryText,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: LanguageCard(
                            accentColor: SACAColors.warlpiriOrange,
                            title: 'Warlpiri',
                            subtitle: 'Wayi! Yuendumu',
                            icon: Icons.record_voice_over_rounded,
                            onTap: () => _goToReportingMethod(
                              context,
                              AppLanguage.warlpiri,
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: LanguageCard(
                            accentColor: SACAColors.deepClinicalGreen,
                            title: 'English',
                            subtitle: 'Hello! Clinical mode',
                            icon: Icons.language_rounded,
                            onTap: () => _goToReportingMethod(
                              context,
                              AppLanguage.english,
                            ),
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
      ),
    );
  }

  void _goToReportingMethod(BuildContext context, AppLanguage language) {
    SACAStateScope.of(context).setLanguage(language);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportingMethodPage(
          triageService: triageService,
          speechInputService: speechInputService,
          speechOutputService: speechOutputService,
        ),
      ),
    );
  }
}
