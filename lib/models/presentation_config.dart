import 'package:flutter/material.dart';

enum PresentationAnimation { none, fade, slide, zoom }

class PresentationConfig {
  double scale;
  Color backgroundColor;
  Color referenceColor;
  Color verseColor;
  PresentationAnimation animation;

  String? backgroundImagePath;
  bool enableNdi;

  PresentationConfig({
    this.scale = 1.0,
    this.backgroundColor = Colors.black,
    this.referenceColor = const Color(0xFF03DAC6),
    this.verseColor = Colors.white,
    this.animation = PresentationAnimation.none,
    this.backgroundImagePath,
    this.enableNdi = true,
  });

  Map<String, dynamic> toMap() => {
        'scale': scale,
        'backgroundColor': backgroundColor.value,
        'referenceColor': referenceColor.value,
        'verseColor': verseColor.value,
        'animation': animation.index,
        'backgroundImagePath': backgroundImagePath,
        'enableNdi': enableNdi,
      };

  factory PresentationConfig.fromMap(Map<String, dynamic> map) =>
      PresentationConfig(
        scale: (map['scale'] as num).toDouble(),
        backgroundColor: Color(map['backgroundColor'] as int),
        referenceColor: Color(map['referenceColor'] as int),
        verseColor: Color(map['verseColor'] as int),
        animation: PresentationAnimation.values[map['animation'] as int],
        backgroundImagePath: map['backgroundImagePath'] as String?,
        enableNdi: map['enableNdi'] as bool? ?? true,
      );
}
