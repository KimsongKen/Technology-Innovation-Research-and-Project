import 'package:flutter/material.dart';

import '../core/enums/report_mode.dart';
import '../core/language/language_keys.dart';
import '../core/language/language_service.dart';
import '../core/theme/saca_colors.dart';
import '../services/speech_input_service.dart';
import '../services/speech_output_service.dart';
import '../services/triage_service.dart';
import '../state/saca_state_scope.dart';
import '../widgets/report_mode_card.dart';
import 'workspace_page.dart';

class ReportingMethodPage extends StatelessWidget {
  const ReportingMethodPage({
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
    final language = SACAStateScope.of(context).selectedLanguage;
    final List<ReportModeCardData> methods = <ReportModeCardData>[
      ReportModeCardData(
        mode: ReportMode.voice,
        heroTag: 'mode-voice',
        icon: Icons.mic_rounded,
        accentColor: SACAColors.deepClinicalGreen,
        title: LanguageService.get(language, L.voice),
        description: LanguageService.get(language, L.voiceDescription),
        recommended: true,
      ),
      ReportModeCardData(
        mode: ReportMode.selection,
        heroTag: 'mode-selection',
        icon: Icons.touch_app_rounded,
        accentColor: SACAColors.earthClay,
        title: LanguageService.get(language, L.selection),
        description: LanguageService.get(language, L.selectionDescription),
      ),
      ReportModeCardData(
        mode: ReportMode.text,
        heroTag: 'mode-text',
        icon: Icons.edit_note_rounded,
        accentColor: SACAColors.warningRedBrown,
        title: LanguageService.get(language, L.text),
        description: LanguageService.get(language, L.textDescription),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(LanguageService.get(language, L.back)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LanguageService.get(language, L.chooseReportMethod),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: SACAColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    LanguageService.get(language, L.pickInputMethod),
                    style: const TextStyle(
                      fontSize: 16,
                      color: SACAColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
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
                                    childAspectRatio: columns == 3 ? 1.03 : 1.7,
                                  ),
                              itemBuilder: (BuildContext context, int index) {
                                final ReportModeCardData data = methods[index];
                                return ReportModeCard(
                                  data: data,
                                  recommendedLabel: LanguageService.get(
                                    language,
                                    L.recommended,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => WorkspacePage(
                                          mode: data.mode,
                                          heroTag: data.heroTag,
                                          triageService: triageService,
                                          speechInputService:
                                              speechInputService,
                                          speechOutputService:
                                              speechOutputService,
                                        ),
                                      ),
                                    );
                                  },
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
        ),
      ),
    );
  }
}
