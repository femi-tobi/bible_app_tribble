import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart' as dmw;
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import '../models/presentation_config.dart';
import '../widgets/ndi_wrapper.dart';
import '../services/verse_splitter.dart';

class BiblePresentationScreen extends StatefulWidget {
  final dynamic data;

  const BiblePresentationScreen({
    super.key,
    required this.data,
  });

  @override
  State<BiblePresentationScreen> createState() => _BiblePresentationScreenState();
}

class _BiblePresentationScreenState extends State<BiblePresentationScreen> {
  final FocusNode _focusNode = FocusNode();
  String _bookName = '';
  int _chapter = 0;
  int _verse = 0;
  String _text = '';
  PresentationConfig _config = PresentationConfig();
  
  // Verse splitting support
  List<VersePart> _verseParts = [];
  int _currentPartIndex = 0;

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
    dmw.DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'update_verse') {
        final verseData = call.arguments as Map;
        setState(() {
          _bookName = verseData['book'] ?? '';
          _chapter = verseData['chapter'] ?? 0;
          _verse = verseData['verse'] ?? 0;
          _text = verseData['text'] ?? '';
          _currentPartIndex = 0;
          _verseParts = []; // Reset to trigger re-split in didChangeDependencies
        });
        print('Updated verse: $_bookName $_chapter:$_verse');
      } else if (call.method == 'next_part') {
        _nextPart();
      } else if (call.method == 'previous_part') {
        _previousPart();
      } else if (call.method == 'init_config') {
        final configData = call.arguments as Map;
        setState(() {
          try {
            _config = PresentationConfig.fromMap(Map<String, dynamic>.from(configData));
            print('Config updated: scale=${_config.scale}');
          } catch (e) {
            print('Error updating config: $e');
          }
        });
      }
      return null;
    });
  }

  void _parseData() {
    print('BiblePresentationScreen: Parsing data...');
    print('Data type: ${widget.data.runtimeType}');
    print('Data: ${widget.data}');
    
    if (widget.data != null && widget.data is Map) {
      final map = widget.data as Map;
      _bookName = map['book'] ?? '';
      _chapter = map['chapter'] ?? 0;
      _verse = map['verse'] ?? 0;
      _text = map['text'] ?? '';
      
      if (map['config'] != null && map['config'] is Map) {
        try {
          _config = PresentationConfig.fromMap(Map<String, dynamic>.from(map['config']));
          print('Config loaded: scale=${_config.scale}, bg=${_config.backgroundColor}');
        } catch (e) {
          print('Error parsing config: $e');
        }
      }
      
      print('Parsed - Book: $_bookName, Chapter: $_chapter, Verse: $_verse');
      print('Text length: ${_text.length}');
      print('Text preview: ${_text.substring(0, _text.length > 50 ? 50 : _text.length)}...');
    } else {
      print('ERROR: Data is null or not a Map!');
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Split verse here where MediaQuery is available
    if (_text.isNotEmpty && _verseParts.isEmpty) {
      _splitVerse();
    }
  }

  
  void _splitVerse() {
    if (_text.isEmpty) {
      _verseParts = [];
      return;
    }
    
    // Get screen size for splitting calculation
    final size = MediaQuery.of(context).size;
    _verseParts = VerseSplitter.splitVerse(
      text: _text,
      screenWidth: size.width,
      screenHeight: size.height,
      fontSize: 72, // Base verse font size
      scale: _config.scale,
    );
    
    print('Verse split into ${_verseParts.length} parts');
  }
  
  void _nextPart() {
    if (_currentPartIndex < _verseParts.length - 1) {
      setState(() {
        _currentPartIndex++;
      });
      print('Next part: $_currentPartIndex/${_verseParts.length}');
    }
  }
  
  void _previousPart() {
    if (_currentPartIndex > 0) {
      setState(() {
        _currentPartIndex--;
      });
      print('Previous part: $_currentPartIndex/${_verseParts.length}');
    }
  }
  
  String _getCurrentText() {
    if (_verseParts.isEmpty) return _text;
    return _verseParts[_currentPartIndex].text;
  }
  
  String _getVerseLabel() {
    if (_verseParts.isEmpty || _verseParts.length == 1) {
      return '$_bookName $_chapter:$_verse';
    }
    final part = _verseParts[_currentPartIndex];
    return '$_bookName $_chapter:$_verse${part.label}';
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return Scaffold(
        backgroundColor: _config.backgroundColor,
        body: Container(
          decoration: _config.backgroundImagePath != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(_config.backgroundImagePath!)),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: const Center(
            child: Text('No data', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }

    Widget Function(Widget, Animation<double>) transitionBuilder;
    
    switch (_config.animation) {
      case PresentationAnimation.none:
        transitionBuilder = (child, animation) {
          return child;
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
      streamName: 'Bible App - Scripture',
      enabled: _config.enableNdi,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            // ESC just closes the window, no message to main
          },
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
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Column(
                      key: ValueKey('$_bookName$_chapter:$_verse:$_currentPartIndex'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          child: Text(
                            _getVerseLabel(),
                            style: TextStyle(
                              color: _config.referenceColor,
                              fontSize: 48 * _config.scale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Flexible(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            child: Text(
                              _getCurrentText(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _config.verseColor,
                                fontSize: 72 * _config.scale,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                                letterSpacing: 1,
                              ),
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
        ),
      ),
    );
  }
}
