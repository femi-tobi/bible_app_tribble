class TimerConfig {
  Duration duration;
  String title;
  bool showMilliseconds;
  bool isCountUp;
  bool playAlert;
  
  TimerConfig({
    this.duration = const Duration(minutes: 5),
    this.title = '',
    this.showMilliseconds = false,
    this.isCountUp = false,
    this.playAlert = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'duration': duration.inSeconds,
      'title': title,
      'showMilliseconds': showMilliseconds,
      'isCountUp': isCountUp,
      'playAlert': playAlert,
    };
  }

  factory TimerConfig.fromMap(Map<String, dynamic> map) {
    return TimerConfig(
      duration: Duration(seconds: map['duration'] ?? 300),
      title: map['title'] ?? '',
      showMilliseconds: map['showMilliseconds'] ?? false,
      isCountUp: map['isCountUp'] ?? false,
      playAlert: map['playAlert'] ?? true,
    );
  }
  
  TimerConfig copyWith({
    Duration? duration,
    String? title,
    bool? showMilliseconds,
    bool? isCountUp,
    bool? playAlert,
  }) {
    return TimerConfig(
      duration: duration ?? this.duration,
      title: title ?? this.title,
      showMilliseconds: showMilliseconds ?? this.showMilliseconds,
      isCountUp: isCountUp ?? this.isCountUp,
      playAlert: playAlert ?? this.playAlert,
    );
  }
}
