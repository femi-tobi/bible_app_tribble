import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/ghs_provider.dart';
import '../providers/presentation_config_provider.dart';
import 'dart:io';
import '../models/presentation_config.dart';
import '../models/hymn.dart';
import '../widgets/ndi_wrapper.dart';

class GhsPresentationScreen extends StatefulWidget {
  const GhsPresentationScreen({super.key});

  @override
  State<GhsPresentationScreen> createState() => _GhsPresentationScreenState();
}

class _GhsPresentationScreenState extends State<GhsPresentationScreen> {
  int _currentSlideIndex = 0;
  final FocusNode _focusNode = FocusNode();
  List<_HymnSlide> _slides = [];

  @override
  void initState() {
    super.initState();
    _prepareSlides();
    _setupMessageHandler();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
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
        // Update config via provider
        final configData = call.arguments as Map;
        try {
          context.read<PresentationConfigProvider>().loadFromMap(Map<String, dynamic>.from(configData));
          print('GHS Config updated via provider');
        } catch (e) {
          print('Error updating GHS config: $e');
        }
      } else if (call.method == 'update_hymn') {
        final hymnData = call.arguments as Map;
        try {
          // Remove config if present
          if (hymnData.containsKey('config')) {
            hymnData.remove('config');
          }
          
          final hymn = Hymn.fromJson(Map<String, dynamic>.from(hymnData));
          context.read<GhsProvider>().setCurrentHymnDirect(hymn);
          
          // Re-prepare slides
          setState(() {
            _currentSlideIndex = 0;
            _prepareSlides();
          });
          print('GHS Hymn updated: ${hymn.title}');
        } catch (e) {
          print('Error updating hymn: $e');
        }
      }
      return null;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _prepareSlides() {
    final ghsProvider = context.read<GhsProvider>();
    final hymn = ghsProvider.currentHymn;
    if (hymn == null) return;

    _slides = [];

    // Title slide
    _slides.add(_HymnSlide(
      label: 'GHS #${hymn.number}',
      lines: [hymn.title],
      isTitle: true,
    ));

    // Prepare chorus slides if chorus exists
    List<_HymnSlide> chorusSlides = [];
    if (hymn.chorus != null && hymn.chorus!.isNotEmpty) {
      final chorusLines = hymn.chorus!.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      for (int j = 0; j < chorusLines.length; j += 2) {
        final chunk = chorusLines.skip(j).take(2).toList();
        final slideNumber = (j ~/ 2) + 1;
        final totalSlides = (chorusLines.length / 2).ceil();
        
        chorusSlides.add(_HymnSlide(
          label: 'Chorus${totalSlides > 1 ? ' ($slideNumber/$totalSlides)' : ''}',
          lines: chunk,
          isTitle: false,
        ));
      }
    }

    // Process each verse and add chorus after each verse (if it exists)
    for (int i = 0; i < hymn.verses.length; i++) {
      final verse = hymn.verses[i];
      final lines = verse.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      // Split verse into chunks of 2 lines
      for (int j = 0; j < lines.length; j += 2) {
        final chunk = lines.skip(j).take(2).toList();
        final slideNumber = (j ~/ 2) + 1;
        final totalSlides = (lines.length / 2).ceil();
        
        _slides.add(_HymnSlide(
          label: 'Verse ${i + 1}${totalSlides > 1 ? ' ($slideNumber/$totalSlides)' : ''}',
          lines: chunk,
          isTitle: false,
        ));
      }

      // Add chorus after each verse (if it exists)
      if (chorusSlides.isNotEmpty) {
        _slides.addAll(chorusSlides);
      }
    }
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
  Widget build(BuildContext context) {
    final ghsProvider = context.watch<GhsProvider>();
    final configProvider = context.watch<PresentationConfigProvider>();
    final config = configProvider.config;
    final hymn = ghsProvider.currentHymn;

    if (hymn == null || _slides.isEmpty) {
      return Scaffold(
        backgroundColor: config.backgroundColor,
        body: Container(
          decoration: config.backgroundImagePath != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(config.backgroundImagePath!)),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: const Center(
            child: Text(
              'No hymn data',
              style: TextStyle(color: Colors.white54, fontSize: 24),
            ),
          ),
        ),
      );
    }

    final currentSlide = _slides[_currentSlideIndex];

    // Determine animation widget based on config
    Widget Function(Widget, Animation<double>) transitionBuilder;
    
    switch (config.animation) {
      case PresentationAnimation.none:
        transitionBuilder = (child, animation) {
          return child; // No animation, instant transition
        };
        break;
      case PresentationAnimation.fade:
        transitionBuilder = (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        };
        break;
      case PresentationAnimation.slide:
        transitionBuilder = (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        };
        break;
      case PresentationAnimation.zoom:
        transitionBuilder = (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        };
        break;
    }

    return NdiWrapper(
      streamName: 'Bible App - GHS',
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            Navigator.pop(context);
          },
          const SingleActivator(LogicalKeyboardKey.arrowRight): _nextSlide,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _previousSlide,
          const SingleActivator(LogicalKeyboardKey.arrowDown): _nextSlide,
          const SingleActivator(LogicalKeyboardKey.arrowUp): _previousSlide,
          const SingleActivator(LogicalKeyboardKey.space): _nextSlide,
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Scaffold(
            backgroundColor: config.backgroundImagePath != null ? Colors.transparent : config.backgroundColor,
            body: Container(
              decoration: config.backgroundImagePath != null
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(config.backgroundImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
              child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _previousSlide();
                } else if (details.primaryVelocity! < 0) {
                  _nextSlide();
                }
              },
              child: Stack(
                children: [
                  // Main Content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: transitionBuilder,
                        child: Column(
                          key: ValueKey(_currentSlideIndex),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Section Label
                            FadeInDown(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                currentSlide.label,
                                style: TextStyle(
                                  color: config.referenceColor,
                                  fontSize: 48 * config.scale,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Content - Maximum 2 lines
                            Flexible(
                              child: FadeInUp(
                                duration: const Duration(milliseconds: 800),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: currentSlide.lines.map((line) => Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: Text(
                                        line,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: config.verseColor,
                                          fontSize: (currentSlide.isTitle ? 64 : 72) * config.scale,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Navigation Hint
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${_currentSlideIndex + 1} / ${_slides.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, color: Colors.white54, size: 20),
                        ],
                      ),
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

class _HymnSlide {
  final String label;
  final List<String> lines;
  final bool isTitle;

  _HymnSlide({
    required this.label,
    required this.lines,
    required this.isTitle,
  });
}
