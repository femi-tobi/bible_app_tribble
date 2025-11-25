import '../services/presentation_window_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  final FocusNode _keyboardFocusNode = FocusNode();
  
  bool _isListening = false;
  BibleBook? _selectedBook;
  int? _selectedChapter;
  double _previewHeight = 120.0; // Adjustable preview height


  @override
  void initState() {
    super.initState();
    _speechService.initialize();
    // Request focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    });
  }

  @override
  void dispose() {
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
  }

  void _onVerseSelected(int verse) {
    final query = '${_selectedBook!.name} $_selectedChapter:$verse';
    _searchController.text = query;
    _handleSearch();
    // Keep _selectedBook and _selectedChapter so Go Live can access them
  }

  void _toggleListening() {
    if (_isListening) {
      _speechService.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _speechService.listen((text) {
        setState(() => _isListening = false);
        _searchController.text = text;
        _handleSearch();
      });
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
      
      PresentationWindowService.openBiblePresentation(context, verseData);
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
                        color: const Color(0xFF121212),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            // Search Bar
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search (e.g. John 3:16)',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                                    color: _isListening ? Colors.red : Colors.grey,
                                    onPressed: _toggleListening,
                                  ),
                                ),
                                onSubmitted: (_) => _handleSearch(),
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
                                color: const Color(0xFF1E1E1E),
                                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                              ),
                              child: _selectedBook != null
                                  ? ChapterGrid(
                                      book: _selectedBook!,
                                      onChapterSelected: _onChapterSelected,
                                      themeColor: _selectedBook!.color,
                                    )
                                  : const Center(
                                      child: Text(
                                        'Select a Book',
                                        style: TextStyle(color: Colors.white30),
                                      ),
                                    ),
                            ),
                          ),
                          
                          // Verse Grid
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                border: Border(
                                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  left: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                              ),
                              child: _selectedBook != null && _selectedChapter != null
                                  ? VerseGrid(
                                      book: _selectedBook!,
                                      chapter: _selectedChapter!,
                                      onVerseSelected: _onVerseSelected,
                                      themeColor: _selectedBook!.color,
                                    )
                                  : const Center(
                                      child: Text(
                                        'Select a Chapter',
                                        style: TextStyle(color: Colors.white30),
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
                    color: const Color(0xFF1E1E1E),
                    border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    children: [
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
                          ],
                        ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ShortcutBadge(label: 'R'),
                                    const SizedBox(width: 2),
                                    _ShortcutBadge(label: 'F5'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
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
                          ],
                        ),
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
                                            color: isSelected ? const Color(0xFF2C2C2C) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: isSelected ? Border.all(color: const Color(0xFF03DAC6), width: 1) : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${verse.verse}',
                                                style: TextStyle(
                                                  color: isSelected ? const Color(0xFF03DAC6) : Colors.grey,
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
                                                  color: isSelected ? Colors.white : Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Text(
                                      'Select a verse to preview',
                                      style: TextStyle(color: Colors.white30),
                                    ),
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
