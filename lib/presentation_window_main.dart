import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;
import 'providers/ghs_provider.dart';
import 'screens/ghs_presentation_screen.dart';
import 'models/hymn.dart';

/// Entry point for the presentation window
/// This runs in a separate Flutter engine instance
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Parse window arguments
  final windowId = int.parse(args.first);
  
  // Initialize window manager for this presentation window
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    
    // Wait for window to be ready, then make it fullscreen/borderless
    windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setFullScreen(true);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.show();
      await windowManager.focus();
    });
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
    // Parse hymn data from arguments
    Hymn? hymn;
    if (args.length > 1) {
      try {
        final hymnJson = jsonDecode(args[1]);
        hymn = Hymn.fromJson(hymnJson);
      } catch (e) {
        print('Error parsing hymn data: $e');
      }
    }

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
        home: PresentationWindowListener(
          windowId: windowId,
          child: const GhsPresentationScreen(),
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
