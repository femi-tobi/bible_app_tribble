import 'package:flutter/material.dart';
import '../constants/bible_data.dart';

class ChapterGrid extends StatelessWidget {
  final BibleBook book;
  final Function(int) onChapterSelected;
  final Color? themeColor;

  const ChapterGrid({
    super.key,
    required this.book,
    required this.onChapterSelected,
    this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: book.chapters,
      itemBuilder: (context, index) {
        final chapter = index + 1;
        return InkWell(
          onTap: () => onChapterSelected(chapter),
          child: Container(
            decoration: BoxDecoration(
              color: themeColor?.withValues(alpha: 0.8) ?? const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(
              child: Text(
                '$chapter',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
