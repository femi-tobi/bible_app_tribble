import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import '../models/presentation_config.dart';
import '../models/sermon.dart';

import '../widgets/ndi_wrapper.dart';

class SermonPresentationScreen extends StatefulWidget {
  final dynamic data;

  const SermonPresentationScreen({
    super.key,
    required this.data,
  });

  @override
  State<SermonPresentationScreen> createState() => _SermonPresentationScreenState();
}

class _SermonPresentationScreenState extends State<SermonPresentationScreen> {
  final FocusNode _focusNode = FocusNode();
  Sermon _sermon = Sermon();
  PresentationConfig _config = PresentationConfig();
  List<_SermonSlide> _slides = [];
  int _currentSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _parseData();
    _prepareSlides();
    _setupMessageHandler();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _parseData() {
    if (widget.data != null && widget.data is Map) {
      final map = widget.data as Map;
      
      // Parse config if present
      if (map['config'] != null && map['config'] is Map) {
        try {
          _config = PresentationConfig.fromMap(Map<String, dynamic>.from(map['config']));
        } catch (e) {
          print('Error parsing config: $e');
        }
      }

      // Parse sermon
      try {
        // Remove config before parsing sermon
        final sermonData = Map<String, dynamic>.from(map);
        sermonData.remove('config');
        _sermon = Sermon.fromMap(sermonData);
      } catch (e) {
        print('Error parsing sermon: $e');
      }
    }
  }

  void _prepareSlides() {
    _slides = [];

    // Title Slide
    _slides.add(_SermonSlide(
      type: _SlideType.title,
      content: _sermon.topic,
      subContent: _sermon.bibleText,
    ));

    // Points
    for (var point in _sermon.points) {
      // Main Point Slide
      _slides.add(_SermonSlide(
        type: _SlideType.point,
        content: point.text,
      ));

      // Sub-points (accumulative or single? Let's do single for now for simplicity, or maybe list)
      // Let's show the main point as header and sub-point as content
      for (var subPoint in point.subPoints) {
        _slides.add(_SermonSlide(
          type: _SlideType.subPoint,
          content: point.text, // Header
          subContent: subPoint, // The sub-point
        ));
      }
    }
  }

  void _setupMessageHandler() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'navigate_slide') {
        final direction = call.arguments as String;
        if (direction == 'next') {
          _nextSlide();
        } else if (direction == 'previous') {
          _previousSlide();
        }
      } else if (call.method == 'init_config') {
        final configData = call.arguments as Map;
        setState(() {
          try {
            _config = PresentationConfig.fromMap(Map<String, dynamic>.from(configData));
          } catch (e) {
            print('Error updating config: $e');
          }
        });
      } else if (call.method == 'update_sermon') {
        final sermonData = call.arguments as Map;
        setState(() {
          try {
            // Remove config if present
            if (sermonData.containsKey('config')) {
              sermonData.remove('config');
            }
            
            _sermon = Sermon.fromMap(Map<String, dynamic>.from(sermonData));
            _currentSlideIndex = 0;
            _prepareSlides();
            print('Sermon updated: ${_sermon.topic}');
          } catch (e) {
            print('Error updating sermon: $e');
          }
        });
      }
      return null;
    });
  }

  void _nextSlide() {
    if (_currentSlideIndex < _slides.length - 1) {
      setState(() => _currentSlideIndex++);
    }
  }

  void _previousSlide() {
    if (_currentSlideIndex > 0) {
      setState(() => _currentSlideIndex--);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) {
      return Scaffold(
        backgroundColor: _config.backgroundColor,
        body: const Center(child: Text('No content', style: TextStyle(color: Colors.white))),
      );
    }

    final currentSlide = _slides[_currentSlideIndex];

    return NdiWrapper(
      streamName: 'Bible App - Sermon',
      enabled: _config.enableNdi,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            // Close handled by main app or window manager
          },
          const SingleActivator(LogicalKeyboardKey.arrowRight): _nextSlide,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _previousSlide,
          const SingleActivator(LogicalKeyboardKey.space): _nextSlide,
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
              child: Padding(
                padding: const EdgeInsets.all(60.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _buildSlideContent(currentSlide),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSlideContent(_SermonSlide slide) {
    switch (slide.type) {
      case _SlideType.title:
        return Column(
          key: ValueKey(_currentSlideIndex),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              child: Text(
                slide.content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _config.referenceColor, // Use reference color for topic
                  fontSize: 72 * _config.scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (slide.subContent != null && slide.subContent!.isNotEmpty) ...[
              const SizedBox(height: 40),
              FadeInUp(
                child: Text(
                  slide.subContent!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _config.verseColor,
                    fontSize: 48 * _config.scale,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        );
      case _SlideType.point:
        return Center(
          key: ValueKey(_currentSlideIndex),
          child: FadeIn(
            child: Text(
              slide.content,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _config.verseColor,
                fontSize: 64 * _config.scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case _SlideType.subPoint:
        return Column(
          key: ValueKey(_currentSlideIndex),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slide.content, // Main point as header
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _config.referenceColor.withOpacity(0.7),
                fontSize: 40 * _config.scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            FadeInUp(
              child: Text(
                slide.subContent ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _config.verseColor,
                  fontSize: 56 * _config.scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
    }
  }
}

enum _SlideType { title, point, subPoint }

class _SermonSlide {
  final _SlideType type;
  final String content;
  final String? subContent;

  _SermonSlide({
    required this.type,
    required this.content,
    this.subContent,
  });
}
