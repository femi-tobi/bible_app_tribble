import 'package:flutter/material.dart';

class BibleBook {
  final String name;
  final String abbreviation;
  final int chapters;
  final Color color;

  const BibleBook({
    required this.name,
    required this.abbreviation,
    required this.chapters,
    required this.color,
  });
}

class BibleData {
  // Colors based on literary type (Law, History, Poetry, etc.)
  static const Color lawColor = Color(0xFF8D6E63); // Brown
  static const Color historyColor = Color(0xFFFFA726); // Orange
  static const Color poetryColor = Color(0xFFEF5350); // Red
  static const Color prophetsColor = Color(0xFFAB47BC); // Purple
  static const Color gospelsColor = Color(0xFF42A5F5); // Blue
  static const Color lettersColor = Color(0xFF66BB6A); // Green
  static const Color prophecyColor = Color(0xFFD4E157); // Lime

  static const List<BibleBook> books = [
    // Old Testament
    BibleBook(name: 'Genesis', abbreviation: 'gn', chapters: 50, color: lawColor),
    BibleBook(name: 'Exodus', abbreviation: 'ex', chapters: 40, color: lawColor),
    BibleBook(name: 'Leviticus', abbreviation: 'lv', chapters: 27, color: lawColor),
    BibleBook(name: 'Numbers', abbreviation: 'nm', chapters: 36, color: lawColor),
    BibleBook(name: 'Deuteronomy', abbreviation: 'dt', chapters: 34, color: lawColor),
    
    BibleBook(name: 'Joshua', abbreviation: 'js', chapters: 24, color: historyColor),
    BibleBook(name: 'Judges', abbreviation: 'jud', chapters: 21, color: historyColor),
    BibleBook(name: 'Ruth', abbreviation: 'rt', chapters: 4, color: historyColor),
    BibleBook(name: '1 Samuel', abbreviation: '1sm', chapters: 31, color: historyColor),
    BibleBook(name: '2 Samuel', abbreviation: '2sm', chapters: 24, color: historyColor),
    BibleBook(name: '1 Kings', abbreviation: '1kgs', chapters: 22, color: historyColor),
    BibleBook(name: '2 Kings', abbreviation: '2kgs', chapters: 25, color: historyColor),
    BibleBook(name: '1 Chronicles', abbreviation: '1ch', chapters: 29, color: historyColor),
    BibleBook(name: '2 Chronicles', abbreviation: '2ch', chapters: 36, color: historyColor),
    BibleBook(name: 'Ezra', abbreviation: 'ezr', chapters: 10, color: historyColor),
    BibleBook(name: 'Nehemiah', abbreviation: 'ne', chapters: 13, color: historyColor),
    BibleBook(name: 'Esther', abbreviation: 'et', chapters: 10, color: historyColor),

    BibleBook(name: 'Job', abbreviation: 'job', chapters: 42, color: poetryColor),
    BibleBook(name: 'Psalms', abbreviation: 'ps', chapters: 150, color: poetryColor),
    BibleBook(name: 'Proverbs', abbreviation: 'prv', chapters: 31, color: poetryColor),
    BibleBook(name: 'Ecclesiastes', abbreviation: 'ec', chapters: 12, color: poetryColor),
    BibleBook(name: 'Song of Solomon', abbreviation: 'so', chapters: 8, color: poetryColor),

    BibleBook(name: 'Isaiah', abbreviation: 'is', chapters: 66, color: prophetsColor),
    BibleBook(name: 'Jeremiah', abbreviation: 'jr', chapters: 52, color: prophetsColor),
    BibleBook(name: 'Lamentations', abbreviation: 'lm', chapters: 5, color: prophetsColor),
    BibleBook(name: 'Ezekiel', abbreviation: 'ez', chapters: 48, color: prophetsColor),
    BibleBook(name: 'Daniel', abbreviation: 'dn', chapters: 12, color: prophetsColor),
    BibleBook(name: 'Hosea', abbreviation: 'ho', chapters: 14, color: prophetsColor),
    BibleBook(name: 'Joel', abbreviation: 'jl', chapters: 3, color: prophetsColor),
    BibleBook(name: 'Amos', abbreviation: 'am', chapters: 9, color: prophetsColor),
    BibleBook(name: 'Obadiah', abbreviation: 'ob', chapters: 1, color: prophetsColor),
    BibleBook(name: 'Jonah', abbreviation: 'jn', chapters: 4, color: prophetsColor),
    BibleBook(name: 'Micah', abbreviation: 'mi', chapters: 7, color: prophetsColor),
    BibleBook(name: 'Nahum', abbreviation: 'na', chapters: 3, color: prophetsColor),
    BibleBook(name: 'Habakkuk', abbreviation: 'hk', chapters: 3, color: prophetsColor),
    BibleBook(name: 'Zephaniah', abbreviation: 'zp', chapters: 3, color: prophetsColor),
    BibleBook(name: 'Haggai', abbreviation: 'hg', chapters: 2, color: prophetsColor),
    BibleBook(name: 'Zechariah', abbreviation: 'zc', chapters: 14, color: prophetsColor),
    BibleBook(name: 'Malachi', abbreviation: 'ml', chapters: 4, color: prophetsColor),

    // New Testament
    BibleBook(name: 'Matthew', abbreviation: 'mt', chapters: 28, color: gospelsColor),
    BibleBook(name: 'Mark', abbreviation: 'mk', chapters: 16, color: gospelsColor),
    BibleBook(name: 'Luke', abbreviation: 'lk', chapters: 24, color: gospelsColor),
    BibleBook(name: 'John', abbreviation: 'jo', chapters: 21, color: gospelsColor),
    BibleBook(name: 'Acts', abbreviation: 'act', chapters: 28, color: gospelsColor),

    BibleBook(name: 'Romans', abbreviation: 'rm', chapters: 16, color: lettersColor),
    BibleBook(name: '1 Corinthians', abbreviation: '1co', chapters: 16, color: lettersColor),
    BibleBook(name: '2 Corinthians', abbreviation: '2co', chapters: 13, color: lettersColor),
    BibleBook(name: 'Galatians', abbreviation: 'gl', chapters: 6, color: lettersColor),
    BibleBook(name: 'Ephesians', abbreviation: 'eph', chapters: 6, color: lettersColor),
    BibleBook(name: 'Philippians', abbreviation: 'ph', chapters: 4, color: lettersColor),
    BibleBook(name: 'Colossians', abbreviation: 'cl', chapters: 4, color: lettersColor),
    BibleBook(name: '1 Thessalonians', abbreviation: '1ts', chapters: 5, color: lettersColor),
    BibleBook(name: '2 Thessalonians', abbreviation: '2ts', chapters: 3, color: lettersColor),
    BibleBook(name: '1 Timothy', abbreviation: '1tm', chapters: 6, color: lettersColor),
    BibleBook(name: '2 Timothy', abbreviation: '2tm', chapters: 4, color: lettersColor),
    BibleBook(name: 'Titus', abbreviation: 'tt', chapters: 3, color: lettersColor),
    BibleBook(name: 'Philemon', abbreviation: 'phm', chapters: 1, color: lettersColor),
    BibleBook(name: 'Hebrews', abbreviation: 'hb', chapters: 13, color: lettersColor),
    BibleBook(name: 'James', abbreviation: 'jm', chapters: 5, color: lettersColor),
    BibleBook(name: '1 Peter', abbreviation: '1pe', chapters: 5, color: lettersColor),
    BibleBook(name: '2 Peter', abbreviation: '2pe', chapters: 3, color: lettersColor),
    BibleBook(name: '1 John', abbreviation: '1jo', chapters: 5, color: lettersColor),
    BibleBook(name: '2 John', abbreviation: '2jo', chapters: 1, color: lettersColor),
    BibleBook(name: '3 John', abbreviation: '3jo', chapters: 1, color: lettersColor),
    BibleBook(name: 'Jude', abbreviation: 'jd', chapters: 1, color: lettersColor),

    BibleBook(name: 'Revelation', abbreviation: 're', chapters: 22, color: prophecyColor),
  ];
}
