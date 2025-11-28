import 'dart:convert';
import 'package:flutter/services.dart';
import '../constants/bible_data.dart';
import '../models/verse.dart';

class BibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  Map<String, dynamic>? _bibleData;
  String _currentVersion = 'kjv';

  String get currentVersion => _currentVersion;

  final Map<String, String> availableVersions = {
    'kjv': 'King James Version',
    'niv': 'New International Version',
    'akjv': 'American King James Version',
    'nlv': 'New Life Version',
  };

  Future<void> loadBible([String? version]) async {
    if (version != null) {
      _currentVersion = version.toLowerCase();
      _bibleData = null; // Force reload if version changes
    }
    
    if (_bibleData != null) return;

    String filename;
    switch (_currentVersion) {
      case 'niv':
        filename = 'NIV_bible.json';
        break;
      case 'akjv':
        filename = 'AKJV_bible.json';
        break;
      case 'nlv':
        filename = 'NLV_bible.json';
        break;
      case 'kjv':
      default:
        filename = 'kjv.json';
        break;
    }

    try {
      final String response = await rootBundle.loadString('assets/$filename');
      _bibleData = json.decode(response);
    } catch (e) {
      print('Error loading Bible version $_currentVersion: $e');
      if (_currentVersion != 'kjv') {
        print('Falling back to KJV');
        _currentVersion = 'kjv';
        await loadBible();
      }
    }
  }

  Future<void> changeVersion(String version) async {
    if (availableVersions.containsKey(version.toLowerCase())) {
      await loadBible(version);
    } else {
      throw Exception('Bible version $version not supported');
    }
  }

  Future<BibleResponse> getVerses(String reference) async {
    await loadBible(); // Ensure data is loaded

    if (_bibleData == null) {
      throw Exception('Bible data not loaded');
    }

    final RegExp regex = RegExp(r'^(\d?\s?[a-zA-Z\s]+)\s+(\d+):(\d+(?:-\d+)?)$');
    final match = regex.firstMatch(reference);

    if (match == null) {
      throw Exception('Invalid reference format: $reference');
    }

    String bookName = match.group(1)!.trim();
    final int chapter = int.parse(match.group(2)!);
    final String verseRange = match.group(3)!;

    final bibleBook = BibleData.books.firstWhere(
      (b) => b.name.toLowerCase() == bookName.toLowerCase() || 
             b.abbreviation.toLowerCase() == bookName.toLowerCase(),
      orElse: () => throw Exception('Book not found: $bookName'),
    );
    
    // Use the canonical name from BibleData
    bookName = bibleBook.name;

    dynamic bookData = _bibleData![bookName];
    if (bookData == null) {
       final key = _bibleData!.keys.firstWhere(
         (k) => k.toLowerCase() == bookName.toLowerCase(),
         orElse: () => '',
       );
       if (key.isNotEmpty) {
         bookData = _bibleData![key];
       }
    }

    if (bookData == null) {
      throw Exception('Book data not found for: $bookName');
    }

    final chapterData = bookData[chapter.toString()];
    if (chapterData == null) {
      throw Exception('Chapter $chapter not found in $bookName');
    }

    List<Verse> verses = [];
    String fullText = '';

    if (verseRange.contains('-')) {
      final parts = verseRange.split('-');
      final start = int.parse(parts[0]);
      final end = int.parse(parts[1]);
      
      for (int i = start; i <= end; i++) {
        final verseText = chapterData[i.toString()];
        if (verseText != null) {
          verses.add(Verse(
            bookName: bookName,
            chapter: chapter,
            verse: i,
            text: verseText.toString(),
          ));
          fullText += '${i > start ? " " : ""}${verseText.toString()}';
        }
      }
    } else {
      final verseNum = int.parse(verseRange);
      final verseText = chapterData[verseRange];
      if (verseText != null) {
        verses.add(Verse(
          bookName: bookName,
          chapter: chapter,
          verse: verseNum,
          text: verseText.toString(),
        ));
        fullText = verseText.toString();
      }
    }

    if (verses.isEmpty) {
      throw Exception('Verses not found for reference: $reference');
    }

    return BibleResponse(
      reference: reference,
      verses: verses,
      text: fullText,
      translationName: availableVersions[_currentVersion] ?? _currentVersion.toUpperCase(),
    );
  }

  Future<List<Verse>> getChapter(String bookName, int chapter) async {
    await loadBible();

    if (_bibleData == null) throw Exception('Bible data not loaded');

    final bibleBook = BibleData.books.firstWhere(
      (b) => b.name.toLowerCase() == bookName.toLowerCase() || 
             b.abbreviation.toLowerCase() == bookName.toLowerCase(),
      orElse: () => throw Exception('Book not found: $bookName'),
    );
    
    bookName = bibleBook.name;

    dynamic bookData = _bibleData![bookName];
    if (bookData == null) {
       final key = _bibleData!.keys.firstWhere(
         (k) => k.toLowerCase() == bookName.toLowerCase(),
         orElse: () => '',
       );
       if (key.isNotEmpty) {
         bookData = _bibleData![key];
       }
    }

    if (bookData == null) throw Exception('Book data not found');

    final chapterData = bookData[chapter.toString()];
    if (chapterData == null) throw Exception('Chapter not found');

    List<Verse> verses = [];
    if (chapterData is Map) {
      // Sort keys to ensure verses are in order
      final sortedKeys = chapterData.keys.map((k) => int.parse(k.toString())).toList()..sort();
      
      for (var key in sortedKeys) {
        verses.add(Verse(
          bookName: bookName,
          chapter: chapter,
          verse: key,
          text: chapterData[key.toString()].toString(),
        ));
      }
    }

    return verses;
  }

  Future<int> getVerseCount(String bookName, int chapter) async {
    await loadBible();
    
    if (_bibleData == null) return 0;

    final bibleBook = BibleData.books.firstWhere(
      (b) => b.name.toLowerCase() == bookName.toLowerCase() || 
             b.abbreviation.toLowerCase() == bookName.toLowerCase(),
      orElse: () => throw Exception('Book not found: $bookName'),
    );
    
    bookName = bibleBook.name;

    dynamic bookData = _bibleData![bookName];
    if (bookData == null) {
       final key = _bibleData!.keys.firstWhere(
         (k) => k.toLowerCase() == bookName.toLowerCase(),
         orElse: () => '',
       );
       if (key.isNotEmpty) {
         bookData = _bibleData![key];
       }
    }

    if (bookData == null) return 0;

    final chapterData = bookData[chapter.toString()];
    if (chapterData == null) return 0;

    if (chapterData is Map) {
      return chapterData.length;
    }
    return 0;
  }
}
