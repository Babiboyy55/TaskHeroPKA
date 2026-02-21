import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Wraps the browser MediaRecorder API for microphone capture.
/// Returns WebM/Opus audio bytes suitable for Deepgram STT.
class WebAudioRecorder {
  web.MediaRecorder? _recorder;
  web.MediaStream? _stream;
  final List<web.Blob> _chunks = [];
  Completer<Uint8List?>? _stopCompleter;

  /// Start recording from the microphone.
  /// Returns `true` if recording started, `false` if permission denied.
  Future<bool> startRecording() async {
    _chunks.clear();
    print('[WebAudioRecorder] Starting recording...');

    try {
      final constraints = web.MediaStreamConstraints(
        audio: true.toJS,
      );

      _stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;
      
      print('[WebAudioRecorder] Microphone access granted');

      _recorder = web.MediaRecorder(
        _stream!,
        web.MediaRecorderOptions(mimeType: 'audio/webm;codecs=opus'),
      );
      
      print('[WebAudioRecorder] MediaRecorder created with MIME: audio/webm;codecs=opus');

      // Collect audio chunks
      _recorder!.ondataavailable = ((web.BlobEvent event) {
        final blob = event.data;
        print('[WebAudioRecorder] Data chunk received: ${blob.size} bytes');
        if (blob.size > 0) {
          _chunks.add(blob);
        }
      }).toJS;

      // When recording stops, combine chunks and resolve completer
      _recorder!.onstop = ((web.Event _) {
        print('[WebAudioRecorder] Recording stopped, processing ${_chunks.length} chunks');
        _resolveStopCompleter();
      }).toJS;

      // Start recording with 250ms timeslice
      _recorder!.start(250);
      print('[WebAudioRecorder] Recording started successfully');
      return true;
    } catch (e) {
      print('[WebAudioRecorder] ERROR: startRecording failed: $e');
      return false;
    }
  }

  /// Stop recording and return the captured audio as a Uint8List.
  Future<Uint8List?> stopRecording() async {
    if (_recorder == null || _recorder!.state != 'recording') {
      return null;
    }

    _stopCompleter = Completer<Uint8List?>();

    // Stop the recorder (triggers onstop handler)
    _recorder!.stop();

    // Stop all media stream tracks
    if (_stream != null) {
      final tracks = _stream!.getTracks().toDart;
      for (final track in tracks) {
        track.stop();
      }
    }

    return _stopCompleter!.future;
  }

  void _resolveStopCompleter() async {
    print('[WebAudioRecorder] Resolving stop completer with ${_chunks.length} chunks');
    
    if (_chunks.isEmpty) {
      print('[WebAudioRecorder] WARNING: No chunks captured, returning null');
      _stopCompleter?.complete(null);
      return;
    }

    try {
      // Combine chunks into a single blob
      final blobParts = _chunks.map((c) => c as JSAny).toList();
      final combined = web.Blob(
        blobParts.toJS,
        web.BlobPropertyBag(type: 'audio/webm'),
      );
      
      print('[WebAudioRecorder] Combined blob size: ${combined.size} bytes');

      // Read blob as ArrayBuffer via FileReader
      final reader = web.FileReader();
      final readerCompleter = Completer<Uint8List?>();

      reader.onloadend = ((web.Event _) {
        final result = reader.result;
        if (result != null && result.isA<JSArrayBuffer>()) {
          final arrayBuffer = result as JSArrayBuffer;
          final bytes = arrayBuffer.toDart.asUint8List();
          print('[WebAudioRecorder] Successfully converted to ${bytes.length} bytes');
          readerCompleter.complete(bytes);
        } else {
          print('[WebAudioRecorder] ERROR: FileReader result is null or not ArrayBuffer');
          readerCompleter.complete(null);
        }
      }).toJS;

      reader.onerror = ((web.Event _) {
        print('[WebAudioRecorder] ERROR: FileReader error occurred');
        readerCompleter.complete(null);
      }).toJS;

      reader.readAsArrayBuffer(combined);

      final bytes = await readerCompleter.future;
      _stopCompleter?.complete(bytes);
    } catch (e) {
      print('[WebAudioRecorder] ERROR: resolve error: $e');
      _stopCompleter?.complete(null);
    }
  }

  void dispose() {
    if (_recorder != null && _recorder!.state == 'recording') {
      _recorder!.stop();
    }
    if (_stream != null) {
      final tracks = _stream!.getTracks().toDart;
      for (final track in tracks) {
        track.stop();
      }
    }
    _recorder = null;
    _stream = null;
    _chunks.clear();
  }
}
