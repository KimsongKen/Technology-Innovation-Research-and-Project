part of '../main.dart';

// ── Warlpiri → English medical vocabulary bridge ─────────────────────────────
// SBERT was trained on English only. Warlpiri words produce near-zero
// embeddings, causing misclassification (e.g. heart attack → multiple sclerosis).
// This map substitutes known Warlpiri clinical terms with their English
// equivalents BEFORE the text reaches the SBERT embedding layer.
// Add more entries as the vocabulary grows — keys are lowercase Warlpiri words
// or common code-switched phrases.
const Map<String, String> _kWarlpiriMedicalVocab = <String, String>{
  // Pain / body
  'warlu':         'pain',
  'karlarra':      'chest pain',
  'kurduju':       'strong severe',
  'pirli-pirli':   'shaking trembling',
  'parnkami':      'running out of breath',
  'nyinami':       'experiencing feeling',
  'warlkirri':     'squeezing tight pressure',
  'warlaljarrimi': 'squeezing crushing pain',
  'rdaka':         'arm hand',
  'wirliya':       'foot leg',
  'yirrarni':      'feeling sensation',
  // Severity / urgency
  'panu':          'worse severe',
  'kapingkilypa':  'rapidly quickly',
  'wiri':          'big large severe',
  'jaru':          'spreading radiating',
  // Symptoms
  'kirda-kirda':   'dizziness lightheadedness',
  'nyiya-nyiyami': 'nausea vomiting',
  'yimi':          'breathing difficulty',
  'wangkarra':     'difficulty speaking',
  // Body parts
  'marlu':         'heart',
  'ngurra':        'body chest',
  'munga':         'head',
  'wanta':         'left side',
  // Duration / onset
  'jinta-kurra':   '1 day',
  'jirrama-kurra': '2 to 3 days',
  'manu-kurra':    '4 to 6 days',
  // Medications / allergies
  'pawuju':        'medication medicine',
  'yarnunjuku':    'allergy allergic reaction',
  // Common verbs relevant to clinical context
  'nyinaja':       'started began',
  'pina':          'back again',
  'karlipa':       'going moving',
  'pitjiri':       'coming arriving',
};

/// Translates Warlpiri words in [text] to English equivalents using
/// [_kWarlpiriMedicalVocab]. Leaves English words and unknown Warlpiri
/// words unchanged. Used only when [languageCode] is 'wbp'.
String _translateWarlpiriToEnglish(String text) {
  if (text.trim().isEmpty) return text;
  // Split on whitespace, replace known tokens, rejoin.
  final List<String> tokens = text.split(RegExp(r'\s+'));
  final List<String> translated = tokens.map((String token) {
    // Strip trailing punctuation before lookup, restore after.
    final String clean = token
        .replaceAll(RegExp(r'[.,;:!?]+$'), '')
        .toLowerCase();
    final String suffix = token.substring(clean.length < token.length
        ? clean.length
        : token.length);
    final String? mapped = _kWarlpiriMedicalVocab[clean];
    return mapped != null ? '$mapped$suffix' : token;
  }).toList();
  return translated.join(' ');
}

class TriageService {
  TriageService({
    String? baseUrl,
    this.authToken = 'dev-token',
  }) : baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  final String baseUrl;
  final String authToken;
  String? _lastRawTranscript;

  static String _resolveDefaultBaseUrl() {
    const String configured = String.fromEnvironment('SACA_API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }
    if (!kIsWeb && io.Platform.isAndroid) {
      // 127.0.0.1 works for both:
      //   - Real device via USB with `adb reverse tcp:8000 tcp:8000`
      //   - Emulator (10.0.2.2 also works on emulator, but 127.0.0.1 via adb reverse works too)
      return 'http://127.0.0.1:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<String> transcribeAudio(io.File wavFile, {String languageCode = 'en'}) async {
    final List<String> candidatePaths = <String>[
      '$baseUrl/triage/transcribe',
    ];
    String? lastError;
    final List<String> attempted = <String>[];

    for (final String url in candidatePaths) {
      try {
        attempted.add(url);
        final int wavSize = await wavFile.length();
        if (wavSize <= 0) {
          throw Exception('Recorded file is empty (0 bytes).');
        }
        final bool exists = await wavFile.exists();
        debugPrint(
          '[SACA][UPLOAD] transcribe path=${wavFile.path} exists=$exists '
          'size_bytes=$wavSize url=$url',
        );
        final Uri uri = Uri.parse(url);
        final http.MultipartRequest req = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $authToken';

        req.files.add(
          await http.MultipartFile.fromPath(
            'audio_file',
            wavFile.path,
            filename: 'voice_note.wav',
          ),
        );
        req.fields['language'] = languageCode;

        final http.StreamedResponse streamed = await req.send();
        final String body = await streamed.stream.bytesToString();
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          lastError = 'HTTP ${streamed.statusCode}: $body';
          // Route not found/method mismatch -> try next compatibility endpoint.
          if (streamed.statusCode == 404 || streamed.statusCode == 405) {
            continue;
          }
          // Any other status (notably 422 with useful detail) is a real failure.
          // Stop trying additional endpoints and surface this response upstream.
          break;
        }

        final dynamic decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) continue;
        final Map<String, dynamic> jsonMap = decoded;
        final String transcript = (
          jsonMap['transcript'] ??
          jsonMap['transcript_final'] ??
          jsonMap['transcript_final_text'] ??
          ''
        )
            .toString();
        if (transcript.trim().isNotEmpty) {
          _lastRawTranscript = transcript.trim();
          return transcript;
        }
      } catch (e) {
        lastError = 'Request exception while contacting $url: $e';
        continue;
      }
    }

    throw Exception(
      lastError ??
          'Transcription failed. Endpoints not available or returned no transcript. '
              'Tried: ${attempted.join(", ")}',
    );
  }

  Future<TriageApiResult> submitSession(
    TriageSession session, {
    required AppLanguage language,
  }) async {

    final int painScore = session.painScore.clamp(1, 10);
    final String narrative = [
      session.chiefComplaint,
      'Pain intensity (1–10 scale, 10 = unbearable): $painScore',
      if (session.symptomDurationDays.trim().isNotEmpty)
        'Symptom duration: ${session.symptomDurationDays.trim()}',
      if (session.onset.isNotEmpty) 'Onset: ${session.onset}',
      if (session.medications.isNotEmpty) 'Medications: ${session.medications}',
      if (session.allergies.isNotEmpty) 'Allergies: ${session.allergies}',
      'Worsening: ${session.isWorsening ? "yes" : "no"}',
      if (session.additionalConcerns.trim().isNotEmpty)
        'Other symptoms or requests: ${session.additionalConcerns.trim()}',
    ].where((String s) => s.trim().isNotEmpty).join('. ');

    final String verifiedCore = session.chiefComplaint.trim();
    final String enrichedVerified = [
      verifiedCore,
      'Pain intensity (1–10, 10 = unbearable pain): $painScore',
      if (session.symptomDurationDays.trim().isNotEmpty)
        'Duration: ${session.symptomDurationDays.trim()}',
      if (session.additionalConcerns.trim().isNotEmpty)
        'Other symptoms or concerns: ${session.additionalConcerns.trim()}',
    ].where((String s) => s.trim().isNotEmpty).join('. ');
    final String verifiedTranscript =
        enrichedVerified.isEmpty ? verifiedCore : enrichedVerified;

    final String rawTranscript = (_lastRawTranscript ?? verifiedCore).trim();
    final String languageCode = language == AppLanguage.warlpiri ? 'wbp' : 'en';

    // ── Warlpiri → English translation for SBERT ──────────────────────────
    // SBERT only understands English. When input is Warlpiri we translate
    // known medical vocabulary before embedding so the ML model gets a
    // semantically meaningful vector instead of near-zero unknowns.
    final String sttRaw = rawTranscript.isEmpty ? narrative : rawTranscript;
    final String sttVerified =
        verifiedTranscript.isEmpty ? narrative : verifiedTranscript;
    final String finalRaw = languageCode == 'wbp'
        ? _translateWarlpiriToEnglish(sttRaw)
        : sttRaw;
    final String finalVerified = languageCode == 'wbp'
        ? _translateWarlpiriToEnglish(sttVerified)
        : sttVerified;

    final List<String> predictUrls = <String>['$baseUrl/triage/predict'];

    for (final String url in predictUrls) {
      try {
        final Uri uri = Uri.parse(url);
        final Map<String, dynamic> payload = <String, dynamic>{
          'raw_transcript': finalRaw,
          'verified_transcript': finalVerified,
          'language': languageCode,
        };
        final http.Response response = await http
            .post(
              uri,
              headers: <String, String>{
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final Map<String, dynamic> merged = <String, dynamic>{
            ...decoded,
            if ((decoded['transcript_final'] ?? '').toString().isEmpty)
              'transcript_final':
                  verifiedTranscript.isEmpty ? narrative : verifiedTranscript,
            'language': languageCode,
          };
          return TriageApiResult.fromJson(merged);
        }
      } catch (_) {
        continue;
      }
    }

    final String fallbackLevel = session.isWorsening ? 'Moderate' : 'Mild';
    final String transcriptOut =
        verifiedTranscript.isNotEmpty ? verifiedTranscript : verifiedCore;
    return TriageApiResult(
      triageLevel: fallbackLevel,
      topCondition:
          session.chiefComplaint.isEmpty ? 'General clinical review' : 'Symptom review required',
      transcriptFinal: transcriptOut.isNotEmpty ? transcriptOut : narrative,
      recommendation: TriagePresentation.recommendationForLevel(fallbackLevel),
      confidence: 0.0,
      top3Symptoms: const <String>[],
      escalationTriggered: false,
      languageCode: languageCode,
    );
  }
}
