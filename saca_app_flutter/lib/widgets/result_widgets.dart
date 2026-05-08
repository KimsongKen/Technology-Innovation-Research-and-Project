part of '../main.dart';

class _TriageHeader extends StatefulWidget {
  const _TriageHeader({
    required this.triageLevel,
    required this.topCondition,
    this.languageBadge,
    this.confidence = 0.0,
  });

  final String triageLevel;
  final String topCondition;
  final String? languageBadge;
  final double confidence;

  @override
  State<_TriageHeader> createState() => _TriageHeaderState();
}

class _TriageHeaderState extends State<_TriageHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color triageColor = TriagePresentation.colorForLevel(widget.triageLevel);
    final IconData? sevIcon = TriagePresentation.severityIcon(widget.triageLevel);
    final String assessedAt = TimeOfDay.now().format(context);
    final bool showConfidence =
        widget.confidence > 0 && widget.confidence <= 1.0;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          decoration: BoxDecoration(
            color: SACAColors.cardBackground,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: triageColor.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: triageColor.withValues(alpha: 0.28),
                blurRadius: 36,
                spreadRadius: -4,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: triageColor.withValues(alpha: 0.14),
                blurRadius: 52,
                spreadRadius: -8,
                offset: const Offset(0, 22),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      SACAStrings.tr(
                        context: context,
                        english: 'ASSESSED AT $assessedAt',
                        warlpiri: 'ASSESSED AT $assessedAt',
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: <Widget>[
                      if (widget.languageBadge != null &&
                          widget.languageBadge!.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: triageColor.withValues(alpha: 0.35),
                              width: 1.1,
                            ),
                            color: triageColor.withValues(alpha: 0.06),
                          ),
                          child: Text(
                            widget.languageBadge!.trim(),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (showConfidence)
                        _ConfidenceBadge(
                          confidence: widget.confidence,
                          accentColor: triageColor,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                SACAStrings.tr(
                  context: context,
                  english: 'CLINICAL FOCUS',
                  warlpiri: 'CLINICAL FOCUS',
                ),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.topCondition,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: SACAColors.charcoal,
                  fontSize: 26,
                  height: 1.22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: triageColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: triageColor.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (sevIcon != null) ...<Widget>[
                        Icon(
                          sevIcon,
                          color: triageColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.triageLevel.toUpperCase(),
                        style: TextStyle(
                          color: triageColor,
                          fontSize: 15,
                          letterSpacing: 0.9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({
    required this.confidence,
    required this.accentColor,
  });

  final double confidence;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final int pct = (confidence * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.verified_rounded, size: 12, color: accentColor),
          const SizedBox(width: 4),
          Text(
            '$pct% confidence',
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentDetailsTile extends StatelessWidget {
  const _AssessmentDetailsTile({
    required this.transcript,
    required this.symptoms,
    this.rawTranscript,
  });

  final String transcript;
  final List<String> symptoms;
  final String? rawTranscript;

  @override
  Widget build(BuildContext context) {
    final String safeTranscript = transcript.trim().isEmpty ? '-' : transcript.trim();
    final List<String> cleanSymptoms = symptoms
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: SACAColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SACAColors.subtleBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: SACAColors.deepClinicalGreen.withValues(alpha: 0.08),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          collapsedIconColor: SACAColors.secondaryText,
          iconColor: SACAColors.deepClinicalGreen,
          title: Row(
          children: <Widget>[
            const Icon(
              Icons.fact_check_outlined,
              size: 20,
              color: SACAColors.deepClinicalGreen,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                SACAStrings.tr(
                  context: context,
                  english: 'View Assessment Details',
                  warlpiri: 'View Assessment Details',
                ),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: SACAColors.charcoal,
                ),
              ),
            ),
          ],
        ),
        children: <Widget>[
          _detailsSectionTitle(context, 'Patient transcript'),
          const SizedBox(height: 8),
          Text(
            safeTranscript,
            style: const TextStyle(
              color: SACAColors.charcoal,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (rawTranscript != null && rawTranscript!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _detailsSectionTitle(context, 'Voice transcript (as recognized)'),
            const SizedBox(height: 8),
            Text(
              rawTranscript!.trim(),
              style: TextStyle(
                color: SACAColors.secondaryText.withValues(alpha: 0.92),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _detailsSectionTitle(context, 'Symptom summary'),
          const SizedBox(height: 8),
          if (cleanSymptoms.isEmpty)
            Text(
              '-',
              style: TextStyle(
                color: SACAColors.secondaryText.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cleanSymptoms
                  .map(
                    (String s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: SACAColors.pageBackground,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: SACAColors.subtleBorder),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: SACAColors.secondaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
        ),
      ),
    );
  }

  Widget _detailsSectionTitle(BuildContext context, String label) {
    return Text(
      SACAStrings.tr(
        context: context,
        english: label.toUpperCase(),
        warlpiri: label.toUpperCase(),
      ),
      style: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _ActionPlanBox extends StatelessWidget {
  const _ActionPlanBox({
    required this.triageLevel,
    required this.recommendation,
  });

  final String triageLevel;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    final Color tone = TriagePresentation.colorForLevel(triageLevel);
    final IconData? sevIcon = TriagePresentation.severityIcon(triageLevel);
    final String resolvedRecommendation = recommendation.trim().isNotEmpty
        ? recommendation
        : TriagePresentation.recommendationForLevel(triageLevel);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: SACAColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SACAColors.subtleBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(height: 4, color: tone),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (sevIcon != null) ...<Widget>[
                        Icon(
                          sevIcon,
                          color: tone,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        SACAStrings.tr(
                          context: context,
                          english: 'Recommended actions',
                          warlpiri: 'Recommended actions',
                        ),
                        style: TextStyle(
                          color: tone,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    resolvedRecommendation,
                    style: const TextStyle(
                      color: SACAColors.charcoal,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
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

class _EscalationBanner extends StatelessWidget {
  const _EscalationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B0000).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.emergency_rounded,
            color: Color(0xFF8B0000),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              SACAStrings.tr(
                context: context,
                english:
                    'ESCALATION TRIGGERED — Immediate clinical review required.',
                warlpiri:
                    'ESCALATION TRIGGERED — Immediate clinical review required.',
              ),
              style: const TextStyle(
                color: Color(0xFF8B0000),
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultActionBar extends StatelessWidget {
  const _ResultActionBar({
    required this.triageColor,
    required this.onAlertClinic,
    required this.onReturnHome,
  });

  final Color triageColor;
  final VoidCallback onAlertClinic;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IgnorePointer(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReturnHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SACAColors.secondaryText,
                      side: const BorderSide(
                        color: SACAColors.subtleBorder,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'NEW ASSESSMENT',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: triageColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onAlertClinic,
                    child: const Text(
                      'ALERT CLINIC',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
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
