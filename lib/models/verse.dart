class BibleResponse {
  final String reference;
  final List<Verse> verses;
  final String text;
  final String translationName;

  BibleResponse({
    required this.reference,
    required this.verses,
    required this.text,
    required this.translationName,
  });

  factory BibleResponse.fromJson(Map<String, dynamic> json) {
    return BibleResponse(
      reference: json['reference'] ?? '',
      verses: (json['verses'] as List?)
              ?.map((v) => Verse.fromJson(v))
              .toList() ??
          [],
      text: json['text'] ?? '',
      translationName: json['translation_name'] ?? '',
    );
  }
}

class Verse {
  final String bookName;
  final int chapter;
  final int verse;
  final String text;

  Verse({
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      bookName: json['book_name'] ?? '',
      chapter: json['chapter'] ?? 0,
      verse: json['verse'] ?? 0,
      text: json['text'] ?? '',
    );
  }
}
