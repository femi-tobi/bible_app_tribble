import 'package:flutter/material.dart';
import '../models/verse.dart';
import '../services/bible_service.dart';
import '../constants/bible_data.dart';

class BibleProvider with ChangeNotifier {
  final BibleService _bibleService = BibleService();
  
  BibleResponse? _currentResponse;
  List<Verse> _currentChapterVerses = [];
  bool _isLoading = false;
  String _error = '';

  BibleResponse? get currentResponse => _currentResponse;
  List<Verse> get currentChapterVerses => _currentChapterVerses;
  bool get isLoading => _isLoading;
  String get error => _error;

  String get currentVersion => _bibleService.currentVersion;
  Map<String, String> get availableVersions => _bibleService.availableVersions;

  Future<void> changeVersion(String version) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _bibleService.changeVersion(version);
      // Reload current verse if available
      if (_currentResponse != null) {
        await searchVerse(_currentResponse!.reference);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchVerse(String reference) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _currentResponse = await _bibleService.getVerses(reference);
      if (_currentResponse != null && _currentResponse!.verses.isNotEmpty) {
        final verse = _currentResponse!.verses.first;
        _currentChapterVerses = await _bibleService.getChapter(verse.bookName, verse.chapter);
      }
    } catch (e) {
      _error = e.toString();
      _currentResponse = null;
      _currentChapterVerses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> nextVerse() async {
    if (_currentResponse == null || _currentResponse!.verses.isEmpty) return;
    
    final currentVerse = _currentResponse!.verses.first;
    final book = BibleData.books.firstWhere((b) => b.name == currentVerse.bookName);
    
    int nextVerseNum = currentVerse.verse + 1;
    int nextChapter = currentVerse.chapter;
    String nextBookName = currentVerse.bookName;

    // Get max verses for current chapter
    int maxVerses = await _bibleService.getVerseCount(currentVerse.bookName, currentVerse.chapter);

    // Check if we need to go to next chapter
    if (nextVerseNum > maxVerses) {
      nextVerseNum = 1;
      nextChapter++;
      
      // Check if we need to go to next book
      if (nextChapter > book.chapters) {
        final currentBookIndex = BibleData.books.indexOf(book);
        if (currentBookIndex < BibleData.books.length - 1) {
          final nextBook = BibleData.books[currentBookIndex + 1];
          nextBookName = nextBook.name;
          nextChapter = 1;
        } else {
          // End of Bible
          return;
        }
      }
    }

    await searchVerse('$nextBookName $nextChapter:$nextVerseNum');
  }

  Future<void> previousVerse() async {
    if (_currentResponse == null || _currentResponse!.verses.isEmpty) return;

    final currentVerse = _currentResponse!.verses.first;
    final book = BibleData.books.firstWhere((b) => b.name == currentVerse.bookName);

    int prevVerseNum = currentVerse.verse - 1;
    int prevChapter = currentVerse.chapter;
    String prevBookName = currentVerse.bookName;

    if (prevVerseNum < 1) {
      prevChapter--;
      
      if (prevChapter < 1) {
        final currentBookIndex = BibleData.books.indexOf(book);
        if (currentBookIndex > 0) {
          final prevBook = BibleData.books[currentBookIndex - 1];
          prevBookName = prevBook.name;
          prevChapter = prevBook.chapters; // This is max chapters, which is correct
          
          // We need to know how many verses are in this last chapter of the previous book
          prevVerseNum = await _bibleService.getVerseCount(prevBookName, prevChapter);
        } else {
          // Start of Bible
          return;
        }
      } else {
        // Previous chapter in same book
        prevVerseNum = await _bibleService.getVerseCount(book.name, prevChapter);
      }
    }

    await searchVerse('$prevBookName $prevChapter:$prevVerseNum');
  }
}
