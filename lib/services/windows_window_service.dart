import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsWindowService {
  /// Makes a window frameless by removing the title bar and borders.
  /// Uses WS_POPUP style which allows the window to cover the taskbar.
  /// [windowId] is expected to be the HWND of the window.
  static void makeWindowFrameless(int windowId) {
    final hwnd = windowId;
    print('WindowsWindowService: Making window frameless. HWND: $hwnd');

    try {
      // Get current style
      final currentStyle = GetWindowLongPtr(hwnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE);
      print('Current style: 0x${currentStyle.toRadixString(16)}');
      
      // Remove WS_CAPTION, WS_THICKFRAME, WS_SYSMENU, WS_MINIMIZEBOX, WS_MAXIMIZEBOX
      // Keep only WS_VISIBLE and WS_POPUP
      final newStyle = (WINDOW_STYLE.WS_VISIBLE | WINDOW_STYLE.WS_POPUP);
      
      print('Setting new style: 0x${newStyle.toRadixString(16)}');
      final result = SetWindowLongPtr(hwnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE, newStyle);
      print('SetWindowLongPtr result: $result');
      
      // Remove all extended styles
      SetWindowLongPtr(hwnd, WINDOW_LONG_PTR_INDEX.GWL_EXSTYLE, 0);
      
      // Force redraw
      SetWindowPos(
        hwnd, 
        HWND_TOPMOST,
        0, 0, 0, 0, 
        SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED | 
        SET_WINDOW_POS_FLAGS.SWP_NOMOVE | 
        SET_WINDOW_POS_FLAGS.SWP_NOSIZE |
        SET_WINDOW_POS_FLAGS.SWP_SHOWWINDOW
      );
      
      print('✓ Frameless style applied');
    } catch (e) {
      print('WindowsWindowService: Error applying style: $e');
    }
  }

  /// Makes a window fullscreen by positioning it to cover the entire screen including taskbar.
  /// Also makes the window frameless (no title bar, borders, buttons).
  static Future<void> makeWindowFullscreen(
    int windowId,
    int x,
    int y,
    int width,
    int height,
  ) async {
    final hwnd = windowId;
    print('WindowsWindowService: Setting fullscreen: ${width}x$height at ($x, $y)');

    try {
      // Wait for window to be fully ready
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Try to hide taskbar temporarily
      final taskbarHwnd = FindWindow('Shell_TrayWnd'.toNativeUtf16(), nullptr);
      if (taskbarHwnd != 0) {
        ShowWindow(taskbarHwnd, SHOW_WINDOW_CMD.SW_HIDE);
        print('✓ Taskbar hidden');
      }
      
      // Since SetWindowLongPtr fails, try using DWM (Desktop Window Manager) to hide title bar
      // DWMWA_NCRENDERING_POLICY = 2, DWMNCRP_DISABLED = 1
      try {
        final policyValue = calloc<Int32>();
        policyValue.value = 1; // DWMNCRP_DISABLED
        
        // Try to call DwmSetWindowAttribute (may not work but worth trying)
        final dwmResult = DwmSetWindowAttribute(
          hwnd,
          2, // DWMWA_NCRENDERING_POLICY
          policyValue,
          sizeOf<Int32>(),
        );
        
        calloc.free(policyValue);
        
        if (dwmResult == 0) {
          print('✓ DWM title bar disabled');
        }
      } catch (e) {
        print('DWM approach failed: $e');
      }
      
      // Maximize the window
      ShowWindow(hwnd, SHOW_WINDOW_CMD.SW_MAXIMIZE);
      
      // Set window to topmost and try to position it
      SetWindowPos(
        hwnd,
        HWND_TOPMOST,
        x,
        y,
        width,
        height,
        SET_WINDOW_POS_FLAGS.SWP_SHOWWINDOW
      );
      
      print('✓ Window set to fullscreen');
    } catch (e) {
      print('WindowsWindowService: Error setting fullscreen: $e');
    }
  }
  
  /// Restores the taskbar when presentation window closes
  static void restoreTaskbar() {
    try {
      final taskbarHwnd = FindWindow('Shell_TrayWnd'.toNativeUtf16(), nullptr);
      if (taskbarHwnd != 0) {
        ShowWindow(taskbarHwnd, SHOW_WINDOW_CMD.SW_SHOW);
        print('✓ Taskbar restored');
      }
    } catch (e) {
      print('Error restoring taskbar: $e');
    }
  }
}

