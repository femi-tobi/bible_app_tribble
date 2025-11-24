import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'providers/bible_provider.dart';
import 'providers/ghs_provider.dart';
import 'screens/home_screen.dart';
import 'screens/ghs_presentation_screen.dart';
import 'models/hymn.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if this is a sub-window (presentation window)
  if (args.firstOrNull != null && int.tryParse(args.first) != null) {
    // This is a presentation window
    final windowId = int.parse(args.first);
    
    // Parse hymn data from second argument
    Hymn? hymn;
    if (args.length > 1) {
      try {
        final hymnJson = jsonDecode(args[1]);
        hymn = Hymn.fromJson(hymnJson);
      } catch (e) {
        print('Error parsing hymn data: $e');
      }
    }
    
    runApp(_createPresentationWindow(windowId, hymn));
    return;
  }
  
  // Initialize window manager for desktop platforms (main window)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
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
