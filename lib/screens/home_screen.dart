import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/presentation_config_provider.dart';
import '../providers/theme_provider.dart';
import '../services/speech_service.dart';
import '../services/presentation_window_service.dart';
import '../constants/bible_data.dart';
import '../widgets/book_grid_item.dart';
import '../widgets/chapter_grid.dart';
import '../widgets/verse_grid.dart';
import '../widgets/presentation_settings_sheet.dart';
import 'ghs_screen.dart';
import 'sermon_editor_screen.dart';
import 'timer_editor_screen.dart';
import 'remote_control_screen.dart';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_service.dart';
import '../services/websocket_server.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  final FocusNode _keyboardFocusNode = FocusNode();
  
  // Audio Player State
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _audioAvailable = false;
  String? _currentAudioPath;
  
  bool _isListening = false;
  BibleBook? _selectedBook;
  int? _selectedChapter;
  double _previewHeight = 120.0; // Adjustable preview height


  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _initSpeechService();
    // Request focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    });

    // Listen for messages from presentation window
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      print('Received method call from presentation window: ${call.method}');
      if (call.method == 'close_presentation') {
        await PresentationWindowService.closePresentationWindow();
      } else if (call.method == 'presentation_navigate') {
        // TODO: Implement verse navigation from presentation window
        print('Navigation requested: ${call.arguments}');
      }
      return null;
    });
    
    // Listen for WebSocket commands
    _setupWebSocketListener();
  }
  
  void _setupWebSocketListener() {
    WebSocketServer.instance.commands.listen((command) {
      final cmd = command['command'] as String?;
      if (cmd == null) return;
      
      print('Received WebSocket command: $cmd');
      
      switch (cmd) {
        case 'next':
          _handleNextCommand();
          break;
        case 'previous':
          _handlePreviousCommand();
          break;
      }
    });
  }
  
  void _handleNextCommand() {
    final provider = context.read<BibleProvider>();
    if (PresentationWindowService.isPresentationActive && provider.currentResponse != null) {
      // Check if there are verse parts to navigate
      DesktopMultiWindow.invokeMethod(
        PresentationWindowService.presentationWindowId!,
        'next_part',
        null,
      );
      // If that fails, move to next verse
      provider.nextVerse();
      _updatePresentationVerse();
    }
  }
  
  void _handlePreviousCommand() {
    final provider = context.read<BibleProvider>();
    if (PresentationWindowService.isPresentationActive && provider.currentResponse != null) {
      // Check if there are verse parts to navigate
      DesktopMultiWindow.invokeMethod(
        PresentationWindowService.presentationWindowId!,
        'previous_part',
        null,
      );
      // If that fails, move to previous verse
      provider.previousVerse();
      _updatePresentationVerse();
    }
  }
  
  void _updatePresentationVerse() {
    final provider = context.read<BibleProvider>();
    if (provider.currentResponse != null) {
      final firstVerse = provider.currentResponse!.verses.first;
      PresentationWindowService.updateBibleVerse({
        'book': firstVerse.bookName,
        'chapter': firstVerse.chapter,
        'verse': firstVerse.verse,
        'text': firstVerse.text,
      });
      
      // Update WebSocket state
      WebSocketServer.instance.updateState({
        'type': 'bible',
        'book': firstVerse.bookName,
        'chapter': firstVerse.chapter,
        'verse': firstVerse.verse,
        'text': firstVerse.text,
        'part': 0,
        'totalParts': 1,
      });
    }
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  Future<void> _loadAudioForChapter(String book, int chapter) async {
    final audioPath = AudioService.getAudioPath(book, chapter);
    
    if (audioPath == null) {
      setState(() {
        _audioAvailable = false;
        _currentAudioPath = null;
      });
      return;
    }
    
    // If already loaded this file, just return
    if (_currentAudioPath == audioPath) {
      setState(() {
        _audioAvailable = true;
      });
      return;
    }
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource(audioPath.replaceFirst('assets/', '')));
      
      setState(() {
        _audioAvailable = true;
        _currentAudioPath = audioPath;
        _position = Duration.zero;
      });
      
      print('Audio loaded: $audioPath');
    } catch (e) {
      print('Error loading audio: $e');
      setState(() {
        _audioAvailable = false;
        _currentAudioPath = null;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch() {
    if (_searchController.text.isNotEmpty) {
      context.read<BibleProvider>().searchVerse(_searchController.text);
      FocusScope.of(context).unfocus();
      // Refocus keyboard listener
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    }
  }

  void _onBookSelected(BibleBook book) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = null;
    });
  }

  void _onChapterSelected(int chapter) {
    setState(() {
      _selectedChapter = chapter;
    });
    if (_selectedBook != null) {
      _loadAudioForChapter(_selectedBook!.name, chapter);
    }
  }

  void _onVerseSelected(int verse) {
    final query = '${_selectedBook!.name} $_selectedChapter:$verse';
    _searchController.text = query;
    _handleSearch();
    // Keep _selectedBook and _selectedChapter so Go Live can access them
  }

  Future<void> _initSpeechService() async {
    final available = await _speechService.initialize();
    if (available && mounted) {
      setState(() => _isListening = true);
      _speechService.listen(_processSpeechResult);
    }
  }

  void _processSpeechResult(String text) {
    if (text.isEmpty) return;
    
    // DEBUG: Print ALL recognized text
    print('🎤 VOSK RECOGNIZED: "$text"');
    
    // Normalize text
    final normalizedText = text.toLowerCase().trim();
    
    // Map spoken numbers to digits (common speech patterns)
    final numberMap = {
      'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5',
      'six': '6', 'seven': '7', 'eight': '8', 'nine': '9', 'ten': '10',
      'eleven': '11', 'twelve': '12', 'thirteen': '13', 'fourteen': '14',
      'fifteen': '15', 'sixteen': '16', 'seventeen': '17', 'eighteen': '18',
      'nineteen': '19', 'twenty': '20', 'thirty': '30', 'forty': '40',
      'fifty': '50', 'sixty': '60', 'seventy': '70', 'eighty': '80', 'ninety': '90',
    };
    
    String processedText = normalizedText;
    numberMap.forEach((word, digit) {
      processedText = processedText.replaceAll(word, digit);
    });
    
    print('🔄 PROCESSED TEXT: "$processedText"');
    
    // Check for book names
    bool foundMatch = false;
    for (final book in BibleData.books) {
      final bookName = book.name.toLowerCase();
      if (processedText.contains(bookName)) {
        print('📖 FOUND BOOK: ${book.name}');
        
        // Look for numbers after the book name
        // Pattern: book name + optional space + chapter + (optional : or space + verse)
        final pattern = RegExp('$bookName\\s*(\\d+)(?:[:\\s](\\d+))?');
        final match = pattern.firstMatch(processedText);
        
        if (match != null) {
          final chapter = match.group(1);
          final verse = match.group(2);
          
          print('✅ MATCH FOUND - Chapter: $chapter, Verse: $verse');
          
          if (chapter != null) {
            String query = '${book.name} $chapter';
            if (verse != null) {
              query += ':$verse';
            }
            
            // Only update if query is different to avoid loops
            if (_searchController.text != query) {
              print('🎯 EXECUTING COMMAND: $query');
              _searchController.text = query;
              _handleSearch();
              foundMatch = true;
              break;
            }
          }
        } else {
          print('❌ NO REGEX MATCH for pattern: $bookName\\s*(\\d+)(?:[:\\s](\\d+))?');
        }
      }
    }
    
    if (!foundMatch) {
      print('⚠️ NO BIBLE REFERENCE DETECTED in: "$text"');
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _speechService.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _speechService.listen(_processSpeechResult);
    }
  }



  void _goLive() {
    final bibleProvider = context.read<BibleProvider>();
    if (bibleProvider.currentResponse != null) {
      // Extract data from currentResponse
      final response = bibleProvider.currentResponse!;
      final firstVerse = response.verses.first;
      
      final verseData = {
        'book': firstVerse.bookName,  // Use bookName from Verse object
        'chapter': firstVerse.chapter,
        'verse': firstVerse.verse,
        'text': firstVerse.text,
      };
      
      // Get presentation config
      final configProvider = context.read<PresentationConfigProvider>();
      final config = configProvider.config.toMap();
      
      PresentationWindowService.openBiblePresentation(context, verseData, config);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a verse first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bibleProvider = context.watch<BibleProvider>();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): _goLive,
        const SingleActivator(LogicalKeyboardKey.keyR): _goLive,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selectedBook != null) {
            setState(() {
              _selectedBook = null;
              _selectedChapter = null;
            });
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          final provider = context.read<BibleProvider>();
          provider.nextVerse();
          // Send updated verse to presentation window if active
          if (PresentationWindowService.isPresentationActive && provider.currentResponse != null) {
            final firstVerse = provider.currentResponse!.verses.first;
            PresentationWindowService.updateBibleVerse({
              'book': firstVerse.bookName,
              'chapter': firstVerse.chapter,
              'verse': firstVerse.verse,
              'text': firstVerse.text,
            });
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          final provider = context.read<BibleProvider>();
          provider.previousVerse();
          // Send updated verse to presentation window if active
          if (PresentationWindowService.isPresentationActive && provider.currentResponse != null) {
            final firstVerse = provider.currentResponse!.verses.first;
            PresentationWindowService.updateBibleVerse({
              'book': firstVerse.bookName,
              'chapter': firstVerse.chapter,
              'verse': firstVerse.verse,
              'text': firstVerse.text,
            });
          }
        },
      },
      child: Focus(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              // 1. Selection Area (80%) - LEFT SIDE
              Expanded(
                flex: 8,
                child: Column(
                  children: [
                    // Top: Book Grid (50%)
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            // Search Bar
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                                        decoration: InputDecoration(
                                          hintText: 'Search (e.g. John 3:16)',
                                          hintStyle: TextStyle(color: Theme.of(context).hintColor),
                                          border: InputBorder.none,
                                          suffixIcon: IconButton(
                                            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                                            color: _isListening ? Colors.red : Theme.of(context).iconTheme.color,
                                            onPressed: _toggleListening,
                                          ),
                                        ),
                                        onSubmitted: (_) => _handleSearch(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: bibleProvider.currentVersion,
                                        dropdownColor: Theme.of(context).colorScheme.surface,
                                        items: bibleProvider.availableVersions.entries.map((entry) {
                                          return DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Text(
                                              entry.key.toUpperCase(),
                                              style: TextStyle(
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            context.read<BibleProvider>().changeVersion(newValue);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Remote Control Button
                                  Material(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RemoteControlScreen(),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.phone_android,
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Remote',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Grid
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 100,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                  childAspectRatio: 1.2,
                                ),
                                itemCount: BibleData.books.length,
                                itemBuilder: (context, index) {
                                  return BookGridItem(
                                    book: BibleData.books[index],
                                    onTap: () => _onBookSelected(BibleData.books[index]),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom: Chapter & Verse Grids (50%)
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          // Chapter Grid
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                              ),
                              child: _selectedBook != null
                                  ? ChapterGrid(
                                      book: _selectedBook!,
                                      onChapterSelected: _onChapterSelected,
                                      themeColor: _selectedBook!.color,
                                    )
                                  : Center(
                                      child: Text(
                                        'Select a Book',
                                        style: TextStyle(color: Theme.of(context).hintColor),
                                      ),
                                    ),
                            ),
                          ),
                          
                          // Verse Grid
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border(
                                  top: BorderSide(color: Theme.of(context).dividerColor),
                                  left: BorderSide(color: Theme.of(context).dividerColor),
                                ),
                              ),
                              child: _selectedBook != null && _selectedChapter != null
                                  ? VerseGrid(
                                      book: _selectedBook!,
                                      chapter: _selectedChapter!,
                                      onVerseSelected: _onVerseSelected,
                                      themeColor: _selectedBook!.color,
                                    )
                                  : Center(
                                      child: Text(
                                        'Select a Chapter',
                                        style: TextStyle(color: Theme.of(context).hintColor),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Verse Text Sidebar (20%) - RIGHT SIDE
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Column(
                    children: [
                      // GHS, Sermon, and Settings Buttons - Always visible
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const GhsScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  backgroundColor: const Color(0xFF03DAC6),
                                  foregroundColor: Colors.black,
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'GHS',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SermonEditorScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'Sermon',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TimerEditorScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'Timer',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) => SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.7,
                                    child: const PresentationSettingsSheet(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                minimumSize: Size.zero,
                              ),
                              child: const Icon(Icons.settings, size: 16),
                            ),
                            const SizedBox(width: 8),
                            // Theme Toggle Button
                            Consumer<ThemeProvider>(
                              builder: (context, themeProvider, _) {
                                return ElevatedButton(
                                  onPressed: () {
                                    themeProvider.toggleTheme();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    backgroundColor: themeProvider.isDarkMode 
                                        ? Colors.grey[800] 
                                        : const Color(0xFF6C63FF),
                                    foregroundColor: Colors.white,
                                    minimumSize: Size.zero,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return RotationTransition(
                                        turns: animation,
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      themeProvider.isDarkMode 
                                          ? Icons.light_mode 
                                          : Icons.dark_mode,
                                      key: ValueKey(themeProvider.isDarkMode),
                                      size: 16,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Presentation Preview
                      if (bibleProvider.currentResponse != null)
                        Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(8),
                              height: _previewHeight,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF03DAC6).withValues(alpha: 0.3)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    // Preview content
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              bibleProvider.currentResponse!.reference,
                                              style: const TextStyle(
                                                color: Color(0xFF03DAC6),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Flexible(
                                              child: Text(
                                                bibleProvider.currentResponse!.text,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  height: 1.2,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // "LIVE" indicator if presentation is active
                                    if (PresentationWindowService.isPresentationActive)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Resize slider
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.photo_size_select_small, size: 12, color: Colors.white30),
                                  Expanded(
                                    child: Slider(
                                      value: _previewHeight,
                                      min: 80,
                                      max: 300,
                                      divisions: 22,
                                      activeColor: const Color(0xFF03DAC6),
                                      inactiveColor: Colors.white12,
                                      onChanged: (value) {
                                        setState(() {
                                          _previewHeight = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const Icon(Icons.photo_size_select_large, size: 16, color: Colors.white30),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),

                      // List
                      Expanded(
                        child: bibleProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : bibleProvider.currentResponse != null
                                ? ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: bibleProvider.currentChapterVerses.length,
                                    itemBuilder: (context, index) {
                                      final verse = bibleProvider.currentChapterVerses[index];
                                      final isSelected = verse.verse == bibleProvider.currentResponse!.verses.first.verse;
                                      
                                      return GestureDetector(
                                        onDoubleTap: _goLive,
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: isSelected 
                                                ? Border.all(color: Theme.of(context).colorScheme.secondary, width: 1) 
                                                : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${verse.verse}',
                                                style: TextStyle(
                                                  color: isSelected 
                                                      ? Theme.of(context).colorScheme.secondary 
                                                      : Theme.of(context).hintColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                verse.text,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1.5,
                                                  color: isSelected 
                                                      ? Theme.of(context).textTheme.bodyLarge?.color 
                                                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      'Select a verse to preview',
                                      style: TextStyle(color: Theme.of(context).hintColor),
                                    ),
                                  ),
                      ),
                      // Audio Player Controls
                      if (_audioAvailable)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      if (_isPlaying) {
                                        await _audioPlayer.pause();
                                      } else {
                                        await _audioPlayer.resume();
                                      }
                                    },
                                    icon: Icon(
                                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                      size: 32,
                                      color: const Color(0xFF03DAC6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Audio Bible',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 10,
                                          ),
                                        ),
                                        Text(
                                          '${_selectedBook?.name ?? ''} $_selectedChapter',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_position),
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                  activeTrackColor: const Color(0xFF03DAC6),
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: const Color(0xFF03DAC6),
                                ),
                                child: Slider(
                                  value: _duration.inMilliseconds > 0
                                      ? _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble())
                                      : 0,
                                  max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1,
                                  onChanged: (value) async {
                                    final position = Duration(milliseconds: value.toInt());
                                    await _audioPlayer.seek(position);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      // Go Live Button
                      if (bibleProvider.currentResponse != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _goLive,
                            icon: const Icon(Icons.tv),
                            label: const Text('GO LIVE'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutBadge extends StatelessWidget {
  final String label;

  const _ShortcutBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
