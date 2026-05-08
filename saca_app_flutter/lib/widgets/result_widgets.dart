part of '../main.dart';

class _TriageHeader extends StatefulWidget {
  const _TriageHeader({
    required this.triageLevel,
    required this.topCondition,
    this.languageBadge,
  });

  final String triageLevel;
  final String topCondition;
  final String? languageBadge;

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
    final Color triageColor = _triageColor(widget.triageLevel);
    final Color soft = Color.lerp(Colors.white, triageColor, 0.13)!;
    final String assessedAt = TimeOfDay.now().format(context);

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                soft.withValues(alpha: 0.95),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                SACAStrings.tr(
                  context: context,
                  english: 'ASSESSED AT $assessedAt',
                  warlpiri: 'ASSESSED AT $assessedAt',
                ),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: triageColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_rounded, color: triageColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Spacer(),
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
                          color: triageColor.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
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
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -4),
                  child: Text(
                    widget.triageLevel.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: triageColor,
                      fontSize: 30,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                SACAStrings.tr(
                  context: context,
                  english: 'DISEASE PREDICTION',
                  warlpiri: 'DISEASE PREDICTION',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  widget.topCondition,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SACAColors.charcoal,
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
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
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        collapsedIconColor: SACAColors.secondaryText,
        iconColor: SACAColors.deepClinicalGreen,
        title: Row(
          children: <Widget>[
            const Icon(Icons.fact_check_outlined, size: 20, color: SACAColors.deepClinicalGreen),
            const SizedBox(width: 10),
            Text(
              SACAStrings.tr(
                context: context,
                english: 'View Assessment Details',
                warlpiri: 'View Assessment Details',
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: SACAColors.charcoal,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
    final Color tone = _triageColor(triageLevel);
    final String resolvedRecommendation = recommendation.trim().isNotEmpty
        ? recommendation
        : _defaultRecommendationForLevel(triageLevel);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border(left: BorderSide(color: tone, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.next_plan_rounded, color: tone, size: 22),
              const SizedBox(width: 8),
              Text(
                SACAStrings.tr(
                  context: context,
                  english: 'Next Steps',
                  warlpiri: 'Next Steps',
                ),
                style: TextStyle(
                  color: tone,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                      side: const BorderSide(color: SACAColors.subtleBorder, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'NEW ASSESSMENT',
                      style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.1),
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
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
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

Color _triageColor(String level) {
  final String normalized = level.toLowerCase();
  if (normalized.contains('severe') ||
      normalized.contains('high') ||
      normalized.contains('critical')) {
    return const Color(0xFF8B0000);
  }
  if (normalized.contains('moderate') || normalized.contains('medium')) {
    return const Color(0xFFB8860B);
  }
  return const Color(0xFF1A5241);
}

String _defaultRecommendationForLevel(String level) {
  final String normalized = level.toLowerCase();
  if (normalized.contains('severe') ||
      normalized.contains('high') ||
      normalized.contains('critical')) {
    return 'Evacuate immediately. Alert the nearest medical officer. '
        'Monitor vitals every 5 minutes.';
  }
  if (normalized.contains('moderate') || normalized.contains('medium')) {
    return 'Schedule clinic visit within 4 hours. Keep patient hydrated. '
        'Monitor for worsening symptoms.';
  }
  return 'Routine check-up recommended. Provide home care instructions. '
      'Follow up if symptoms persist.';
}
