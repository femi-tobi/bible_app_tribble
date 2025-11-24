import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/verse.dart';
import '../constants/bible_data.dart';

class BibleService {
  List<dynamic>? _bibleData;

  Future<void> loadBible() async {
    if (_bibleData != null) return;
    final String response = await rootBundle.loadString('assets/kjv.json');
    _bibleData = json.decode(response);
  }

  Future<BibleResponse> getVerses(String reference) async {
    await loadBible();

    // Parse reference (e.g., "John 3:16" or "Gn 1:1")
    // Simple parsing logic: Split by space to get book and chapter:verse
    // This is a basic implementation and might need refinement for books with numbers (1 John)
    
    String bookName = '';
    int chapter = 0;
    int verseNum = 0;
    
    // Normalize reference
    reference = reference.trim();
    
    // Regex to separate book, chapter, and verse
    // Handles "1 John 1:1", "John 3:16", "Genesis 1:1"
    final RegExp regex = RegExp(r'^(\d?\s?[a-zA-Z]+)\s+(\d+):(\d+)$');
    final match = regex.firstMatch(reference);

    if (match != null) {
      bookName = match.group(1)!.trim();
      chapter = int.parse(match.group(2)!);
      verseNum = int.parse(match.group(3)!);
    } else {
       // Fallback for just chapter selection or other formats if needed, 
       // but for now we assume full verse reference for "Go Live"
       throw Exception('Invalid reference format. Use "Book Chapter:Verse" (e.g., John 3:16)');
    }

    // Find book in JSON
    // The JSON uses abbreviations like "gn", "ex", etc.
    // We need to map the input book name to these abbreviations.
    // We can use our BibleData to find the abbreviation.
    
    final bibleBook = BibleData.books.firstWhere(
      (b) => b.name.toLowerCase() == bookName.toLowerCase() || 
             b.abbreviation.toLowerCase() == bookName.toLowerCase(),
      orElse: () => throw Exception('Book not found: $bookName'),
    );

    final bookJson = _bibleData!.firstWhere(
      (b) => b['abbrev'].toString().toLowerCase() == bibleBook.abbreviation.toLowerCase(),
      orElse: () => throw Exception('Book data not found for: ${bibleBook.name}'),
    );

    final chapters = bookJson['chapters'] as List;
    if (chapter < 1 || chapter > chapters.length) {
      throw Exception('Chapter $chapter not found in ${bibleBook.name}');
    }

    final versesList = chapters[chapter - 1] as List;
    if (verseNum < 1 || verseNum > versesList.length) {
      throw Exception('Verse $verseNum not found in ${bibleBook.name} $chapter');
    }

    final text = versesList[verseNum - 1].toString();

    final verseObj = Verse(
      bookName: bibleBook.name,
      chapter: chapter,
      verse: verseNum,
      text: text,
    );

    return BibleResponse(
      reference: reference,
      verses: [verseObj],
      text: text,
      translationName: 'KJV',
    );
  }

  Future<List<Verse>> getChapter(String bookName, int chapter) async {
    await loadBible();

    final bibleBook = BibleData.books.firstWhere(
      (b) => b.name.toLowerCase() == bookName.toLowerCase() || 
             b.abbreviation.toLowerCase() == bookName.toLowerCase(),
      orElse: () => throw Exception('Book not found: $bookName'),
    );

    final bookJson = _bibleData!.firstWhere(
      (b) => b['abbrev'].toString().toLowerCase() == bibleBook.abbreviation.toLowerCase(),
      orElse: () => throw Exception('Book data not found for: ${bibleBook.name}'),
    );

    final chapters = bookJson['chapters'] as List;
    if (chapter < 1 || chapter > chapters.length) {
      throw Exception('Chapter $chapter not found in ${bibleBook.name}');
    }

    final versesList = chapters[chapter - 1] as List;
    
    return List.generate(versesList.length, (index) {
      return Verse(
        bookName: bibleBook.name,
        chapter: chapter,
        verse: index + 1,
        text: versesList[index].toString(),
      );
    });
  }

  Future<int> getVerseCount(String bookName, int chapter) async {
    await loadBible();

    final bibleBook = BibleData.books.firstWhere(
      (b) => b.name.toLowerCase() == bookName.toLowerCase() || 
             b.abbreviation.toLowerCase() == bookName.toLowerCase(),
      orElse: () => throw Exception('Book not found: $bookName'),
    );

    final bookJson = _bibleData!.firstWhere(
      (b) => b['abbrev'].toString().toLowerCase() == bibleBook.abbreviation.toLowerCase(),
      orElse: () => throw Exception('Book data not found for: ${bibleBook.name}'),
    );

    final chapters = bookJson['chapters'] as List;
    if (chapter < 1 || chapter > chapters.length) {
      return 0;
    }

    final versesList = chapters[chapter - 1] as List;
    return versesList.length;
  }
}
