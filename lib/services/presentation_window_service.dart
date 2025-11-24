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
  ) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      // For mobile/web, fallback to simple navigation
      print('Multi-window not supported on this platform');
      return;
    }

    try {
      // Get all available displays
      final screens = await screenRetriever.getAllDisplays();
      
      print('=== Display Detection ===');
      print('Total displays found: ${screens.length}');
      for (int i = 0; i < screens.length; i++) {
        final screen = screens[i];
        print('Display $i: ID=${screen.id}, Size=${screen.size.width}x${screen.size.height}');
      }
      
      // Find external display (not primary)
      Display? externalDisplay;
      for (final screen in screens) {
        if (screen.id != screens.first.id) {
          externalDisplay = screen;
          print('Selected external display: ID=${screen.id}');
          break;
        }
      }

      // Use external display if available, otherwise use primary
      final targetDisplay = externalDisplay ?? screens.first;
      if (externalDisplay == null) {
        print('No external display found, using primary');
      }
      
      // Serialize hymn data to pass to new window
      final hymnJson = jsonEncode(hymn.toJson());
      
      // Create new window for presentation
      final window = await DesktopMultiWindow.createWindow(hymnJson);
      _presentationWindowId = window.windowId;
      
      // Get window controller
      final windowController = WindowController.fromWindowId(window.windowId);
      
      // Apply native frameless style on Windows
      if (Platform.isWindows) {
        try {
          // On Windows, the windowId from desktop_multi_window is the HWND
          WindowsWindowService.makeWindowFrameless(window.windowId);
        } catch (e) {
          print('Error applying frameless style: $e');
        }
      }
      
      // Position and size window on target display
      final rect = Offset(
        targetDisplay.visiblePosition!.dx,
        targetDisplay.visiblePosition!.dy,
      ) & Size(
        targetDisplay.size.width,
        targetDisplay.size.height,
      );
      
      // Configure window for fullscreen presentation
      await windowController.setFrame(rect);
      await windowController.setTitle('GHS Presentation');
      await windowController.show();
      
      print('Presentation window created: ID=${window.windowId}');
      print('Window positioned at: ${rect.left}, ${rect.top}');
      print('Window size: ${rect.width} x ${rect.height}');
      print('========================');
      
    } catch (e) {
      print('Error creating presentation window: $e');
      rethrow;
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

  static Future<void> closePresentationWindow() async {
    if (_presentationWindowId != null) {
      try {
        final windowController = WindowController.fromWindowId(_presentationWindowId!);
        await windowController.close();
        _presentationWindowId = null;
      } catch (e) {
        print('Error closing presentation window: $e');
      }
    }
  }

  static bool get isPresentationActive => _presentationWindowId != null;
}
