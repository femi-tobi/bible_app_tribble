import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/presentation_config.dart';

class PresentationConfigProvider with ChangeNotifier {
  PresentationConfig _config = PresentationConfig();

  PresentationConfig get config => _config;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('presentationConfig');
    if (json != null) {
      _config = PresentationConfig.fromMap(jsonDecode(json));
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('presentationConfig', jsonEncode(_config.toMap()));
  }

  void setScale(double v) {
    _config.scale = v;
    _save();
    notifyListeners();
  }

  void setBackground(Color c) {
    _config.backgroundColor = c;
    _save();
    notifyListeners();
  }

  void setReference(Color c) {
    _config.referenceColor = c;
    _save();
    notifyListeners();
  }

  void setVerse(Color c) {
    _config.verseColor = c;
    _save();
    notifyListeners();
  }

  void setAnimation(PresentationAnimation a) {
    _config.animation = a;
    _save();
    notifyListeners();
  }
}
