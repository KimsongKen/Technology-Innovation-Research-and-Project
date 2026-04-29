import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

typedef AudioChunkCallback = Future<void> Function(Uint8List chunk);

class AudioStreamer {
  AudioStreamer({
    this.sampleRate = 16000,
    this.numChannels = 1,
    this.chunkMs = 400,
  }) : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  final int sampleRate;
  final int numChannels;
  final int chunkMs;

  StreamSubscription<Uint8List>? _sub;
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  bool _running = false;

  int get _bytesPerChunk => ((sampleRate * chunkMs) ~/ 1000) * 2 * numChannels;

  Future<void> start({required AudioChunkCallback onChunk}) async {
    if (_running) return;
    final bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final Stream<Uint8List> stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _running = true;
    _sub = stream.listen((Uint8List bytes) async {
      _buffer.add(bytes);
      final Uint8List current = _buffer.toBytes();
      if (current.length < _bytesPerChunk) return;

      int offset = 0;
      while (offset + _bytesPerChunk <= current.length) {
        final Uint8List chunk = Uint8List.sublistView(
          current,
          offset,
          offset + _bytesPerChunk,
        );
        await onChunk(chunk);
        offset += _bytesPerChunk;
      }

      _buffer.clear();
      if (offset < current.length) {
        _buffer.add(Uint8List.sublistView(current, offset));
      }
    });
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _sub?.cancel();
    _sub = null;
    _buffer.clear();
    await _recorder.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }
}
