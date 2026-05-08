import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saca_app/main.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _testApp(Widget home) {
  return MaterialApp(
    home: SACAStateScope(
      state: SACAAppState(),
      child: home,
    ),
  );
}

TriageSession _session({
  String chiefComplaint = 'Chest pain',
  String onset = '1 day',
  bool isWorsening = false,
  int painScore = 5,
}) {
  return TriageSession(
    chiefComplaint: chiefComplaint,
    onset: onset,
    isWorsening: isWorsening,
    medications: '',
    allergies: '',
    painLocation: <String>['Chest'],
    painScore: painScore,
  );
}

TriageApiResult _result({
  String triageLevel = 'Moderate',
  String topCondition = 'Respiratory Infection',
  String recommendation = 'See clinic within 4 hours.',
  double confidence = 0.82,
  bool escalationTriggered = false,
}) {
  return TriageApiResult(
    triageLevel: triageLevel,
    topCondition: topCondition,
    transcriptFinal: 'Patient reports $topCondition.',
    recommendation: recommendation,
    confidence: confidence,
    top3Symptoms: <String>['fever', 'cough', 'fatigue'],
    escalationTriggered: escalationTriggered,
  );
}

// ---------------------------------------------------------------------------
// TriagePresentation unit tests (no widget tree required)
// ---------------------------------------------------------------------------

void main() {
  group('TriagePresentation.colorForLevel', () {
    test('returns dark-red for severe/high/critical levels', () {
      const Color expected = Color(0xFF8B0000);
      expect(TriagePresentation.colorForLevel('High'), equals(expected));
      expect(TriagePresentation.colorForLevel('SEVERE'), equals(expected));
      expect(TriagePresentation.colorForLevel('Critical'), equals(expected));
    });

    test('returns amber for moderate/medium levels', () {
      const Color expected = Color(0xFFB8860B);
      expect(TriagePresentation.colorForLevel('Moderate'), equals(expected));
      expect(TriagePresentation.colorForLevel('medium'), equals(expected));
    });

    test('returns green for mild/low levels', () {
      const Color expected = Color(0xFF1A5241);
      expect(TriagePresentation.colorForLevel('Mild'), equals(expected));
      expect(TriagePresentation.colorForLevel('Low'), equals(expected));
      expect(TriagePresentation.colorForLevel(''), equals(expected));
    });
  });

  group('TriagePresentation.recommendationForLevel', () {
    test('returns evacuation text for high severity', () {
      final String rec = TriagePresentation.recommendationForLevel('High');
      expect(rec, contains('Evacuate immediately'));
    });

    test('returns clinic-visit text for moderate', () {
      final String rec = TriagePresentation.recommendationForLevel('Moderate');
      expect(rec, contains('4 hours'));
    });

    test('returns routine text for mild', () {
      final String rec = TriagePresentation.recommendationForLevel('Mild');
      expect(rec, contains('Routine'));
    });
  });

  // ---------------------------------------------------------------------------
  // ResultSummaryPage widget tests
  // ---------------------------------------------------------------------------

  group('ResultSummaryPage', () {
    testWidgets('shows triage level and top condition', (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(
          ResultSummaryPage(
            session: _session(),
            triageService: TriageService(),
            apiResult: _result(
              triageLevel: 'High',
              topCondition: 'Cardiac Event',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('HIGH'), findsWidgets);
      expect(find.text('Cardiac Event'), findsOneWidget);
    });

    testWidgets('shows confidence badge when confidence > 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(
          ResultSummaryPage(
            session: _session(),
            triageService: TriageService(),
            apiResult: _result(confidence: 0.75),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('75% confidence'), findsOneWidget);
    });

    testWidgets('hides confidence badge when confidence is 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(
          ResultSummaryPage(
            session: _session(),
            triageService: TriageService(),
            apiResult: _result(confidence: 0.0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('confidence'), findsNothing);
    });

    testWidgets('shows escalation banner when escalationTriggered is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(
          ResultSummaryPage(
            session: _session(),
            triageService: TriageService(),
            apiResult: _result(escalationTriggered: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ESCALATION TRIGGERED'), findsOneWidget);
    });

    testWidgets('does not show escalation banner when escalationTriggered is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(
          ResultSummaryPage(
            session: _session(),
            triageService: TriageService(),
            apiResult: _result(escalationTriggered: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ESCALATION TRIGGERED'), findsNothing);
    });

    testWidgets('symptom chips are shown in assessment details', (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(
          ResultSummaryPage(
            session: _session(),
            triageService: TriageService(),
            apiResult: _result(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand the assessment details tile.
      await tester.tap(find.text('View Assessment Details'));
      await tester.pumpAndSettle();

      expect(find.text('fever'), findsOneWidget);
      expect(find.text('cough'), findsOneWidget);
      expect(find.text('fatigue'), findsOneWidget);
    });

    testWidgets('NEW ASSESSMENT and ALERT CLINIC buttons are visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(
          ResultSummaryPage(
            session: _session(),
            triageService: TriageService(),
            apiResult: _result(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEW ASSESSMENT'), findsOneWidget);
      expect(find.text('ALERT CLINIC'), findsOneWidget);
    });
  });
}
