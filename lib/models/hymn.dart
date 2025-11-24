class Hymn {
  final int number;
  final String title;
  final List<String> verses;
  final String? chorus;

  Hymn({
    required this.number,
    required this.title,
    required this.verses,
    this.chorus,
  });

  factory Hymn.fromJson(Map<String, dynamic> json) {
    // Parse number - it comes as a String in the JSON
    final numberValue = json['number'];
    final int hymnNumber = numberValue is int ? numberValue : int.parse(numberValue.toString());
    
    // Parse chorus - it can be false or a String
    final chorusValue = json['chorus'];
    final String? hymnChorus = (chorusValue == false || chorusValue == null) ? null : chorusValue.toString();
    
    return Hymn(
      number: hymnNumber,
      title: json['title'] as String,
      verses: (json['verses'] as List<dynamic>)
          .where((v) => v != null && v.toString().trim().isNotEmpty)
          .map((v) => v.toString())
          .toList(),
      chorus: hymnChorus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'verses': verses,
      'chorus': chorus,
    };
  }
}

class HymnResponse {
  final Hymn hymn;

  HymnResponse({required this.hymn});

  factory HymnResponse.fromJson(Map<String, dynamic> json) {
    return HymnResponse(
      hymn: Hymn.fromJson(json),
    );
  }
}
