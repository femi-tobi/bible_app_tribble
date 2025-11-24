import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) {},
        onStatus: (val) {},
      );
      return _isAvailable;
    } catch (e) {
      return false;
    }
  }

  void listen(Function(String) onResult) {
    if (_isAvailable) {
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            onResult(val.recognizedWords);
          }
        },
      );
    }
  }

  void stop() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
