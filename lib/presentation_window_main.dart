import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/ghs_provider.dart';
import 'providers/presentation_config_provider.dart';
import 'screens/ghs_presentation_screen.dart';
import 'screens/bible_presentation_screen.dart';
import 'screens/sermon_presentation_screen.dart';
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
    for (int i = 1; i <= 3; i++) {
      Future.delayed(Duration(milliseconds: 300 * i), () {
        try {
          print('Attempting to apply frameless style (Attempt $i)...');
          WindowsWindowService.makeWindowFrameless(windowId);
        } catch (e) {
          print('Error applying frameless style: $e');
        }
      });
    }
  }

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
    String type = 'hymn';
    dynamic data;
    
    if (args.length > 1) {
      try {
        final jsonStr = args[1];
        print('Parsing args[1]: ${jsonStr.substring(0, jsonStr.length > 50 ? 50 : jsonStr.length)}...');
        
        final parsed = jsonDecode(jsonStr);
        
        if (parsed is Map && parsed.containsKey('type') && parsed.containsKey('data')) {
          type = parsed['type'];
          data = parsed['data'];
          print('Detected presentation type: $type');
        } else {
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
              final hymnData = Map<String, dynamic>.from(data);
              if (hymnData.containsKey('config')) {
                hymnData.remove('config');
              }
              final hymn = Hymn.fromJson(hymnData);
              provider.setCurrentHymnDirect(hymn);
            } catch (e) {
              print('Error setting hymn data: $e');
            }
          }
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => PresentationConfigProvider()),
      ],
      child: MaterialApp(
        title: type == 'hymn' ? 'GHS Presentation' : type == 'bible' ? 'Bible Presentation' : 'Sermon Presentation',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF1E1E1E),
          scaffoldBackgroundColor: Colors.black,
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
        home: type == 'hymn' 
            ? GhsPresentationScreen(data: data ?? {})
            : type == 'bible'
              ? BiblePresentationScreen(data: data)
              : SermonPresentationScreen(data: data),
      ),
    );
  }
}
