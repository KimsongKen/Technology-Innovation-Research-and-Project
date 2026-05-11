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

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _WindowHeader(
                        icon: Icons.health_and_safety_rounded,
                        title: 'SACA',
                        subtitle: 'Choose language / Pina yimi',
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
                                onTap: () => _openReportingMethod(
                                  context,
                                  triageService,
                                  AppLanguage.warlpiri,
                                ),
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: LanguageCard(
                                accentColor: SACAColors.deepClinicalGreen,
                                title: 'English',
                                subtitle: 'Hello!  Clinical mode',
                                icon: Icons.language_rounded,
                                onTap: () => _openReportingMethod(
                                  context,
                                  triageService,
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
            );
          },
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
                      _PageBackButton(
                        onPressed: () => Navigator.of(context).pop(),
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
        const _MobileHeader(
          icon: Icons.health_and_safety_rounded,
          title: 'SACA',
          subtitle: 'Choose language / Pina yimi',
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
        Align(
          alignment: Alignment.centerLeft,
          child: _PageBackButton(onPressed: () => Navigator.of(context).pop()),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: SACAColors.deepClinicalGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SACAColors.deepClinicalGreen.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
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
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 16,
                    height: 1.25,
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

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SACAColors.deepClinicalGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SACAColors.deepClinicalGreen.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
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
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                    height: 1.25,
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

class _MobileReportMethodCard extends StatelessWidget {
  const _MobileReportMethodCard({required this.data, required this.onTap});

  final ReportModeCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SACAColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SACAColors.subtleBorder),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Hero(
                tag: data.heroTag,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: data.accentColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data.icon, color: data.accentColor, size: 29),
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
                            style: const TextStyle(
                              color: SACAColors.charcoal,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (data.recommended) ...<Widget>[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.verified_rounded,
                            color: data.accentColor,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      data.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SACAColors.secondaryText,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: data.accentColor,
                size: 28,
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
        foregroundColor: SACAColors.deepClinicalGreen,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_rounded),
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
