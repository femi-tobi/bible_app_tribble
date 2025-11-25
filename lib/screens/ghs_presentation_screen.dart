import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/ghs_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
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
    final hymn = ghsProvider.currentHymn;

    if (hymn == null || _slides.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No hymn data',
            style: TextStyle(color: Colors.white54, fontSize: 24),
          ),
        ),
      );
    }

    final currentSlide = _slides[_currentSlideIndex];

    return CallbackShortcuts(
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
          backgroundColor: Colors.black,
          body: GestureDetector(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Section Label
                        Text(
                          currentSlide.label,
                          style: const TextStyle(
                            color: Color(0xFF03DAC6),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Content - Maximum 2 lines
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentSlide.lines.map((line) => Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text(
                                  line,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: currentSlide.isTitle ? 64 : 72,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
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
                // Close Button
                Positioned(
                  top: 30,
                  right: 30,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 36),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Press ESC to exit',
                  ),
                ),
              ],
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
