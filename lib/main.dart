import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:convert';
import 'providers/bible_provider.dart';
import 'providers/ghs_provider.dart';
import 'providers/presentation_config_provider.dart';
import 'screens/home_screen.dart';
import 'screens/ghs_presentation_screen.dart';
import 'screens/bible_presentation_screen.dart';
import 'models/hymn.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load presentation config
  final configProvider = PresentationConfigProvider();
  await configProvider.load();
  
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
      
      // Initialize WindowManager for this window
      await windowManager.ensureInitialized();
      
      WindowOptions windowOptions = const WindowOptions(
        size: Size(800, 600),
        center: true,
        backgroundColor: Colors.black,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.setFullScreen(true);
      });

      // Parse data from third argument (args[2])
      // The data is wrapped as: {"type":"hymn|bible","data":{...}}
      Hymn? hymn;
      Map<String, dynamic>? bibleData;
      String presentationType = '';
      
      if (args.length > 2) {
        try {
          final wrappedData = jsonDecode(args[2]);
          final type = wrappedData['type'];
          final data = wrappedData['data'];
          presentationType = type ?? '';
          
          if (type == 'hymn' && data != null) {
            hymn = Hymn.fromJson(data);
            print('✓ Hymn loaded: ${hymn.title}');
          } else if (type == 'bible' && data != null) {
            bibleData = Map<String, dynamic>.from(data);
            print('✓ Bible verse loaded: ${bibleData['book']} ${bibleData['chapter']}:${bibleData['verse']}');
          }
        } catch (e) {
          print('✗ Error parsing presentation data: $e');
        }
      }
      
      print('Launching $presentationType presentation window');
      
      if (presentationType == 'hymn') {
        runApp(_createHymnPresentationWindow(windowId, hymn));
      } else if (presentationType == 'bible') {
        runApp(_createBiblePresentationWindow(windowId, bibleData));
      }
      return;
    }
  }
  
  print('=== MAIN WINDOW ===');
  
  runApp(const BibleApp());
}

// Create hymn presentation window app
Widget _createHymnPresentationWindow(int windowId, Hymn? hymn) {
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

// Create Bible presentation window app
Widget _createBiblePresentationWindow(int windowId, Map<String, dynamic>? verseData) {
  return MaterialApp(
    title: 'Bible Presentation',
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
    home: BiblePresentationScreen(data: verseData),
  );
}
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
