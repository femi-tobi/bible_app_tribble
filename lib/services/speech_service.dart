import 'dart:async';
import 'dart:typed_data';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:record/record.dart';
import 'model_loader_service.dart';

class SpeechService {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  final ModelLoaderService _modelLoader = ModelLoaderService();
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isAvailable = false;
  bool _isExplicitlyStopped = false;
  Function(String)? _onResultCallback;
  
  Model? _model;
  Recognizer? _recognizer;
  StreamSubscription<Uint8List>? _audioSubscription;

  Future<bool> initialize() async {
    try {
      // Load the model
      final modelPath = await _modelLoader.loadModel();
      if (modelPath == null) {
        print('Failed to load Vosk model');
        return false;
      }

      // Create model and recognizer
      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );

      _isAvailable = true;
      print('Vosk initialized successfully');
      return true;
    } catch (e) {
      print('Speech initialization error: $e');
      return false;
    }
  }

  void listen(Function(String) onResult) async {
    _onResultCallback = onResult;
    _isExplicitlyStopped = false;
    
    if (_isAvailable && _recognizer != null) {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      // Check microphone permission
      if (!await _recorder.hasPermission()) {
        print('Microphone permission denied');
        return;
      }

      // Start recording with stream
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      print('Vosk listening started');

      // Process audio stream
      _audioSubscription = stream.listen(
        (audioData) async {
          if (_recognizer != null && !_isExplicitlyStopped) {
            try {
              final resultReady = await _recognizer!.acceptWaveformBytes(audioData);
              
              if (resultReady) {
                final result = await _recognizer!.getResult();
                final text = _extractText(result);
                if (text.isNotEmpty && _onResultCallback != null) {
                  _onResultCallback!(text);
                }
              } else {
                final partial = await _recognizer!.getPartialResult();
                final text = _extractText(partial);
                if (text.isNotEmpty && _onResultCallback != null) {
                  _onResultCallback!(text);
                }
              }
            } catch (e) {
              print('Error processing audio: $e');
            }
          }
        },
        onError: (error) {
          print('Audio stream error: $error');
          if (!_isExplicitlyStopped) {
            _restartListening();
          }
        },
        onDone: () {
          print('Audio stream done');
          if (!_isExplicitlyStopped) {
            _restartListening();
          }
        },
      );
    } catch (e) {
      print('Error starting Vosk listen: $e');
      if (!_isExplicitlyStopped) {
        _restartListening();
      }
    }
  }

  String _extractText(String jsonResult) {
    try {
      // Vosk returns JSON like {"text": "hello world"}
      final match = RegExp(r'"text"\s*:\s*"([^"]*)"').firstMatch(jsonResult);
      return match?.group(1) ?? '';
    } catch (e) {
      return '';
    }
  }

  void _restartListening() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isExplicitlyStopped && _recognizer != null) {
        _startListening();
      }
    });
  }

  Future<void> stop() async {
    _isExplicitlyStopped = true;
    _onResultCallback = null;
    await _audioSubscription?.cancel();
    await _recorder.stop();
    print('Vosk stopped');
  }

  bool get isListening => _audioSubscription != null && !_isExplicitlyStopped;

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }
}
