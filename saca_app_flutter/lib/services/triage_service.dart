part of '../main.dart';

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
    if (Platform.isAndroid) {
      // Android emulator localhost maps to itself; host machine is 10.0.2.2.
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<String> transcribeAudio(File wavFile, {String languageCode = 'en'}) async {
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
      if (session.additionalConcerns.trim().isNotEmpty)
        'Other symptoms or concerns: ${session.additionalConcerns.trim()}',
    ].where((String s) => s.trim().isNotEmpty).join('. ');
    final String verifiedTranscript =
        enrichedVerified.isEmpty ? verifiedCore : enrichedVerified;

    final String rawTranscript = (_lastRawTranscript ?? verifiedCore).trim();
    final String languageCode = language == AppLanguage.warlpiri ? 'wbp' : 'en';

    final List<String> predictUrls = <String>['$baseUrl/triage/predict'];

    for (final String url in predictUrls) {
      try {
        final Uri uri = Uri.parse(url);
        final Map<String, dynamic> payload = <String, dynamic>{
          'raw_transcript': rawTranscript.isEmpty ? narrative : rawTranscript,
          'verified_transcript':
              verifiedTranscript.isEmpty ? narrative : verifiedTranscript,
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
