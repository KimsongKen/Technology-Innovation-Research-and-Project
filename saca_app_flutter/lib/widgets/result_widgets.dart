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
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color triageColor = _triageColor(widget.triageLevel);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: RadialGradient(
          center: const Alignment(-0.7, -0.8),
          radius: 1.3,
          colors: <Color>[triageColor.withValues(alpha: 0.28), Colors.white],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: triageColor.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          ScaleTransition(
            scale: _pulseScale,
            child: Icon(Icons.favorite, color: triageColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.triageLevel.toUpperCase(),
                  style: TextStyle(
                    color: triageColor,
                    fontSize: 28,
                    letterSpacing: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.topCondition,
                  style: const TextStyle(
                    color: SACAColors.charcoal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.languageBadge != null &&
                    widget.languageBadge!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(Icons.translate, size: 18, color: triageColor),
                      label: Text(
                        widget.languageBadge!.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      backgroundColor: triageColor.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTranscriptBox extends StatelessWidget {
  const _PatientTranscriptBox({required this.transcript});

  final String transcript;

  @override
  Widget build(BuildContext context) {
    final String value = transcript.trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SACAColors.subtleBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Patient Transcript:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SACAColors.secondaryText,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: SACAColors.charcoal,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tone.withValues(alpha: 0.11),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Action Plan',
            style: TextStyle(
              color: tone,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resolvedRecommendation,
            style: const TextStyle(
              color: SACAColors.charcoal,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomWrap extends StatelessWidget {
  const _SymptomWrap({required this.symptoms});

  final List<String> symptoms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SACAColors.subtleBorder.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Symptom Summary',
            style: TextStyle(
              color: SACAColors.secondaryText.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            symptoms.where((String s) => s.trim().isNotEmpty).join('  •  '),
            style: TextStyle(
              color: SACAColors.secondaryText.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.35,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: onReturnHome,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: SACAColors.deepClinicalGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('NEW ASSESSMENT'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: triageColor,
                foregroundColor: Colors.white,
                elevation: 6,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onAlertClinic,
              child: const Text('ALERT CLINIC'),
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
