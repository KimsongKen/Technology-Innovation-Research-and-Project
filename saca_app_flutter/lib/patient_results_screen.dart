// patient_results_screen.dart
// Patient-facing triage results screen — SACA app
// Matches existing app design language: cream bg, dark teal, rust/terracotta CTAs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum TriageLevel { severe, moderate, mild }

class PatientTriageResult {
  final TriageLevel level;
  final String actionPlan;          // e.g. "Attend clinic within 4 hours"
  final String verifiedTranscript;  // "What you told us"
  final String rawTranscript;       // Hidden by default — collapsible
  final String? onset;              // "When it started"
  final String? medications;        // "Medicines you mentioned"
  final String? allergies;          // "Allergies you mentioned"
  final String topCondition;        // e.g. "Chest pain assessment"
  final String languageDetected;    // 'en' or 'wbp'
  final String? warlpiriRawTranscript;

  const PatientTriageResult({
    required this.level,
    required this.actionPlan,
    required this.verifiedTranscript,
    required this.rawTranscript,
    this.onset,
    this.medications,
    this.allergies,
    required this.topCondition,
    this.languageDetected = 'en',
    this.warlpiriRawTranscript,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — matches existing app palette
// ─────────────────────────────────────────────────────────────────────────────

class _AppColors {
  // Base
  static const background = Color(0xFFF5F0E8);   // warm cream
  static const surface    = Color(0xFFFFFFFF);    // white cards
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF5A5A5A);
  static const textMuted     = Color(0xFF8A8A8A);
  static const divider       = Color(0xFFE8E0D4);

  // Brand
  static const teal      = Color(0xFF1E5C42);     // primary teal (mic button colour)
  static const tealLight = Color(0xFFD4EDE3);     // teal 10%
  static const rust      = Color(0xFF8B3A2A);     // CTA rust/terracotta
  static const rustLight = Color(0xFFF3DDD8);     // rust 10%

  // Triage level colours — calming, not alarming
  static const severe         = Color(0xFFE07B2A); // warm amber — urgent
  static const severeLight    = Color(0xFFFAEDD9);
  static const severeDark     = Color(0xFF7A3D0A);
  static const moderate       = Color(0xFFC9952A); // golden — attention
  static const moderateLight  = Color(0xFFFAF0D5);
  static const moderateDark   = Color(0xFF6B4E0A);
  static const mild           = Color(0xFF1E5C42); // teal — calm
  static const mildLight      = Color(0xFFD4EDE3);
  static const mildDark       = Color(0xFF0F3324);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PatientResultsScreen extends StatelessWidget {
  final PatientTriageResult result;

  const PatientResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed triage hero at the top
            _TriageLevelHero(level: result.level),

            // Scrollable content below the hero
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. FOCAL POINT: What to do next ──────────────────────
                    _ActionPlanCard(
                      level: result.level,
                      actionPlan: result.actionPlan,
                      topCondition: result.topCondition,
                    ),
                    const SizedBox(height: 16),

                    // ── 2. What you told us (verified transcript) ─────────────
                    _WhatYouToldUsCard(
                      verifiedTranscript: result.verifiedTranscript,
                      languageDetected: result.languageDetected,
                      warlpiriRawTranscript: result.warlpiriRawTranscript,
                    ),
                    const SizedBox(height: 16),

                    // ── 3. Quick summary of your visit (symptom data) ─────────
                    if (_hasSummaryData(result))
                      _VisitSummaryCard(
                        onset: result.onset,
                        medications: result.medications,
                        allergies: result.allergies,
                      ),
                    if (_hasSummaryData(result)) const SizedBox(height: 16),

                    // ── 4. Collapsible raw transcript (secondary, hidden) ──────
                    _RawTranscriptTile(rawTranscript: result.rawTranscript),
                    const SizedBox(height: 28),

                    // ── 5. Action buttons ─────────────────────────────────────
                    _ActionButtons(level: result.level),
                    const SizedBox(height: 16),

                    // ── 6. Reassurance footer ─────────────────────────────────
                    const _ReassuranceFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasSummaryData(PatientTriageResult r) =>
      (r.onset?.isNotEmpty ?? false) ||
      (r.medications?.isNotEmpty ?? false) ||
      (r.allergies?.isNotEmpty ?? false);
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 1 — TRIAGE LEVEL HERO
// Fixed at top. Large, colour-coded. Most important emotional signal.
// ─────────────────────────────────────────────────────────────────────────────

class _TriageLevelHero extends StatelessWidget {
  final TriageLevel level;
  const _TriageLevelHero({required this.level});

  @override
  Widget build(BuildContext context) {
    final config = _triageConfig(level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        // Subtle bottom border to separate from scrollable content
        border: const Border(
          bottom: BorderSide(color: Color(0x18000000), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back nav + language badge row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new,
                        size: 16, color: config.textColor),
                    const SizedBox(width: 4),
                    Text('Back',
                        style: TextStyle(
                            fontSize: 15,
                            color: config.textColor,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Triage level pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: config.pillColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  config.levelLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: config.pillTextColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main headline — the emotional anchor
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: config.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(config.icon, size: 26, color: config.iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  config.headline,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: config.textColor,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            config.subheadline,
            style: TextStyle(
              fontSize: 15,
              color: config.textColor.withOpacity(0.75),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  _TriageConfig _triageConfig(TriageLevel level) {
    switch (level) {
      case TriageLevel.severe:
        return _TriageConfig(
          backgroundColor: _AppColors.severeLight,
          textColor: _AppColors.severeDark,
          pillColor: _AppColors.severe,
          pillTextColor: Colors.white,
          iconBgColor: _AppColors.severe.withOpacity(0.18),
          iconColor: _AppColors.severe,
          icon: Icons.priority_high_rounded,
          levelLabel: 'Urgent',
          headline: 'Please get help right now.',
          subheadline:
              'Your symptoms need attention immediately. A nurse or doctor should see you straight away.',
        );
      case TriageLevel.moderate:
        return _TriageConfig(
          backgroundColor: _AppColors.moderateLight,
          textColor: _AppColors.moderateDark,
          pillColor: _AppColors.moderate,
          pillTextColor: Colors.white,
          iconBgColor: _AppColors.moderate.withOpacity(0.18),
          iconColor: _AppColors.moderate,
          icon: Icons.schedule_rounded,
          levelLabel: 'See nurse today',
          headline: 'Please see a nurse today.',
          subheadline:
              'Your symptoms are important. Please visit the clinic within the next few hours.',
        );
      case TriageLevel.mild:
        return _TriageConfig(
          backgroundColor: _AppColors.mildLight,
          textColor: _AppColors.mildDark,
          pillColor: _AppColors.mild,
          pillTextColor: Colors.white,
          iconBgColor: _AppColors.mild.withOpacity(0.18),
          iconColor: _AppColors.mild,
          icon: Icons.check_circle_outline_rounded,
          levelLabel: 'When ready',
          headline: 'You can be seen when ready.',
          subheadline:
              'Your symptoms do not appear urgent right now. Please still visit the clinic today if you can.',
        );
    }
  }
}

class _TriageConfig {
  final Color backgroundColor, textColor, pillColor, pillTextColor;
  final Color iconBgColor, iconColor;
  final IconData icon;
  final String levelLabel, headline, subheadline;

  const _TriageConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.pillColor,
    required this.pillTextColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.icon,
    required this.levelLabel,
    required this.headline,
    required this.subheadline,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 2 — ACTION PLAN CARD
// The focal point. Most prominent card on screen.
// ─────────────────────────────────────────────────────────────────────────────

class _ActionPlanCard extends StatelessWidget {
  final TriageLevel level;
  final String actionPlan;
  final String topCondition;

  const _ActionPlanCard({
    required this.level,
    required this.actionPlan,
    required this.topCondition,
  });

  @override
  Widget build(BuildContext context) {
    // Left-border accent color matches triage level
    final accentColor = level == TriageLevel.severe
        ? _AppColors.severe
        : level == TriageLevel.moderate
            ? _AppColors.moderate
            : _AppColors.teal;

    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card label
            Row(
              children: [
                Icon(Icons.directions_walk_rounded,
                    size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  'What to do next',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // The action plan — largest text on the card
            Text(
              actionPlan,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),

            // Top condition context
            Text(
              'Based on: $topCondition',
              style: const TextStyle(
                fontSize: 14,
                color: _AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            // "Tell the nurse" CTA button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {/* Navigate to nurse handoff */},
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                label: const Text(
                  'Show this to the nurse',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.rust,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 3 — WHAT YOU TOLD US
// Verified transcript — confirms the patient was heard correctly.
// Includes Warlpiri source if applicable.
// ─────────────────────────────────────────────────────────────────────────────

class _WhatYouToldUsCard extends StatelessWidget {
  final String verifiedTranscript;
  final String languageDetected;
  final String? warlpiriRawTranscript;

  const _WhatYouToldUsCard({
    required this.verifiedTranscript,
    required this.languageDetected,
    this.warlpiriRawTranscript,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      icon: Icons.chat_bubble_outline_rounded,
      iconColor: _AppColors.teal,
      label: 'What you told us',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language badge (Warlpiri only)
          if (languageDetected == 'wbp') ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _AppColors.tealLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.record_voice_over,
                      size: 13, color: _AppColors.teal),
                  SizedBox(width: 4),
                  Text(
                    'Warlpiri',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Verified transcript
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AppColors.divider),
            ),
            child: Text(
              verifiedTranscript.isNotEmpty
                  ? '"$verifiedTranscript"'
                  : 'No transcript recorded.',
              style: const TextStyle(
                fontSize: 16,
                color: _AppColors.textPrimary,
                height: 1.55,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Warlpiri original source (if applicable)
          if (warlpiriRawTranscript != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: const Icon(Icons.translate,
                  size: 18, color: _AppColors.textMuted),
              title: const Text(
                'Original Warlpiri words',
                style: TextStyle(
                  fontSize: 13,
                  color: _AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              iconColor: _AppColors.textMuted,
              collapsedIconColor: _AppColors.textMuted,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 26),
                  child: Text(
                    '"$warlpiriRawTranscript"',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 4 — VISIT SUMMARY CARD
// Onset, medications, allergies — patient-friendly labels.
// ─────────────────────────────────────────────────────────────────────────────

class _VisitSummaryCard extends StatelessWidget {
  final String? onset;
  final String? medications;
  final String? allergies;

  const _VisitSummaryCard({this.onset, this.medications, this.allergies});

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      icon: Icons.summarize_outlined,
      iconColor: _AppColors.teal,
      label: 'A quick summary of your visit',
      child: Column(
        children: [
          if (onset?.isNotEmpty ?? false)
            _SummaryRow(
              icon: Icons.access_time_rounded,
              label: 'When it started',
              value: onset!,
            ),
          if (medications?.isNotEmpty ?? false) ...[
            if (onset?.isNotEmpty ?? false)
              const Divider(height: 20, color: _AppColors.divider),
            _SummaryRow(
              icon: Icons.medication_outlined,
              label: 'Medicines you mentioned',
              value: medications!,
            ),
          ],
          if (allergies?.isNotEmpty ?? false) ...[
            if ((onset?.isNotEmpty ?? false) ||
                (medications?.isNotEmpty ?? false))
              const Divider(height: 20, color: _AppColors.divider),
            _SummaryRow(
              icon: Icons.warning_amber_rounded,
              label: 'Allergies you mentioned',
              value: allergies!,
              valueColor: _AppColors.rust,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: valueColor ?? _AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 5 — RAW TRANSCRIPT (COLLAPSED BY DEFAULT)
// Secondary, technical — hidden to reduce cognitive load.
// ─────────────────────────────────────────────────────────────────────────────

class _RawTranscriptTile extends StatelessWidget {
  final String rawTranscript;
  const _RawTranscriptTile({required this.rawTranscript});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.divider),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: const Icon(Icons.mic_none_rounded,
            color: _AppColors.textMuted, size: 20),
        title: const Text(
          'Original recording transcript',
          style: TextStyle(
            fontSize: 14,
            color: _AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: const Text(
          'Tap to see the unedited audio transcript',
          style: TextStyle(
            fontSize: 12,
            color: _AppColors.textMuted,
          ),
        ),
        iconColor: _AppColors.textMuted,
        collapsedIconColor: _AppColors.textMuted,
        children: [
          const Divider(height: 1, color: _AppColors.divider),
          const SizedBox(height: 14),
          Text(
            rawTranscript.isNotEmpty
                ? rawTranscript
                : 'No raw transcript available.',
            style: const TextStyle(
              fontSize: 14,
              color: _AppColors.textSecondary,
              height: 1.6,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is exactly what the microphone heard. It may contain errors.',
            style: TextStyle(
              fontSize: 12,
              color: _AppColors.textMuted.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 6 — ACTION BUTTONS
// Context-sensitive. Severe = call for help. All = share + new assessment.
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final TriageLevel level;
  const _ActionButtons({required this.level});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Emergency call button — only for severe
        if (level == TriageLevel.severe) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {/* Launch emergency call */},
              icon: const Icon(Icons.phone_rounded, size: 22),
              label: const Text(
                'Call for urgent help',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.severe,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Share results button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {/* Share via system sheet */},
            icon: const Icon(Icons.share_outlined, size: 20),
            label: const Text(
              'Share these results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _AppColors.teal,
              side: const BorderSide(color: _AppColors.teal, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Start new assessment
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton.icon(
            onPressed: () {/* Navigate back to mode selection */},
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'Start a new assessment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            style: TextButton.styleFrom(
              foregroundColor: _AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 7 — REASSURANCE FOOTER
// Calm, grounding message at the very bottom.
// ─────────────────────────────────────────────────────────────────────────────

class _ReassuranceFooter extends StatelessWidget {
  const _ReassuranceFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.tealLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline_rounded,
              size: 18, color: _AppColors.teal),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This result is to help guide you — a trained nurse or doctor will always review your care. You are not alone.',
              style: TextStyle(
                fontSize: 13,
                color: _AppColors.mildDark,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED BASE CARD — used by What You Told Us + Visit Summary
// ─────────────────────────────────────────────────────────────────────────────

class _BaseCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  const _BaseCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card section label
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _AppColors.divider),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREVIEW — SAMPLE USAGE
// ─────────────────────────────────────────────────────────────────────────────

class PatientResultsPreview extends StatelessWidget {
  const PatientResultsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _AppColors.teal,
          background: _AppColors.background,
        ),
        useMaterial3: true,
        fontFamily: 'Helvetica Neue', // replace with your app's font
      ),
      home: PatientResultsScreen(
        result: const PatientTriageResult(
          level: TriageLevel.moderate,
          actionPlan: 'Attend the clinic within 4 hours for a clinician assessment.',
          verifiedTranscript: 'I have chest pain that started this morning and I feel dizzy.',
          rawTranscript: 'i have chest pan that start this morning and i feel dizzy',
          onset: 'This morning',
          medications: 'Metformin 500mg daily',
          allergies: 'Penicillin',
          topCondition: 'Chest pain assessment',
          languageDetected: 'en',
        ),
      ),
    );
  }
}

// Warlpiri example:
//
// PatientResultsScreen(
//   result: PatientTriageResult(
//     level: TriageLevel.severe,
//     actionPlan: 'Go to the emergency area right now. Do not wait.',
//     verifiedTranscript: 'chest pain, difficulty breathing — severe',
//     rawTranscript: 'rduku-rduku pacha wiri wardapi nganta',
//     onset: 'Just now',
//     medications: null,
//     allergies: null,
//     topCondition: 'Acute chest pain',
//     languageDetected: 'wbp',
//     warlpiriRawTranscript: 'rduku-rduku pacha wiri wardapi nganta',
//   ),
// )
