import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_config.dart';
import '../services/presentation_window_service.dart';

class TimerProvider with ChangeNotifier {
  TimerConfig _config = TimerConfig();
  Timer? _timer;
  Duration _currentDuration = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isOvertime = false;
  List<TimerConfig> _presets = [];

  TimerConfig get config => _config;
  Duration get currentDuration => _currentDuration;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isOvertime => _isOvertime;
  List<TimerConfig> get presets => _presets;

  TimerProvider() {
    _loadPresets();
  }

  void updateConfig(TimerConfig newConfig) {
    _config = newConfig;
    if (!_isRunning && !_isPaused) {
      reset();
    }
    notifyListeners();
  }

  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _isPaused = false;
    
    // If starting fresh (not resumed), set initial duration based on mode
    if (_currentDuration == Duration.zero && !_config.isCountUp) {
      _currentDuration = _config.duration;
    } else if (_currentDuration == _config.duration && _config.isCountUp) {
       _currentDuration = Duration.zero;
    }
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
    _updatePresentation();
  }

  void pause() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _isPaused = true;
    _timer?.cancel();
    notifyListeners();
    _updatePresentation();
  }

  void reset() {
    _isRunning = false;
    _isPaused = false;
    _isOvertime = false;
    _timer?.cancel();
    
    if (_config.isCountUp) {
      _currentDuration = Duration.zero;
    } else {
      _currentDuration = _config.duration;
    }
    
    notifyListeners();
    _updatePresentation();
  }

  void _tick(Timer timer) {
    if (_config.isCountUp) {
      _currentDuration += const Duration(seconds: 1);
      // Check if we reached the target duration (optional for count up, maybe just visual indication)
      if (_currentDuration >= _config.duration && !_isOvertime) {
         _isOvertime = true;
         // Play alert if enabled
         if (_config.playAlert) {
           // TODO: Trigger alert
         }
      }
    } else {
      // Countdown
      if (_currentDuration.inSeconds > 0) {
        _currentDuration -= const Duration(seconds: 1);
      } else {
        // Timer finished
        _isOvertime = true;
        // Keep counting into negative (overtime) or stop? 
        // For now let's stop at 0 and mark overtime
        pause();
        // Play alert if enabled
        if (_config.playAlert) {
           // TODO: Trigger alert
        }
      }
    }
    notifyListeners();
    _updatePresentation();
  }
  
  void _updatePresentation() {
    if (PresentationWindowService.isPresentationActive) {
      PresentationWindowService.updateTimer({
        'currentSeconds': _currentDuration.inSeconds,
        'isRunning': _isRunning,
        'isPaused': _isPaused,
        'isOvertime': _isOvertime,
      });
    }
  }

  // Presets Management
  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? presetsJson = prefs.getStringList('timer_presets');
    
    if (presetsJson != null) {
      _presets = presetsJson
          .map((json) => TimerConfig.fromMap(jsonDecode(json)))
          .toList();
      notifyListeners();
    }
  }

  Future<void> savePreset(TimerConfig preset) async {
    _presets.add(preset);
    await _savePresetsToStorage();
    notifyListeners();
  }
  
  Future<void> removePreset(int index) async {
    if (index >= 0 && index < _presets.length) {
      _presets.removeAt(index);
      await _savePresetsToStorage();
      notifyListeners();
    }
  }

  Future<void> _savePresetsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> presetsJson = _presets
        .map((config) => jsonEncode(config.toMap()))
        .toList();
    await prefs.setStringList('timer_presets', presetsJson);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
