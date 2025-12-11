import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '../models/hymn.dart';
import '../models/sermon.dart';
import 'windows_window_service.dart';

class PresentationWindowService {
  static int? _presentationWindowId;
  static String? _currentType;
  
  // Public getter for presentation window ID
  static int? get presentationWindowId => _presentationWindowId;
  


  static Future<void> openFullscreenPresentation(
    BuildContext context,
    Hymn hymn,
    Map<String, dynamic> config,
  ) async {
    // If we already have a hymn window open, just update it
    if (_presentationWindowId != null && _currentType == 'hymn') {
      print('Reuse existing Hymn window (ID=$_presentationWindowId)');
      await updateHymn(hymn);
      await sendConfig(config);
      return;
    }
    
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
    // If we already have a bible window open, just update it
    if (_presentationWindowId != null && _currentType == 'bible') {
      print('Reuse existing Bible window (ID=$_presentationWindowId)');
      await updateBibleVerse(verseData);
      await sendConfig(config);
      return;
    }

    // Include config in verse data
    final dataWithConfig = Map<String, dynamic>.from(verseData);
    dataWithConfig['config'] = config;
    await _createWindow(context, dataWithConfig, 'bible');
  }

  static Future<void> openSermonPresentation(
    BuildContext context,
    Sermon sermon,
    Map<String, dynamic> config,
  ) async {
    // If we already have a sermon window open, just update it
    if (_presentationWindowId != null && _currentType == 'sermon') {
      print('Reuse existing Sermon window (ID=$_presentationWindowId)');
      await updateSermon(sermon);
      await sendConfig(config);
      return;
    }

    // Include config in sermon data
    final sermonData = sermon.toMap();
    sermonData['config'] = config;
    await _createWindow(context, sermonData, 'sermon');
  }

  static Future<void> openTimerPresentation(
    BuildContext context,
    Map<String, dynamic> timerData,
    Map<String, dynamic> config,
  ) async {
    // If we already have a timer window open, just update it
    if (_presentationWindowId != null && _currentType == 'timer') {
      print('Reuse existing Timer window (ID=$_presentationWindowId)');
      await updateTimer(timerData);
      await sendConfig(config);
      return;
    }

    // Include config in timer data
    final dataWithConfig = Map<String, dynamic>.from(timerData);
    dataWithConfig['config'] = config;
    await _createWindow(context, dataWithConfig, 'timer');
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

    // NEVER close and recreate windows - this causes "Lost connection to device" crash
    // Instead, we only close if switching to a different presentation type
    // For same type, we just update the content via method calls

    try {
      print('Creating new presentation window...');
      final jsonArgs = jsonEncode({
        'type': type,
        'data': data,
      });
      
      // Create new window for presentation
      final window = await DesktopMultiWindow.createWindow(jsonArgs);
      
      print('Presentation window created: ID=${window.windowId}');
      
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
      
      print('Setting window frame: $rect');
      // await windowController.setFrame(rect);
      
      String title = 'Presentation';
      if (type == 'hymn') title = 'GHS Presentation';
      else if (type == 'bible') title = 'Bible Presentation';
      else if (type == 'sermon') title = 'Sermon Presentation';
      else if (type == 'timer') title = 'Timer Presentation';
      
      // await windowController.setTitle(title);
      await windowController.show();
      
      // Store window ID for later communication
      _presentationWindowId = window.windowId;
      _currentType = type;
      
    } catch (e) {
      print('Error creating presentation window: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open presentation window: $e')),
      );
    }
  }

  static Future<bool> _verifyWindowActive() async {
    if (_presentationWindowId == null) return false;
    
    try {
      final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      if (!subWindowIds.contains(_presentationWindowId)) {
        print('Window ID $_presentationWindowId not found in active windows list. Resetting.');
        _presentationWindowId = null;
        _currentType = null;
        return false;
      }
      return true;
    } catch (e) {
      print('Error verifying window status: $e');
      return true; 
    }
  }

  static Future<void> _handleCommunicationError(dynamic e) async {
    print('Communication error with presentation window: $e');
    if (e.toString().contains('target window not found') || 
        e.toString().contains('Window not found')) {
      print('Target window lost. Resetting state.');
      _presentationWindowId = null;
      _currentType = null;
    }
  }

  static Future<void> sendNavigationCommand(String direction) async {
    if (await _verifyWindowActive()) {
      try {
        await DesktopMultiWindow.invokeMethod(
          _presentationWindowId!,
          'navigate_slide',
          direction,
        );
      } catch (e) {
        await _handleCommunicationError(e);
      }
    }
  }

  static Future<void> updateBibleVerse(Map<String, dynamic> verseData) async {
    if (await _verifyWindowActive()) {
      try {
        await DesktopMultiWindow.invokeMethod(
          _presentationWindowId!,
          'update_verse',
          verseData,
        );
      } catch (e) {
        await _handleCommunicationError(e);
      }
    }
  }

  static Future<void> updateHymn(Hymn hymn) async {
    if (await _verifyWindowActive()) {
      try {
        await DesktopMultiWindow.invokeMethod(
          _presentationWindowId!,
          'update_hymn',
          hymn.toJson(),
        );
      } catch (e) {
        await _handleCommunicationError(e);
      }
    }
  }

  static Future<void> updateSermon(Sermon sermon) async {
    if (await _verifyWindowActive()) {
      try {
        await DesktopMultiWindow.invokeMethod(
          _presentationWindowId!,
          'update_sermon',
          sermon.toMap(),
        );
      } catch (e) {
        await _handleCommunicationError(e);
      }
    }
  }

  static Future<void> updateTimer(Map<String, dynamic> timerData) async {
    if (await _verifyWindowActive()) {
      try {
        await DesktopMultiWindow.invokeMethod(
          _presentationWindowId!,
          'update_timer',
          timerData,
        );
      } catch (e) {
        await _handleCommunicationError(e);
      }
    }
  }

  static Future<void> sendConfig(Map<String, dynamic> config) async {
    if (await _verifyWindowActive()) {
      try {
        await DesktopMultiWindow.invokeMethod(
          _presentationWindowId!,
          'init_config',
          config,
        );
      } catch (e) {
        await _handleCommunicationError(e);
      }
    }
  }

  static Future<void> closePresentationWindow() async {
    if (_presentationWindowId != null) {
      try {
        // Verify window still exists before trying to hide it
        final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
        if (subWindowIds.contains(_presentationWindowId)) {
          final windowController = WindowController.fromWindowId(_presentationWindowId!);
          // Hide instead of close to prevent crash on next presentation
          await windowController.hide();
          print('Presentation window hidden: ID=$_presentationWindowId');
        } else {
          print('Window ID $_presentationWindowId already closed');
        }
      } catch (e) {
        print('Error hiding presentation window: $e');
      }
      // Don't reset _presentationWindowId - keep it so we can reuse the window
      // Only reset the current type
      _currentType = null;
    }
  }

  static bool get isPresentationActive => _presentationWindowId != null;
}
