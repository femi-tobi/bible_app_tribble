import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/ghs_provider.dart';
import 'screens/ghs_presentation_screen.dart';
import 'screens/bible_presentation_screen.dart';
import 'models/hymn.dart';
import 'services/windows_window_service.dart';

/// Entry point for the presentation window
/// This runs in a separate Flutter engine instance
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Parse window arguments
  final windowId = int.parse(args.first);
  
  print('Presentation window starting with ${args.length} args');
  for (int i = 0; i < args.length; i++) {
    print('Arg $i: ${args[i].substring(0, args[i].length > 100 ? 100 : args[i].length)}...');
  }
  
  // Apply native frameless style on Windows
  if (Platform.isWindows) {
    // Add a delay to ensure window is fully created and style isn't overridden
    // Retry a few times to be sure
    for (int i = 1; i <= 3; i++) {
      Future.delayed(Duration(milliseconds: 300 * i), () {
        try {
          print('Attempting to apply frameless style (Attempt $i)...');
          // On Windows, the windowId from desktop_multi_window is the HWND
          WindowsWindowService.makeWindowFrameless(windowId);
        } catch (e) {
          print('Error applying frameless style: $e');
        }
      });
    }
  }
  
  DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
    // Handle method calls from main window
    if (call.method == 'navigate_slide') {
      // Broadcast navigation event
      return true;
    }
    return null;
  });

  runApp(PresentationWindowApp(windowId: windowId, args: args));
}

class PresentationWindowApp extends StatelessWidget {
  final int windowId;
  final List<String> args;

  const PresentationWindowApp({
    super.key,
    required this.windowId,
    required this.args,
  });

  @override
  Widget build(BuildContext context) {
    // Parse arguments
    // Format: ['multi_window', windowId, jsonString]
    // jsonString structure: { 'type': 'hymn'|'bible', 'data': ... }
    
    String type = 'hymn';
    dynamic data;
    
    if (args.length > 1) {
      try {
        final jsonStr = args[1];
        print('Parsing args[1]: ${jsonStr.substring(0, jsonStr.length > 50 ? 50 : jsonStr.length)}...');
        
        // Try to parse as the new format wrapper
        final parsed = jsonDecode(jsonStr);
        
        if (parsed is Map && parsed.containsKey('type') && parsed.containsKey('data')) {
          type = parsed['type'];
          data = parsed['data'];
          print('Detected presentation type: $type');
        } else {
          // Legacy format (direct hymn JSON)
          print('Legacy format detected, assuming hymn');
          type = 'hymn';
          data = parsed;
        }
      } catch (e) {
        print('Error parsing arguments: $e');
      }
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final provider = GhsProvider();
          if (type == 'hymn' && data != null) {
            try {
              final hymn = Hymn.fromJson(data);
              provider.setCurrentHymnDirect(hymn);
            } catch (e) {
              print('Error setting hymn data: $e');
            }
          }
          return provider;
        }),
        // Add BibleProvider if needed, or pass data directly to screen
      ],
      child: MaterialApp(
        title: type == 'hymn' ? 'GHS Presentation' : 'Bible Presentation',
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
        home: PresentationWindowListener(
          windowId: windowId,
          child: type == 'hymn' 
              ? const GhsPresentationScreen()
              : BiblePresentationScreen(data: data),
        ),
      ),
    );
  }
}

/// Listens for navigation commands from the main window
class PresentationWindowListener extends StatefulWidget {
  final int windowId;
  final Widget child;

  const PresentationWindowListener({
    super.key,
    required this.windowId,
    required this.child,
  });

  @override
  State<PresentationWindowListener> createState() => _PresentationWindowListenerState();
}

class _PresentationWindowListenerState extends State<PresentationWindowListener> {
  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  void _setupListener() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'navigate_slide') {
        final direction = call.arguments as String;
        if (mounted) {
          // Trigger navigation in the presentation screen
          // This will be handled by the GhsPresentationScreen's key listener
          if (direction == 'next') {
            // Simulate right arrow key
            _simulateNavigation(true);
          } else if (direction == 'previous') {
            // Simulate left arrow key
            _simulateNavigation(false);
          }
        }
      }
      return null;
    });
  }

  void _simulateNavigation(bool forward) {
    // The GhsPresentationScreen already has navigation logic
    // We just need to trigger it through the provider
    final provider = context.read<GhsProvider>();
    if (forward) {
      provider.nextSlide();
    } else {
      provider.previousSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
