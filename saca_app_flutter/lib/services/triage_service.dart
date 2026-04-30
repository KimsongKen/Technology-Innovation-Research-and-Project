part of '../main.dart';

class TriageService {
  TriageService({
    String? baseUrl,
    this.authToken = 'dev-token',
  }) : baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  final String baseUrl;
  final String authToken;
  String? _lastRecordedWavPath;

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

  Future<String> transcribeAudio(File wavFile) async {
    _lastRecordedWavPath = wavFile.path;
    final List<String> candidatePaths = <String>[
      '$baseUrl/triage/analyze-voice',
      '$baseUrl/v2/triage/analyze-voice',
    ];
    String? lastError;

    for (final String url in candidatePaths) {
      try {
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

        final http.StreamedResponse streamed = await req.send();
        final String body = await streamed.stream.bytesToString();
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          lastError = 'HTTP ${streamed.statusCode}: $body';
          continue;
        }

        final dynamic decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) continue;
        final Map<String, dynamic> jsonMap = decoded;
        final String transcript = (jsonMap['transcript'] ?? '').toString();
        if (transcript.trim().isNotEmpty) return transcript;
      } catch (_) {
        lastError = 'Request exception while contacting $url';
        continue;
      }
    }

    throw Exception(lastError ?? 'Transcription failed (no valid response received).');
  }

  Future<TriageApiResult> submitSession(
    TriageSession session, {
    File? wavFile,
  }) async {
    final File? resolvedWavFile =
        wavFile ?? ((_lastRecordedWavPath != null) ? File(_lastRecordedWavPath!) : null);

    final String narrative = [
      session.chiefComplaint,
      if (session.onset.isNotEmpty) 'Onset: ${session.onset}',
      if (session.medications.isNotEmpty) 'Medications: ${session.medications}',
      if (session.allergies.isNotEmpty) 'Allergies: ${session.allergies}',
      'Worsening: ${session.isWorsening ? "yes" : "no"}',
    ].where((String s) => s.trim().isNotEmpty).join('. ');

    final List<String> urls = <String>[
      '$baseUrl/triage/analyze-voice',
      '$baseUrl/v2/triage/analyze-voice',
    ];

    for (final String url in urls) {
      try {
        final Uri uri = Uri.parse(url);
        final http.MultipartRequest req = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $authToken'
          ..fields['text_input'] = narrative
          ..fields['voice_transcript'] = session.chiefComplaint
          ..fields['pain_locations'] = jsonEncode(session.painLocation);

        if (resolvedWavFile != null && await resolvedWavFile.exists()) {
          final int audioBytes = await resolvedWavFile.length();
          debugPrint(
            '[SACA][UPLOAD] analyze path=${resolvedWavFile.path} exists=true '
            'size_bytes=$audioBytes url=$url',
          );
          req.files.add(
            await http.MultipartFile.fromPath(
              'audio_file',
              resolvedWavFile.path,
              filename: 'voice_note.wav',
            ),
          );
        } else {
          debugPrint('[SACA][UPLOAD] analyze using fallback WAV bytes url=$url');
          req.files.add(
            http.MultipartFile.fromBytes(
              'audio_file',
              _buildFallbackWavBytes(),
              filename: 'fallback.wav',
            ),
          );
        }

        final http.StreamedResponse streamed = await req.send().timeout(
          const Duration(seconds: 20),
        );
        final String body = await streamed.stream.bytesToString().timeout(
          const Duration(seconds: 20),
        );
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          continue;
        }
        final dynamic decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return TriageApiResult.fromJson(decoded);
        }
      } catch (_) {
        continue;
      }
    }

    final String fallbackLevel = session.isWorsening ? 'Moderate' : 'Mild';
    return TriageApiResult(
      triageLevel: fallbackLevel,
      topCondition:
          session.chiefComplaint.isEmpty ? 'General clinical review' : 'Symptom review required',
      transcriptFinal: session.chiefComplaint,
      recommendation: _defaultRecommendationForLevel(fallbackLevel),
    );
  }

  Uint8List _buildFallbackWavBytes() {
    const int sampleRate = 16000;
    const int seconds = 1;
    const int numChannels = 1;
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final int blockAlign = numChannels * (bitsPerSample ~/ 8);
    final int dataSize = sampleRate * seconds * blockAlign;
    final ByteData header = ByteData(44);

    void writeAscii(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final Uint8List out = Uint8List(44 + dataSize);
    out.setRange(0, 44, header.buffer.asUint8List());
    return out;
  }
}
