import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';
import 'providers/bible_provider.dart';
import 'providers/ghs_provider.dart';
import 'screens/home_screen.dart';
import 'screens/ghs_presentation_screen.dart';
import 'models/hymn.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== FLUTTER APP STARTING ===');
  print('Total args: ${args.length}');
  for (int i = 0; i < args.length; i++) {
    final argPreview = args[i].length > 100 ? '${args[i].substring(0, 100)}...' : args[i];
    print('Arg[$i]: $argPreview');
  }
  
  // Check if this is a sub-window (presentation window)
  // desktop_multi_window passes args as: ['multi_window', windowId, data]
  if (args.length >= 2 && args[0] == 'multi_window') {
    final windowId = int.tryParse(args[1]);
    
    print('Desktop multi-window detected!');
    print('Window ID from args[1]: $windowId');
    
    if (windowId != null) {
      // This is a presentation window
      print('=== SUB-WINDOW DETECTED ===');
      print('Window ID: $windowId');
      print('Args count: ${args.length}');
      
      // Parse hymn data from third argument (args[2])
      Hymn? hymn;
      if (args.length > 2) {
        try {
          final jsonPreview = args[2].length > 100 ? args[2].substring(0, 100) : args[2];
          print('Hymn JSON preview: $jsonPreview...');
          final hymnJson = jsonDecode(args[2]);
          hymn = Hymn.fromJson(hymnJson);
          print('✓ Hymn parsed successfully: ${hymn.title}');
        } catch (e, stackTrace) {
          print('✗ Error parsing hymn data: $e');
          print('Stack trace: $stackTrace');
        }
      } else {
        print('✗ WARNING: No hymn data in args!');
      }
      
      print('Launching presentation window with hymn: ${hymn?.title ?? "NULL"}');
      runApp(_createPresentationWindow(windowId, hymn));
      return;
    }
  }
  
  print('=== MAIN WINDOW ===');
  
  runApp(const BibleApp());
}

// Create presentation window app
Widget _createPresentationWindow(int windowId, Hymn? hymn) {
  return ChangeNotifierProvider(
    create: (_) {
      final provider = GhsProvider();
      if (hymn != null) {
        provider.setCurrentHymnDirect(hymn);
      }
      return provider;
    },
    child: MaterialApp(
      title: 'GHS Presentation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1E1E1E),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const GhsPresentationScreen(),
    ),
  );
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BibleProvider()),
        ChangeNotifierProvider(create: (_) => GhsProvider()),
      ],
      child: MaterialApp(
        title: 'Church Bible Presenter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF1E1E1E),
          scaffoldBackgroundColor: const Color(0xFF121212),
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            secondary: Color(0xFF03DAC6),
            surface: Color(0xFF1E1E1E),
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
