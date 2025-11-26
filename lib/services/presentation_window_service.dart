import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '../models/hymn.dart';
import 'windows_window_service.dart';

class PresentationWindowService {
  static int? _presentationWindowId;

  static Future<void> openFullscreenPresentation(
    BuildContext context,
    Hymn hymn,
    Map<String, dynamic> config,
  ) async {
    // Include config in hymn data
    final hymnData = hymn.toJson();
    hymnData['config'] = config;
    await _createWindow(context, hymnData, 'hymn');
  }

  static Future<void> openBiblePresentation(
    BuildContext context,
    Map<String, dynamic> verseData,
    Map<String, dynamic> config,
  ) async {
    // Include config in verse data
    final dataWithConfig = Map<String, dynamic>.from(verseData);
    dataWithConfig['config'] = config;
    await _createWindow(context, dataWithConfig, 'bible');
  }

  static Future<void> _createWindow(
    BuildContext context,
    dynamic data,
    String type,
  ) async {
    // Get available displays
    final displays = await ScreenRetriever.instance.getAllDisplays();
    
    // Find external display (usually the second one)
    Display? targetDisplay;
    if (displays.length > 1) {
      targetDisplay = displays[1]; // Use second display
    } else {
      targetDisplay = displays[0]; // Fallback to primary
    }
    
    print('=== Display Detection ===');
    print('Total displays found: ${displays.length}');
    for (int i = 0; i < displays.length; i++) {
      print('Display $i: ID=${displays[i].id}, Size=${displays[i].size.width}x${displays[i].size.height}');
    }
    print('Selected external display: ID=${targetDisplay.id}');

    // Close existing window if open
    if (_presentationWindowId != null) {
      try {
        await WindowController.fromWindowId(_presentationWindowId!).close();
      } catch (e) {
        print('Error closing existing window: $e');
      }
    }

    try {
      // Create new window for presentation
      // Pass type as first arg, data as second
      // desktop_multi_window passes: ['multi_window', windowId, args...]
      final window = await DesktopMultiWindow.createWindow(jsonEncode({
        'type': type,
        'data': data,
      }));
      
      // Get window controller
      final windowController = WindowController.fromWindowId(window.windowId);
      
      // Position and size window on target display
      final rect = Offset(
        targetDisplay.visiblePosition!.dx,
        targetDisplay.visiblePosition!.dy,
      ) & Size(
        targetDisplay.size.width,
        targetDisplay.size.height,
      );
      
      // Configure window for presentation
      await windowController.setFrame(rect);
      await windowController.setTitle(type == 'hymn' ? 'GHS Presentation' : 'Bible Presentation');
      await windowController.show();
      
      // Apply fullscreen on Windows to cover taskbar (includes making frameless)
      // Apply fullscreen on Windows to cover taskbar (includes making frameless)
      // NOTE: We now handle this inside the secondary window's main() using window_manager
      /*
      if (Platform.isWindows) {
        try {
          await WindowsWindowService.makeWindowFullscreen(
            window.windowId,
            rect.left.toInt(),
            rect.top.toInt(),
            rect.width.toInt(),
            rect.height.toInt(),
          );
        } catch (e) {
          print('Error applying fullscreen: $e');
        }
      }
      */
      
      print('Presentation window created: ID=${window.windowId}');
      print('Window positioned at: ${rect.left}, ${rect.top}');
      print('Window size: ${rect.width} x ${rect.height}');
      print('========================');
      
      // Store window ID for later communication
      _presentationWindowId = window.windowId;
      
    } catch (e) {
      print('Error creating presentation window: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open presentation window: $e')),
      );
    }
  }

  static Future<void> sendNavigationCommand(String direction) async {
    if (_presentationWindowId != null) {
      try {
        await DesktopMultiWindow.invokeMethod(
          _presentationWindowId!,
          'navigate_slide',
          direction,
        );
      } catch (e) {
        print('Error sending navigation command: $e');
      }
    }
  }

  static Future<void> updateBibleVerse(Map<String, dynamic> verseData) async {
    if (_presentationWindowId != null) {
      try {
        await DesktopMultiWindow.invokeMethod(
          _presentationWindowId!,
          'update_verse',
          verseData,
        );
      } catch (e) {
        print('Error updating Bible verse: $e');
      }
    }
  }

  static Future<void> sendConfig(Map<String, dynamic> config) async {
    if (_presentationWindowId != null) {
      try {
        await DesktopMultiWindow.invokeMethod(
          _presentationWindowId!,
          'init_config',
          config,
        );
      } catch (e) {
        print('Error sending config: $e');
      }
    }
  }

  static Future<void> closePresentationWindow() async {
    if (_presentationWindowId != null) {
      try {
        final windowController = WindowController.fromWindowId(_presentationWindowId!);
        await windowController.close();
      } catch (e) {
        print('Error closing presentation window: $e');
      } finally {
        // Always reset window ID, even if close fails
        _presentationWindowId = null;
      }
    }
  }

  static bool get isPresentationActive => _presentationWindowId != null;
}
