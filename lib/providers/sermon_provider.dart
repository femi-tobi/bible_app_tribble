import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sermon.dart';

class SermonProvider extends ChangeNotifier {
  Sermon _currentSermon = Sermon();
  final _uuid = const Uuid();

  Sermon get currentSermon => _currentSermon;

  void updateTopic(String topic) {
    _currentSermon.topic = topic;
    notifyListeners();
  }

  void updateBibleText(String text) {
    _currentSermon.bibleText = text;
    notifyListeners();
  }

  void addPoint() {
    _currentSermon.points.add(SermonPoint(
      id: _uuid.v4(),
      text: '',
    ));
    notifyListeners();
  }

  void removePoint(int index) {
    if (index >= 0 && index < _currentSermon.points.length) {
      _currentSermon.points.removeAt(index);
      notifyListeners();
    }
  }

  void updatePointText(int index, String text) {
    if (index >= 0 && index < _currentSermon.points.length) {
      _currentSermon.points[index].text = text;
      notifyListeners();
    }
  }

  void addSubPoint(int pointIndex) {
    if (pointIndex >= 0 && pointIndex < _currentSermon.points.length) {
      _currentSermon.points[pointIndex].subPoints.add('');
      notifyListeners();
    }
  }

  void removeSubPoint(int pointIndex, int subPointIndex) {
    if (pointIndex >= 0 && pointIndex < _currentSermon.points.length) {
      var subPoints = _currentSermon.points[pointIndex].subPoints;
      if (subPointIndex >= 0 && subPointIndex < subPoints.length) {
        subPoints.removeAt(subPointIndex);
        notifyListeners();
      }
    }
  }

  void updateSubPointText(int pointIndex, int subPointIndex, String text) {
    if (pointIndex >= 0 && pointIndex < _currentSermon.points.length) {
      var subPoints = _currentSermon.points[pointIndex].subPoints;
      if (subPointIndex >= 0 && subPointIndex < subPoints.length) {
        subPoints[subPointIndex] = text;
        notifyListeners();
      }
    }
  }

  void clearSermon() {
    _currentSermon = Sermon();
    notifyListeners();
  }
}
