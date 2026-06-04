part of '../main.dart';

// ── Kokoro on-device TTS ──────────────────────────────────────────────────

enum KokoroState { notDownloaded, downloading, initialising, ready, error }


@pragma('vm:entry-point')
void _kokoroIsolateMain(SendPort toMain) {
  final ReceivePort inbox = ReceivePort();
  toMain.send(inbox.sendPort); // handshake: give the main isolate our port

  sherpa_onnx.OfflineTts? tts;

  inbox.listen((dynamic raw) {
    if (raw is! List<dynamic>) return;
    final String cmd = raw[0] as String;

    switch (cmd) {
      // ── Initialise the TTS engine ──────────────────────────────────────
      case 'init':
        try {
          sherpa_onnx.initBindings();
          final String root = raw[1] as String;
          final String sep  = io.Platform.pathSeparator;
          tts = sherpa_onnx.OfflineTts(
            sherpa_onnx.OfflineTtsConfig(
              model: sherpa_onnx.OfflineTtsModelConfig(
                kokoro: sherpa_onnx.OfflineTtsKokoroModelConfig(
                  model:   '$root${sep}model.onnx',
                  voices:  '$root${sep}voices.bin',
                  tokens:  '$root${sep}tokens.txt',
                  dataDir: '$root${sep}espeak-ng-data',
                ),
                // Android emulator only has 2 virtual cores — cap at 1.
                numThreads: io.Platform.isAndroid ? 1 : 2,
                debug:      false,
                provider:   'cpu',
              ),
              maxNumSenetences: 1,
            ),
          );
          toMain.send(<dynamic>['ready']);
        } catch (e) {
          toMain.send(<dynamic>['error', e.toString()]);
        }

      // ── Synthesise audio (blocking FFI — safe because we are off-UI) ──
      case 'synth':
        if (tts == null) {
          toMain.send(<dynamic>['error', 'TTS not initialised']);
          return;
        }
        try {
          final String text  = raw[1] as String;
          final double spd   = raw[2] as double;
          final int    sid   = raw[3] as int;
          final sherpa_onnx.GeneratedAudio audio =
              tts!.generate(text: text, sid: sid, speed: spd);
          // Build WAV bytes here in the isolate — keeps the main thread free.
          final Uint8List wav =
              KokoroTtsService._buildWav(audio.samples, audio.sampleRate);
          toMain.send(<dynamic>['audio', wav]);
        } catch (e) {
          toMain.send(<dynamic>['error', e.toString()]);
        }

      // ── Warm-up: prime the ONNX graph, no reply needed ────────────────
      case 'warmup':
        try {
          tts?.generate(text: '.', sid: 0, speed: 1.0);
          // Result discarded — this JIT-compiles the ONNX graph so the
          // first real synthesis returns in milliseconds, not seconds.
        } catch (_) {}

      // ── Shutdown ───────────────────────────────────────────────────────
      case 'stop':
        tts?.free();
        tts = null;
        inbox.close();
    }
  });
}


class KokoroTtsService {
  // ── Public notifiers ─────────────────────────────────────────────────────

  static final ValueNotifier<KokoroState> stateNotifier =
      ValueNotifier<KokoroState>(KokoroState.notDownloaded);
  static final ValueNotifier<double> progressNotifier =
      ValueNotifier<double>(0.0);
  /// Whether Kokoro is the active voice engine. When false the app falls
  /// back to the built-in FlutterTts even if the model is downloaded.
  static final ValueNotifier<bool> enabledNotifier =
      ValueNotifier<bool>(true);
  static String? lastError;

  /// Speed slider value: 0.0 (🐢) … 1.0 (🐇). Set by [SACAAppState].
  static double speed = 0.5;

  // ── Private ───────────────────────────────────────────────────────────────

  // Background synthesis isolate
  static Isolate?     _synthIsolate;
  static SendPort?    _toIsolate;
  static ReceivePort? _fromIsolate;

  // Pending synthesis completer — only one synthesis runs at a time.
  static Completer<Uint8List>? _synthCompleter;

  /// Generation counter — incremented on every new [speak] / [stop] call.
  /// Every async step checks it before continuing so stale chains self-cancel
  /// without ever overlapping with the newly started speech.
  static int _speakGen = 0;

  static FlutterTts?  _ftts;
  static AudioPlayer? _player;

  // ── FlutterTts voice cache ────────────────────────────────────────────────
  // getVoices() is slow (platform channel round-trip).  We call it once per
  // language and cache the result so subsequent speak() calls start instantly.
  static Map<String, String>? _cachedEngVoice;
  static Map<String, String>? _cachedWrlVoice;
  static bool _fttsBaseConfigured = false;   // volume + awaitSpeakCompletion

  static const String _archiveUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/'
      'tts-models/kokoro-en-v0_19.tar.bz2';
  static const String _modelFolder = 'kokoro-en-v0_19';

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Call once at app startup.
  static Future<void> checkAndInit() async {
    try {
      final io.Directory base = await _modelDir();
      if (await _modelExists(base)) {
        await _init(base);
      } else {
        stateNotifier.value = KokoroState.notDownloaded;
      }
    } catch (e) {
      lastError = e.toString();
      stateNotifier.value = KokoroState.error;
    }
  }

  /// Pre-warm both TTS engines in the background at app startup.
  ///
  /// FlutterTts: initialises the platform engine, calls getVoices() once and
  /// caches the result — so the first real speak() call is instant.
  ///
  /// Kokoro: if the model is loaded, sends a warm-up synthesis to the isolate
  /// so the ONNX computation graph is JIT-compiled before the user reaches the
  /// voice-input section, eliminating the 2-3 second first-run delay.
  static void warmUp() {
    // FlutterTts warm-up: only run on Android.
    // On Android, getVoices() is a slow platform call that causes a 2-3 s
    // cold-start delay — pre-initialising eliminates it.
    // On Windows, the SAPI synthesizer initialises early and conflicts with
    // the audio stack when the voice section opens, so we skip it there.
    if (!kIsWeb && io.Platform.isAndroid) {
      _primeFlutterTts();
    }
    // Kokoro ONNX warm-up — only if the isolate is already running.
    if (stateNotifier.value == KokoroState.ready && _toIsolate != null) {
      try { _toIsolate!.send(<dynamic>['warmup']); } catch (_) {}
    }
  }

  /// Initialises the FlutterTts instance and applies base config so the
  /// first real speak() call doesn't pay the cold-start cost.
  ///
  /// We deliberately do NOT call _setupFttsVoice / getVoices() here.
  /// getVoices() is a slow platform call and if it runs concurrently with
  /// a real speak() that also calls getVoices() (before the cache is warm)
  /// it causes a crash on Android. The first real speak() will populate the
  /// cache; all subsequent calls are instant.
  static Future<void> _primeFlutterTts() async {
    try {
      _ftts ??= FlutterTts();
      if (!_fttsBaseConfigured) {
        await _ftts!.setVolume(1.0);
        await _ftts!.awaitSpeakCompletion(true);
        _fttsBaseConfigured = true;
      }
    } catch (_) {}
  }

  /// Download model, extract, then initialise. Safe to call multiple times.
  static Future<void> downloadAndInit() async {
    final KokoroState s = stateNotifier.value;
    if (s == KokoroState.downloading ||
        s == KokoroState.initialising ||
        s == KokoroState.ready) { return; }

    stateNotifier.value    = KokoroState.downloading;
    progressNotifier.value = 0.0;
    lastError = null;

    try {
      final io.Directory base = await _modelDir();
      await _downloadAndExtract(base);   // stream-download + decompress + untar
      stateNotifier.value = KokoroState.initialising;
      await _init(base);                 // spawn isolate, load model
    } catch (e) {
      lastError = e.toString();
      stateNotifier.value = KokoroState.error;
    }
  }

  static Future<void> _downloadAndExtract(io.Directory base) async {
    // Stream the download straight to a temp file so we never hold 326 MB of
    // compressed data in the Dart heap (a List<int> would use far more than
    // the raw byte size and risks OOM on Android).
    final io.Directory tmp = await getTemporaryDirectory();
    final io.File tmpArchive = io.File(
      '${tmp.path}${io.Platform.pathSeparator}saca_kokoro_dl.tar.bz2',
    );

    final http.Client client = http.Client();
    try {
      // ── 1. Download ───────────────────────────────────────────────────────
      final http.StreamedResponse resp =
          await client.send(http.Request('GET', Uri.parse(_archiveUrl)));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Download failed: HTTP ${resp.statusCode}');
      }

      final int total   = resp.contentLength ?? 0;
      int      received = 0;
      final io.IOSink sink = tmpArchive.openWrite();
      try {
        await for (final List<int> chunk in resp.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) progressNotifier.value = received / total;
        }
      } finally {
        await sink.close();
      }
      progressNotifier.value = 1.0;

      // ── 2. Decompress + untar from disk (low heap overhead) ───────────────
      // InputFileStream reads the .bz2 in buffered chunks from disk rather
      // than requiring the full 326 MB to be loaded into the Dart heap first.
      final InputFileStream bzStream = InputFileStream(tmpArchive.path);
      late final Archive archive;
      try {
        final List<int> tarBytes = BZip2Decoder().decodeBuffer(bzStream);
        archive = TarDecoder().decodeBytes(tarBytes);
      } finally {
        bzStream.close();
      }

      // ── 3. Write files to the documents directory ─────────────────────────
      for (final ArchiveFile entry in archive.files) {
        if (!entry.isFile) continue;
        final String outPath =
            '${base.path}${io.Platform.pathSeparator}'
            '${entry.name.replaceAll('/', io.Platform.pathSeparator)}';
        final io.File outFile = io.File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(entry.content as List<int>);
      }
    } finally {
      client.close();
      // Always clean up the temp download file.
      try { await tmpArchive.delete(); } catch (_) {}
    }
  }

  /// Spawn the background synthesis isolate and wait for it to be ready.
  static Future<void> _init(io.Directory base) async {
    stateNotifier.value = KokoroState.initialising;
    try {
      // Cleanly shut down any existing isolate.
      _shutdownIsolate();

      final String sep  = io.Platform.pathSeparator;
      final String root = '${base.path}$sep$_modelFolder';

      // Spawn the synthesis isolate.
      _fromIsolate  = ReceivePort();
      _synthIsolate = await Isolate.spawn(
        _kokoroIsolateMain,
        _fromIsolate!.sendPort,
        debugName: 'KokoroSynth',
      );

      // Handshake: wait for the isolate's SendPort, then send 'init'.
      final Completer<void> readyCompleter = Completer<void>();

      _fromIsolate!.listen((dynamic msg) {
        // ① Receive the isolate's inbox SendPort (one-time handshake).
        if (msg is SendPort) {
          _toIsolate = msg;
          _toIsolate!.send(<dynamic>['init', root]);
          return;
        }

        // ② All subsequent messages are List<dynamic>.
        if (msg is! List<dynamic>) return;
        final String kind = msg[0] as String;

        switch (kind) {
          case 'ready':
            if (!readyCompleter.isCompleted) readyCompleter.complete();

          case 'audio':
            final Completer<Uint8List>? c = _synthCompleter;
            _synthCompleter = null;
            c?.complete(msg[1] as Uint8List);

          case 'error':
            final String err = msg[1] as String;
            if (!readyCompleter.isCompleted) {
              readyCompleter.completeError(err);
            } else {
              final Completer<Uint8List>? c = _synthCompleter;
              _synthCompleter = null;
              c?.completeError(err);
            }
        }
      });

      // Wait up to 30 s for the model to load in the isolate.
      await readyCompleter.future.timeout(const Duration(seconds: 30));
      stateNotifier.value = KokoroState.ready;
      // Prime the ONNX graph immediately so first real synthesis is instant.
      try { _toIsolate!.send(<dynamic>['warmup']); } catch (_) {}
    } catch (e) {
      lastError = e.toString();
      stateNotifier.value = KokoroState.error;
    }
  }

  static void _shutdownIsolate() {
    try {
      _toIsolate?.send(<dynamic>['stop']);
    } catch (_) {}
    _synthIsolate?.kill(priority: Isolate.immediate);
    _fromIsolate?.close();
    _synthIsolate   = null;
    _toIsolate      = null;
    _fromIsolate    = null;
    _synthCompleter = null;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<void> speak(
    String text, {
    String?     preamble,
    AppLanguage language = AppLanguage.english,
  }) async {
    if (text.trim().isEmpty) return;

    // Immediately stop anything playing and claim a fresh generation token.
    // Every await below checks the token so stale chains cancel themselves.
    stop();
    final int gen = _speakGen;

    final List<String> tParts = _split(text);
    final List<String> pParts =
        preamble != null ? _split(preamble) : <String>['', ''];

    if (language == AppLanguage.warlpiri) {
      // ── Warlpiri mode ─────────────────────────────────────────────────────
      // Route through Kokoro (same neural engine as English) when ready.
      // Fall back to FlutterTts female voice only if the model isn't loaded.
      // Single synthesis call — no English prefix, no overlap possible.
      final String wrlText = <String>[pParts[1], tParts[1]]
          .where((String s) => s.isNotEmpty)
          .join('. ');
      final String toSpeak = wrlText.isNotEmpty ? wrlText : text;
      if (stateNotifier.value == KokoroState.ready &&
          _toIsolate != null &&
          enabledNotifier.value) {
        await _kokoroSpeak(toSpeak, gen, warlpiri: true);
      } else {
        await _warlpiriSpeak(toSpeak, gen);
      }
    } else {
      // ── English mode ──────────────────────────────────────────────────────
      final String engText = <String>[pParts[0], tParts[0]]
          .where((String s) => s.isNotEmpty)
          .join('. ');
      if (stateNotifier.value == KokoroState.ready &&
          _toIsolate != null &&
          enabledNotifier.value) {
        await _kokoroSpeak(engText, gen);
      } else {
        await _englishFallbackSpeak(engText, gen);
      }
    }
  }

  /// Stop any speech immediately. Invalidates all in-flight speak chains.
  static void stop() {
    ++_speakGen; // stales every in-flight generation check → silent exit

    final Completer<Uint8List>? c = _synthCompleter;
    _synthCompleter = null;
    c?.completeError('stopped');

    _player?.stop();
    _ftts?.stop();
  }

  // ── Warlpiri FlutterTts fallback (used only when Kokoro is not ready) ──────

  /// Speak [text] using a female-tuned FlutterTts voice.
  /// Only called when the Kokoro model hasn't been downloaded yet, or if
  /// Kokoro synthesis fails.  No English is played before or after.
  static Future<void> _warlpiriSpeak(String text, int gen) async {
    if (_speakGen != gen) return;
    _ftts ??= FlutterTts();
    if (!_fttsBaseConfigured) {
      await _ftts!.setVolume(1.0);
      await _ftts!.awaitSpeakCompletion(true);
      _fttsBaseConfigured = true;
    }
    if (_speakGen != gen) return;
    await _setupFttsVoice(warlpiri: true);
    if (_speakGen != gen) return;
    await _ftts!.speak(text);
  }

  // ── Kokoro neural synthesis (off-UI isolate) — English and Warlpiri ───────

  static Future<void> _kokoroSpeak(
    String text,
    int gen, {
    bool warlpiri = false,
  }) async {
    try {
      final Completer<Uint8List>? prev = _synthCompleter;
      _synthCompleter = null;
      prev?.completeError('cancelled');

      final double synthSpeed = 0.5 + speed * 1.0;

      _synthCompleter = Completer<Uint8List>();
      _toIsolate!.send(<dynamic>['synth', text, synthSpeed, 0]);

      final Uint8List wav = await _synthCompleter!.future;
      _synthCompleter = null;

      if (_speakGen != gen) return;

      _player ??= AudioPlayer();
      await _player!.stop();

      final io.Directory tmp = await getTemporaryDirectory();
      final io.File wavFile  = io.File(
        '${tmp.path}${io.Platform.pathSeparator}saca_kokoro.wav',
      );
      await wavFile.writeAsBytes(wav, flush: true);
      await _player!.play(DeviceFileSource(wavFile.absolute.path));
    } catch (e) {
      final String reason = e.toString();
      if (reason == 'stopped' || reason == 'cancelled') return;
      if (_speakGen != gen) return;
      // Use the appropriate FlutterTts fallback voice.
      if (warlpiri) {
        await _warlpiriSpeak(text, gen);
      } else {
        await _englishFallbackSpeak(text, gen);
      }
    }
  }

  // ── English FlutterTts fallback ──────────────────────────────────────────

  static Future<void> _englishFallbackSpeak(String text, int gen) async {
    if (_speakGen != gen) return;
    _ftts ??= FlutterTts();
    if (!_fttsBaseConfigured) {
      await _ftts!.setVolume(1.0);
      await _ftts!.awaitSpeakCompletion(true);
      _fttsBaseConfigured = true;
    }
    if (_speakGen != gen) return;
    await _setupFttsVoice(warlpiri: false);
    if (_speakGen != gen) return;
    await _ftts!.speak(text);
  }

  static Future<void> _setupFttsVoice({required bool warlpiri}) async {
    final double rate = warlpiri
        ? (0.20 + (0.55 - 0.20) * speed)
        : (0.26 + (0.72 - 0.26) * speed);
    await _ftts!.setSpeechRate(rate);
    await _ftts!.setPitch(warlpiri ? 1.1 : 1.0);

    // If we already have a cached voice for this language, apply it instantly
    // and skip the expensive getVoices() platform call.
    final Map<String, String>? cached = warlpiri ? _cachedWrlVoice : _cachedEngVoice;
    if (cached != null) {
      await _ftts!.setVoice(cached);
      return;
    }

    try {
      final List<dynamic>? voices = await _ftts!.getVoices;
      if (voices != null) {
        final List<String> prefs = warlpiri
            ? <String>[
                'Natasha', 'Aria',  'Jenny',  'Zira',  'Karen',
                'Catherine', 'Hazel', 'Libby', 'Susan', 'Anna', 'Samantha',
              ]
            : <String>[
                'Aria', 'Jenny', 'Zira', 'Natasha', 'Karen', 'Hazel', 'Libby',
              ];

        bool voiceSet = false;

        // Pass 1: match by preferred name.
        for (final String p in prefs) {
          final dynamic hit = voices.firstWhere(
            (dynamic v) => v['name']
                .toString()
                .toLowerCase()
                .contains(p.toLowerCase()),
            orElse: () => null,
          );
          if (hit != null) {
            final Map<String, String> chosen = <String, String>{
              'name':   hit['name'].toString(),
              'locale': hit['locale'].toString(),
            };
            await _ftts!.setVoice(chosen);
            // Cache so next call skips getVoices() entirely.
            if (warlpiri) { _cachedWrlVoice = chosen; }
            else          { _cachedEngVoice = chosen; }
            voiceSet = true;
            break;
          }
        }

        // Pass 2 (Warlpiri only): fall back to any voice the system reports as female.
        if (!voiceSet && warlpiri) {
          final dynamic female = voices.firstWhere(
            (dynamic v) {
              final String g = (v['gender'] ?? '').toString().toLowerCase();
              return g == 'female' || g == 'f';
            },
            orElse: () => null,
          );
          if (female != null) {
            final Map<String, String> chosen = <String, String>{
              'name':   female['name'].toString(),
              'locale': female['locale'].toString(),
            };
            await _ftts!.setVoice(chosen);
            _cachedWrlVoice = chosen;
          }
        }
      }
    } catch (_) {}
    await _ftts!.setLanguage(warlpiri ? 'en-AU' : 'en-US');
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  static List<String> _split(String text) {
    final int idx = text.indexOf(' / ');
    if (idx <= 0) return <String>[text.trim(), text.trim()];
    return <String>[
      text.substring(0, idx).trim(),
      text.substring(idx + 3).trim(),
    ];
  }

  static Future<io.Directory> _modelDir() async {
    // On Android we use the app-specific external storage directory
    // (/storage/emulated/0/Android/data/<pkg>/files/saca_kokoro).
    // Unlike internal app_flutter storage, this path is reachable via
    // `adb push` and USB file transfer without root, which lets you
    // pre-load the model from a laptop when the phone has no internet.
    // On all other platforms fall back to the standard documents directory.
    io.Directory? base;
    if (!kIsWeb && io.Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();

    final io.Directory dir = io.Directory(
      '${base.path}${io.Platform.pathSeparator}saca_kokoro',
    );
    await dir.create(recursive: true);
    return dir;
  }

  static Future<bool> _modelExists(io.Directory base) {
    final String sep  = io.Platform.pathSeparator;
    final String path = '${base.path}$sep$_modelFolder${sep}model.onnx';
    return io.File(path).exists();
  }

  /// Encode Float32 PCM [samples] as a 16-bit mono WAV [Uint8List].
  ///
  /// A silence header is prepended so the audio device has time to initialise
  /// before speech begins.  Windows needs ~350 ms; Android needs only ~80 ms.
  /// Without this the first syllable is cut off on the audioplayers back-end.
  ///
  /// Called from the background isolate so the main thread never does this work.
  static Uint8List _buildWav(Float32List samples, int sampleRate) {
    // Platform-appropriate silence: Windows needs longer device warm-up.
    final double silenceSec   = io.Platform.isAndroid ? 0.08 : 0.35;
    final int    silenceFrames = (sampleRate * silenceSec).round();
    final Float32List padded = Float32List(silenceFrames + samples.length);
    padded.setRange(silenceFrames, padded.length, samples);

    final Int16List pcm = Int16List(padded.length);
    for (int i = 0; i < padded.length; i++) {
      pcm[i] = (padded[i].clamp(-1.0, 1.0) * 32767).round();
    }
    final Uint8List pcmBytes = pcm.buffer.asUint8List();
    final ByteData  hdr      = ByteData(44);

    hdr.setUint32(0,  0x52494646, Endian.big);             // 'RIFF'
    hdr.setUint32(4,  36 + pcmBytes.length, Endian.little);
    hdr.setUint32(8,  0x57415645, Endian.big);             // 'WAVE'
    hdr.setUint32(12, 0x666d7420, Endian.big);             // 'fmt '
    hdr.setUint32(16, 16, Endian.little);
    hdr.setUint16(20, 1,  Endian.little);                  // PCM
    hdr.setUint16(22, 1,  Endian.little);                  // mono
    hdr.setUint32(24, sampleRate, Endian.little);
    hdr.setUint32(28, sampleRate * 2, Endian.little);      // byte rate
    hdr.setUint16(32, 2,  Endian.little);                  // block align
    hdr.setUint16(34, 16, Endian.little);                  // 16-bit
    hdr.setUint32(36, 0x64617461, Endian.big);             // 'data'
    hdr.setUint32(40, pcmBytes.length, Endian.little);

    return Uint8List.fromList(
      <int>[...hdr.buffer.asUint8List(), ...pcmBytes],
    );
  }
}
