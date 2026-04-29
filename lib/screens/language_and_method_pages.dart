part of '../main.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key, required this.triageService});

  final TriageService triageService;

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Smart Adaptive Clinical Assistant',
                    style: TextStyle(
                      color: SACAColors.charcoal,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose language / Pina yimi',
                    style: TextStyle(
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
                            subtitle: 'Wayi!  Yuendumu',
                            icon: Icons.record_voice_over_rounded,
                            onTap: () {
                              SACAStateScope.of(context).setLanguage(AppLanguage.warlpiri);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReportingMethodPage(triageService: triageService),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: LanguageCard(
                            accentColor: SACAColors.deepClinicalGreen,
                            title: 'English',
                            subtitle: 'Hello!  Clinical mode',
                            icon: Icons.language_rounded,
                            onTap: () {
                              SACAStateScope.of(context).setLanguage(AppLanguage.english);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReportingMethodPage(triageService: triageService),
                                ),
                              );
                            },
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
}

class ReportingMethodPage extends StatelessWidget {
  const ReportingMethodPage({super.key, required this.triageService});

  final TriageService triageService;

  @override
  Widget build(BuildContext context) {
    final List<ReportModeCardData> methods = <ReportModeCardData>[
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
          english: 'Point to Pictures',
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
                    label: Text(
                      SACAStrings.tr(
                        context: context,
                        english: 'Back',
                        warlpiri: 'Rete',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose How to Report',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: SACAColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    SACAStrings.tr(
                      context: context,
                      english: 'Pick one clinical input method',
                      warlpiri: 'Clinical input nyampu pina',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: SACAColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final int columns = constraints.maxWidth >= 980 ? 3 : 1;
                        return GridView.builder(
                          itemCount: methods.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                            childAspectRatio: columns == 3 ? 1.03 : 1.7,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final ReportModeCardData data = methods[index];
                            return ReportModeCard(
                              data: data,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => WorkspacePage(
                                      mode: data.mode,
                                      heroTag: data.heroTag,
                                      triageService: triageService,
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
