import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsWindowService {
  /// Makes a window frameless by removing the title bar and borders.
  /// [windowId] is expected to be the HWND of the window.
  static void makeWindowFrameless(int windowId) {
    final hwnd = windowId;
    print('WindowsWindowService: Attempting to make window frameless. HWND: $hwnd');

    try {
      // Get current window style
      final style = GetWindowLongPtr(hwnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE);
      print('WindowsWindowService: Current style: ${style.toRadixString(16)}');
      
      // Remove caption, thick frame (resize border), and system menu
      final newStyle = style & ~(WINDOW_STYLE.WS_CAPTION | WINDOW_STYLE.WS_THICKFRAME | WINDOW_STYLE.WS_SYSMENU);
      print('WindowsWindowService: New style: ${newStyle.toRadixString(16)}');
      
      // Apply new style
      final result = SetWindowLongPtr(hwnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE, newStyle);
      if (result == 0) {
        print('WindowsWindowService: Warning - SetWindowLongPtr returned 0 (might be error or previous value was 0)');
      }
      
      // Force window to redraw and apply changes
      SetWindowPos(
        hwnd, 
        NULL, 
        0, 0, 0, 0, 
        SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED | 
        SET_WINDOW_POS_FLAGS.SWP_NOMOVE | 
        SET_WINDOW_POS_FLAGS.SWP_NOSIZE | 
        SET_WINDOW_POS_FLAGS.SWP_NOZORDER | 
        SET_WINDOW_POS_FLAGS.SWP_NOACTIVATE
      );
      
      print('WindowsWindowService: Applied frameless style to window HWND: $hwnd');
    } catch (e) {
      print('WindowsWindowService: Error applying style: $e');
    }
  }

  /// Makes a window fullscreen by removing decorations and maximizing.
  /// [windowId] is expected to be the HWND of the window.
  static Future<void> makeWindowFullscreen(int windowId) async {
    final hwnd = windowId;
    print('WindowsWindowService: Making window fullscreen. HWND: $hwnd');

    try {
      // Wait a bit for window to be fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      
      // First make it frameless
      makeWindowFrameless(hwnd);
      
      // Get monitor info for the window's current monitor
      final monitorInfo = calloc<MONITORINFO>();
      monitorInfo.ref.cbSize = sizeOf<MONITORINFO>();
      
      final hMonitor = MonitorFromWindow(hwnd, MONITOR_FROM_FLAGS.MONITOR_DEFAULTTONEAREST);
      if (GetMonitorInfo(hMonitor, monitorInfo) != 0) {
        final rect = monitorInfo.ref.rcMonitor;
        final width = rect.right - rect.left;
        final height = rect.bottom - rect.top;
        
        print('Monitor dimensions: ${width}x$height at (${rect.left}, ${rect.top})');
        
        // Set window to cover entire monitor
        SetWindowPos(
          hwnd,
          HWND_TOPMOST,
          rect.left,
          rect.top,
          width,
          height,
          SET_WINDOW_POS_FLAGS.SWP_SHOWWINDOW | SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED
        );
      } else {
        // Fallback: just maximize
        SetWindowPos(
          hwnd,
          HWND_TOPMOST,
          0, 0, 0, 0,
          SET_WINDOW_POS_FLAGS.SWP_NOMOVE | 
          SET_WINDOW_POS_FLAGS.SWP_NOSIZE | 
          SET_WINDOW_POS_FLAGS.SWP_SHOWWINDOW
        );
        ShowWindow(hwnd, SHOW_WINDOW_CMD.SW_MAXIMIZE);
      }
      
      calloc.free(monitorInfo);
      
      print('WindowsWindowService: Window set to fullscreen mode');
    } catch (e) {
      print('WindowsWindowService: Error setting fullscreen: $e');
    }
  }
}

