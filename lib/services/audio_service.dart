class AudioService {
  // Map book names to their audio folder numbers and names
  static const Map<String, String> _bookToFolderName = {
    'Genesis': '01 Genesis',
    'Exodus': '02 Exodus',
    'Leviticus': '03 Leviticus',
    'Numbers': '04 Numbers',
    'Deuteronomy': '05 Deuteronomy',
    'Joshua': '06 Joshua',
    'Judges': '07 Judges',
    'Ruth': '08 Ruth',
    '1 Samuel': '09 I Samuel',
    '2 Samuel': '10 II Samuel',
    '1 Kings': '11 I Kings',
    '2 Kings': '12 II Kings',
    '1 Chronicles': '13 I Chronicles',
    '2 Chronicles': '14 II Chronicles',
    'Ezra': '15 Ezra',
    'Nehemiah': '16 Nehemiah',
    'Esther': '17 Esther',
    'Job': '18 Job',
    'Psalms': '19 Psalms',
    'Proverbs': '20 Proverbs',
    'Ecclesiastes': '21 Ecclesiastes',
    'Song of Solomon': '22 Solomon',
    'Isaiah': '23 Isaiah',
    'Jeremiah': '24 Jeremiah',
    'Lamentations': '25 Lamentations',
    'Ezekiel': '26 Ezekiel',
    'Daniel': '27 Daniel',
    'Hosea': '28 Hosea',
    'Joel': '29 Joel',
    'Amos': '30 Amos',
    'Obadiah': '31 Obadiah',
    'Jonah': '32 Jonah',
    'Micah': '33 Micah',
    'Nahum': '34 Nahum',
    'Habakkuk': '35 Habakkuk',
    'Zephaniah': '36 Zephaniah',
    'Haggai': '37 Haggai',
    'Zechariah': '38 Zechariah',
    'Malachi': '39 Malachi',
    'Matthew': '40 Matthew',
    'Mark': '41 Mark',
    'Luke': '42 Luke',
    'John': '43 John',
    'Acts': '44 Acts',
    'Romans': '45 Romans',
    '1 Corinthians': '46 I Corinthians',
    '2 Corinthians': '47 II Corinthians',
    'Galatians': '48 Galatians',
    'Ephesians': '49 Ephesians',
    'Philippians': '50 Philippians',
    'Colossians': '51 Colossians',
    '1 Thessalonians': '52 I Thessalonians',
    '2 Thessalonians': '53 II Thessalonians',
    '1 Timothy': '54 I Timothy',
    '2 Timothy': '55 II Timothy',
    'Titus': '56 Titus',
    'Philemon': '57 Philemon',
    'Hebrews': '58 Hebrews',
    'James': '59 James',
    '1 Peter': '60 I Peter',
    '2 Peter': '61 II Peter',
    '1 John': '62 I John',
    '2 John': '63 II John',
    '3 John': '64 III John',
    'Jude': '65 Jude',
    'Revelation': '66 Revelation',
  };

  /// Get the audio file path for a specific book and chapter
  /// Returns null if the book is not found
  static String? getAudioPath(String bookName, int chapter) {
    final folderName = _bookToFolderName[bookName];
    if (folderName == null) {
      print('Audio folder not found for book: $bookName');
      return null;
    }

    // Format chapter number with leading zeros (001, 002, etc.)
    final chapterStr = chapter.toString().padLeft(3, '0');
    
    // Build path: assets/Audio Bible/## BookName/## BookName ###.mp3
    final path = 'assets/Audio Bible/$folderName/$folderName $chapterStr.mp3';
    
    return path;
  }

  /// Check if audio is available for a book
  static bool hasAudio(String bookName) {
    return _bookToFolderName.containsKey(bookName);
  }

  /// Get the folder name for a book (for debugging)
  static String? getFolderName(String bookName) {
    return _bookToFolderName[bookName];
  }
}
