import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'dart:io' show Platform;

class PresentationWindowService {
  static Future<void> openFullscreenPresentation(
    BuildContext context,
    Widget presentationWidget,
  ) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      // For mobile/web, just navigate normally
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => presentationWidget),
      );
      return;
    }

    try {
      // Get all available displays
      final screens = await screenRetriever.getAllDisplays();
      
      // Find external display (not primary)
      Display? externalDisplay;
      for (final screen in screens) {
        if (screen.id != screens.first.id) {
          externalDisplay = screen;
          break;
        }
      }

      // Use external display if available, otherwise use primary
      final targetDisplay = externalDisplay ?? screens.first;
      
      // Store current window position and size
      final currentPosition = await windowManager.getPosition();
      final currentSize = await windowManager.getSize();
      final wasFullscreen = await windowManager.isFullScreen();

      // Navigate to presentation
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _FullscreenWrapper(
              child: presentationWidget,
              targetDisplay: targetDisplay,
              onClose: () async {
                // Restore original window state
                await windowManager.setFullScreen(false);
                await windowManager.setSize(currentSize);
                await windowManager.setPosition(currentPosition);
                if (wasFullscreen) {
                  await windowManager.setFullScreen(true);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error opening fullscreen presentation: $e');
      // Fallback to normal navigation
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => presentationWidget),
        );
      }
    }
  }
}

class _FullscreenWrapper extends StatefulWidget {
  final Widget child;
  final Display targetDisplay;
  final VoidCallback onClose;

  const _FullscreenWrapper({
    required this.child,
    required this.targetDisplay,
    required this.onClose,
  });

  @override
  State<_FullscreenWrapper> createState() => _FullscreenWrapperState();
}

class _FullscreenWrapperState extends State<_FullscreenWrapper> {
  @override
  void initState() {
    super.initState();
    _setupFullscreen();
  }

  Future<void> _setupFullscreen() async {
    try {
      // Move window to target display
      final display = widget.targetDisplay;
      await windowManager.setPosition(
        Offset(display.visiblePosition!.dx, display.visiblePosition!.dy),
      );
      
      // Set window size to display size
      await windowManager.setSize(
        Size(display.size.width, display.size.height),
      );
      
      // Enter fullscreen
      await windowManager.setFullScreen(true);
      
      // Bring to front
      await windowManager.focus();
    } catch (e) {
      print('Error setting up fullscreen: $e');
    }
  }

  @override
  void dispose() {
    widget.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
