import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:animate_do/animate_do.dart';

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

  @override
  void initState() {
    super.initState();
    _parseData();
    _setupMessageHandler();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
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
      
      print('Parsed - Book: $_bookName, Chapter: $_chapter, Verse: $_verse');
      print('Text length: ${_text.length}');
      print('Text preview: ${_text.substring(0, _text.length > 50 ? 50 : _text.length)}...');
    } else {
      print('ERROR: Data is null or not a Map!');
    }
  }

  void _setupMessageHandler() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'navigate_slide') {
        final direction = call.arguments as String;
        if (direction == 'next') {
          // Navigation handled by main app's BibleProvider
        } else if (direction == 'previous') {
          // Navigation handled by main app's BibleProvider
        }
      } else if (call.method == 'update_verse') {
        // Update the verse display with new data
        final verseData = call.arguments as Map;
        setState(() {
          _bookName = verseData['book'] ?? '';
          _chapter = verseData['chapter'] ?? 0;
          _verse = verseData['verse'] ?? 0;
          _text = verseData['text'] ?? '';
        });
        print('Updated verse: $_bookName $_chapter:$_verse');
      }
      return null;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No data', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          // Close handled by main app
        },
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onHorizontalDragEnd: (details) {
              // Swipe gestures - but Bible navigation is handled by main app
              // This is just for visual feedback if needed
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
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
                  },
                  child: Column(
                    key: ValueKey('$_bookName$_chapter:$_verse'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reference Label
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          '$_bookName $_chapter:$_verse',
                          style: const TextStyle(
                            color: Color(0xFF03DAC6),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Verse Text
                      Flexible(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: Text(
                            _text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
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
    );
  }
}
