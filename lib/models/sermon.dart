class SermonPoint {
  String id;
  String text;
  List<String> subPoints;

  SermonPoint({
    required this.id,
    required this.text,
    List<String>? subPoints,
  }) : subPoints = subPoints ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'subPoints': subPoints,
    };
  }

  factory SermonPoint.fromMap(Map<String, dynamic> map) {
    return SermonPoint(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      subPoints: List<String>.from(map['subPoints'] ?? []),
    );
  }
}

class Sermon {
  String topic;
  String bibleText;
  List<SermonPoint> points;

  Sermon({
    this.topic = '',
    this.bibleText = '',
    List<SermonPoint>? points,
  }) : points = points ?? [];

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'bibleText': bibleText,
      'points': points.map((p) => p.toMap()).toList(),
    };
  }

  factory Sermon.fromMap(Map<String, dynamic> map) {
    return Sermon(
      topic: map['topic'] ?? '',
      bibleText: map['bibleText'] ?? '',
      points: List<SermonPoint>.from(
        (map['points'] ?? []).map((x) => SermonPoint.fromMap(x)),
      ),
    );
  }
}
