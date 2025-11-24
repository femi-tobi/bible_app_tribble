import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/bible_provider.dart';

class PresentationScreen extends StatelessWidget {
  const PresentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bibleProvider = context.watch<BibleProvider>();
    final response = bibleProvider.currentResponse;

    if (response == null) {
      return const Scaffold(
        body: Center(child: Text('No verse selected')),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.pop(context);
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          context.read<BibleProvider>().nextVerse();
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          context.read<BibleProvider>().previousVerse();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      response.reference,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF03DAC6),
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Text(
                      response.text,
                      style: const TextStyle(
                        fontSize: 64,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Georgia', // Serif looks better for scripture
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeIn(
                    delay: const Duration(milliseconds: 1000),
                    child: Text(
                      response.translationName,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
