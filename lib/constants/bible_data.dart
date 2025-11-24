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
    BibleBook(name: 'Genesis', abbreviation: 'Gn', chapters: 50, color: lawColor),
    BibleBook(name: 'Exodus', abbreviation: 'Ex', chapters: 40, color: lawColor),
    BibleBook(name: 'Leviticus', abbreviation: 'Lv', chapters: 27, color: lawColor),
    BibleBook(name: 'Numbers', abbreviation: 'Nm', chapters: 36, color: lawColor),
    BibleBook(name: 'Deuteronomy', abbreviation: 'Dt', chapters: 34, color: lawColor),
    
    BibleBook(name: 'Joshua', abbreviation: 'Jos', chapters: 24, color: historyColor),
    BibleBook(name: 'Judges', abbreviation: 'Jg', chapters: 21, color: historyColor),
    BibleBook(name: 'Ruth', abbreviation: 'Ru', chapters: 4, color: historyColor),
    BibleBook(name: '1 Samuel', abbreviation: '1Sm', chapters: 31, color: historyColor),
    BibleBook(name: '2 Samuel', abbreviation: '2Sm', chapters: 24, color: historyColor),
    BibleBook(name: '1 Kings', abbreviation: '1Ki', chapters: 22, color: historyColor),
    BibleBook(name: '2 Kings', abbreviation: '2Ki', chapters: 25, color: historyColor),
    BibleBook(name: '1 Chronicles', abbreviation: '1Ch', chapters: 29, color: historyColor),
    BibleBook(name: '2 Chronicles', abbreviation: '2Ch', chapters: 36, color: historyColor),
    BibleBook(name: 'Ezra', abbreviation: 'Ezr', chapters: 10, color: historyColor),
    BibleBook(name: 'Nehemiah', abbreviation: 'Ne', chapters: 13, color: historyColor),
    BibleBook(name: 'Esther', abbreviation: 'Es', chapters: 10, color: historyColor),

    BibleBook(name: 'Job', abbreviation: 'Jb', chapters: 42, color: poetryColor),
    BibleBook(name: 'Psalms', abbreviation: 'Ps', chapters: 150, color: poetryColor),
    BibleBook(name: 'Proverbs', abbreviation: 'Pr', chapters: 31, color: poetryColor),
    BibleBook(name: 'Ecclesiastes', abbreviation: 'Ec', chapters: 12, color: poetryColor),
    BibleBook(name: 'Song of Solomon', abbreviation: 'So', chapters: 8, color: poetryColor),

    BibleBook(name: 'Isaiah', abbreviation: 'Is', chapters: 66, color: prophetsColor),
    BibleBook(name: 'Jeremiah', abbreviation: 'Jr', chapters: 52, color: prophetsColor),
    BibleBook(name: 'Lamentations', abbreviation: 'La', chapters: 5, color: prophetsColor),
    BibleBook(name: 'Ezekiel', abbreviation: 'Eze', chapters: 48, color: prophetsColor),
    BibleBook(name: 'Daniel', abbreviation: 'Dn', chapters: 12, color: prophetsColor),
    BibleBook(name: 'Hosea', abbreviation: 'Ho', chapters: 14, color: prophetsColor),
    BibleBook(name: 'Joel', abbreviation: 'Jl', chapters: 3, color: prophetsColor),
    BibleBook(name: 'Amos', abbreviation: 'Am', chapters: 9, color: prophetsColor),
    BibleBook(name: 'Obadiah', abbreviation: 'Ob', chapters: 1, color: prophetsColor),
    BibleBook(name: 'Jonah', abbreviation: 'Jon', chapters: 4, color: prophetsColor),
    BibleBook(name: 'Micah', abbreviation: 'Mic', chapters: 7, color: prophetsColor),
    BibleBook(name: 'Nahum', abbreviation: 'Na', chapters: 3, color: prophetsColor),
    BibleBook(name: 'Habakkuk', abbreviation: 'Hab', chapters: 3, color: prophetsColor),
    BibleBook(name: 'Zephaniah', abbreviation: 'Zp', chapters: 3, color: prophetsColor),
    BibleBook(name: 'Haggai', abbreviation: 'Hg', chapters: 2, color: prophetsColor),
    BibleBook(name: 'Zechariah', abbreviation: 'Zc', chapters: 14, color: prophetsColor),
    BibleBook(name: 'Malachi', abbreviation: 'Ml', chapters: 4, color: prophetsColor),

    // New Testament
    BibleBook(name: 'Matthew', abbreviation: 'Mt', chapters: 28, color: gospelsColor),
    BibleBook(name: 'Mark', abbreviation: 'Mk', chapters: 16, color: gospelsColor),
    BibleBook(name: 'Luke', abbreviation: 'Lk', chapters: 24, color: gospelsColor),
    BibleBook(name: 'John', abbreviation: 'Jn', chapters: 21, color: gospelsColor),
    BibleBook(name: 'Acts', abbreviation: 'Ac', chapters: 28, color: gospelsColor),

    BibleBook(name: 'Romans', abbreviation: 'Rm', chapters: 16, color: lettersColor),
    BibleBook(name: '1 Corinthians', abbreviation: '1Co', chapters: 16, color: lettersColor),
    BibleBook(name: '2 Corinthians', abbreviation: '2Co', chapters: 13, color: lettersColor),
    BibleBook(name: 'Galatians', abbreviation: 'Ga', chapters: 6, color: lettersColor),
    BibleBook(name: 'Ephesians', abbreviation: 'Eph', chapters: 6, color: lettersColor),
    BibleBook(name: 'Philippians', abbreviation: 'Php', chapters: 4, color: lettersColor),
    BibleBook(name: 'Colossians', abbreviation: 'Col', chapters: 4, color: lettersColor),
    BibleBook(name: '1 Thessalonians', abbreviation: '1Th', chapters: 5, color: lettersColor),
    BibleBook(name: '2 Thessalonians', abbreviation: '2Th', chapters: 3, color: lettersColor),
    BibleBook(name: '1 Timothy', abbreviation: '1Ti', chapters: 6, color: lettersColor),
    BibleBook(name: '2 Timothy', abbreviation: '2Ti', chapters: 4, color: lettersColor),
    BibleBook(name: 'Titus', abbreviation: 'Tit', chapters: 3, color: lettersColor),
    BibleBook(name: 'Philemon', abbreviation: 'Phm', chapters: 1, color: lettersColor),
    BibleBook(name: 'Hebrews', abbreviation: 'Heb', chapters: 13, color: lettersColor),
    BibleBook(name: 'James', abbreviation: 'Jm', chapters: 5, color: lettersColor),
    BibleBook(name: '1 Peter', abbreviation: '1Pe', chapters: 5, color: lettersColor),
    BibleBook(name: '2 Peter', abbreviation: '2Pe', chapters: 3, color: lettersColor),
    BibleBook(name: '1 John', abbreviation: '1Jo', chapters: 5, color: lettersColor),
    BibleBook(name: '2 John', abbreviation: '2Jo', chapters: 1, color: lettersColor),
    BibleBook(name: '3 John', abbreviation: '3Jo', chapters: 1, color: lettersColor),
    BibleBook(name: 'Jude', abbreviation: 'Jud', chapters: 1, color: lettersColor),

    BibleBook(name: 'Revelation', abbreviation: 'Rev', chapters: 22, color: prophecyColor),
  ];
}
