import 'package:flutter/material.dart';
import '../constants/bible_data.dart';
import '../services/bible_service.dart';

class VerseGrid extends StatefulWidget {
  final BibleBook book;
  final int chapter;
  final Function(int) onVerseSelected;
  final Color? themeColor;

  const VerseGrid({
    super.key,
    required this.book,
    required this.chapter,
    required this.onVerseSelected,
    this.themeColor,
  });

  @override
  State<VerseGrid> createState() => _VerseGridState();
}

class _VerseGridState extends State<VerseGrid> {
  final BibleService _bibleService = BibleService();
  int _verseCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerseCount();
  }

  Future<void> _loadVerseCount() async {
    final count = await _bibleService.getVerseCount(widget.book.name, widget.chapter);
    if (mounted) {
      setState(() {
        _verseCount = count;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _verseCount,
      itemBuilder: (context, index) {
        final verse = index + 1;
        return InkWell(
          onTap: () => widget.onVerseSelected(verse),
          child: Container(
            decoration: BoxDecoration(
              color: widget.themeColor?.withValues(alpha: 0.6) ?? const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(
              child: Text(
                '$verse',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
