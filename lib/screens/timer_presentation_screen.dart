import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/presentation_config.dart';
import '../models/timer_config.dart';
import '../widgets/ndi_wrapper.dart';

class TimerPresentationScreen extends StatefulWidget {
  final dynamic data;

  const TimerPresentationScreen({
    super.key,
    required this.data,
  });

  @override
  State<TimerPresentationScreen> createState() => _TimerPresentationScreenState();
}

class _TimerPresentationScreenState extends State<TimerPresentationScreen> {
  final FocusNode _focusNode = FocusNode();
  PresentationConfig _config = PresentationConfig();
  TimerConfig _timerConfig = TimerConfig();
  
  Duration _currentDuration = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isOvertime = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _parseData();
    _setupMessageHandler();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _setupMessageHandler() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'update_timer') {
        final data = call.arguments as Map;
        setState(() {
          if (data['currentSeconds'] != null) {
            _currentDuration = Duration(seconds: data['currentSeconds']);
          }
          if (data['isRunning'] != null) _isRunning = data['isRunning'];
          if (data['isPaused'] != null) _isPaused = data['isPaused'];
          if (data['isOvertime'] != null) {
             bool wasOvertime = _isOvertime;
             _isOvertime = data['isOvertime'];
             // Play alert if just transitioned to overtime and enabled
             if (!wasOvertime && _isOvertime && _timerConfig.playAlert) {
               _playAlert();
             }
          }
        });
      } else if (call.method == 'init_config') {
        final configData = call.arguments as Map;
        setState(() {
          try {
            _config = PresentationConfig.fromMap(Map<String, dynamic>.from(configData));
          } catch (e) {
            print('Error updating config: $e');
          }
        });
      } else if (call.method == 'update_timer_config') {
         final configData = call.arguments as Map;
         setState(() {
            _timerConfig = TimerConfig.fromMap(Map<String, dynamic>.from(configData));
         });
      }
      return null;
    });
  }

  void _parseData() {
    if (widget.data != null && widget.data is Map) {
      final map = widget.data as Map;
      
      // Parse presentation config
      if (map['config'] != null && map['config'] is Map) {
        try {
          _config = PresentationConfig.fromMap(Map<String, dynamic>.from(map['config']));
        } catch (e) {
          print('Error parsing config: $e');
        }
      }

      // Parse timer data
      if (map['timerConfig'] != null) {
         _timerConfig = TimerConfig.fromMap(Map<String, dynamic>.from(map['timerConfig']));
      }
      
      if (map['currentSeconds'] != null) {
        _currentDuration = Duration(seconds: map['currentSeconds']);
      }
      
      _isRunning = map['isRunning'] ?? false;
      _isPaused = map['isPaused'] ?? false;
    }
  }

  Future<void> _playAlert() async {
    try {
      // Play a default notification sound
      // You might need to add a specific sound asset later
      await _audioPlayer.play(AssetSource('sounds/timer_end.mp3'));
    } catch (e) {
      print('Error playing alert: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    String time = "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    
    if (_timerConfig.showMilliseconds) {
       // Since we only track seconds in provider for now, this will always be 00
       // To support real milliseconds, we'd need finer timer resolution
       // For now, just show .00
       time += ".00";
    }
    
    return time;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NdiWrapper(
      streamName: 'Bible App - Timer',
      enabled: _config.enableNdi,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {}, // Prevent default escape
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Scaffold(
            backgroundColor: _config.backgroundImagePath != null ? Colors.transparent : _config.backgroundColor,
            body: Container(
              decoration: _config.backgroundImagePath != null
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(_config.backgroundImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_timerConfig.title.isNotEmpty)
                      Text(
                        _timerConfig.title,
                        style: TextStyle(
                          color: _config.referenceColor,
                          fontSize: 48 * _config.scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      _formatDuration(_currentDuration),
                      style: TextStyle(
                        color: _isOvertime ? Colors.red : _config.verseColor,
                        fontSize: 120 * _config.scale,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
