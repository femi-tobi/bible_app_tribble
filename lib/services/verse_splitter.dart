import 'package:flutter/material.dart';

class VersePart {
  final String text;
  final String label; // e.g., "a", "b", "c"
  final int partIndex;
  final int totalParts;

  VersePart({
    required this.text,
    required this.label,
    required this.partIndex,
    required this.totalParts,
  });
}

class VerseSplitter {
  /// Split verse text into multiple parts if it's too long
  /// Returns list of VersePart objects
  static List<VersePart> splitVerse({
    required String text,
    required double screenWidth,
    required double screenHeight,
    required double fontSize,
    required double scale,
  }) {
    // Calculate available space (accounting for padding)
    final availableWidth = screenWidth * 0.8; // 80% of screen width
    final availableHeight = screenHeight * 0.7; // 70% of screen height
    
    // Estimate characters per line
    final scaledFontSize = fontSize * scale;
    final charsPerLine = (availableWidth / (scaledFontSize * 0.6)).floor();
    
    // Estimate lines that fit on screen
    final lineHeight = scaledFontSize * 1.3; // line height multiplier
    final maxLines = (availableHeight / lineHeight).floor();
    
    // Calculate max characters per slide
    final maxCharsPerSlide = charsPerLine * maxLines;
    
    print('VerseSplitter: charsPerLine=$charsPerLine, maxLines=$maxLines, maxChars=$maxCharsPerSlide');
    print('VerseSplitter: text length=${text.length}');
    
    // If text fits in one slide, return as is
    if (text.length <= maxCharsPerSlide) {
      return [
        VersePart(
          text: text,
          label: '',
          partIndex: 0,
          totalParts: 1,
        ),
      ];
    }
    
    // Split text into parts
    final parts = <VersePart>[];
    final sentences = _splitIntoSentences(text);
    
    String currentPart = '';
    int partIndex = 0;
    
    for (final sentence in sentences) {
      // If adding this sentence would exceed limit, save current part
      if (currentPart.isNotEmpty && 
          (currentPart.length + sentence.length) > maxCharsPerSlide) {
        parts.add(VersePart(
          text: currentPart.trim(),
          label: _getPartLabel(partIndex),
          partIndex: partIndex,
          totalParts: 0, // Will update later
        ));
        currentPart = '';
        partIndex++;
      }
      
      currentPart += sentence;
    }
    
    // Add remaining text
    if (currentPart.isNotEmpty) {
      parts.add(VersePart(
        text: currentPart.trim(),
        label: _getPartLabel(partIndex),
        partIndex: partIndex,
        totalParts: 0,
      ));
    }
    
    // Update total parts count
    final totalParts = parts.length;
    for (int i = 0; i < parts.length; i++) {
      parts[i] = VersePart(
        text: parts[i].text,
        label: parts[i].label,
        partIndex: i,
        totalParts: totalParts,
      );
    }
    
    print('VerseSplitter: Split into ${parts.length} parts');
    return parts;
  }
  
  /// Split text into sentences at punctuation marks
  static List<String> _splitIntoSentences(String text) {
    final sentences = <String>[];
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);
      
      // Check for sentence endings
      if (char == '.' || char == ';' || char == ':' || char == '!') {
        // Look ahead to see if there's a space (not an abbreviation)
        if (i + 1 < text.length && text[i + 1] == ' ') {
          sentences.add(buffer.toString());
          buffer.clear();
        }
      }
    }
    
    // Add remaining text
    if (buffer.isNotEmpty) {
      sentences.add(buffer.toString());
    }
    
    // If no sentences found, split by words
    if (sentences.isEmpty || sentences.length == 1) {
      return _splitByWords(text, 200); // Max 200 chars per part
    }
    
    return sentences;
  }
  
  /// Fallback: split by words if sentence splitting doesn't work
  static List<String> _splitByWords(String text, int maxLength) {
    final parts = <String>[];
    final words = text.split(' ');
    final buffer = StringBuffer();
    
    for (final word in words) {
      if (buffer.length + word.length + 1 > maxLength && buffer.isNotEmpty) {
        parts.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.write('$word ');
    }
    
    if (buffer.isNotEmpty) {
      parts.add(buffer.toString().trim());
    }
    
    return parts;
  }
  
  /// Get part label (a, b, c, etc.)
  static String _getPartLabel(int index) {
    if (index < 26) {
      return String.fromCharCode(97 + index); // a-z
    } else {
      // For more than 26 parts, use aa, ab, etc.
      final first = index ~/ 26;
      final second = index % 26;
      return '${String.fromCharCode(97 + first - 1)}${String.fromCharCode(97 + second)}';
    }
  }
}
