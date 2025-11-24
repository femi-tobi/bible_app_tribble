import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsWindowService {
  /// Makes a window frameless by removing the title bar and borders.
  /// [windowId] is expected to be the HWND of the window.
  static void makeWindowFrameless(int windowId) {
    final hwnd = windowId;

    // Get current window style
    // On 64-bit Windows, we should use GetWindowLongPtr
    // But win32 package maps it correctly usually
    final style = GetWindowLongPtr(hwnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE);
    
    // Remove caption, thick frame (resize border), and system menu
    // WS_CAPTION includes WS_BORDER | WS_DLGFRAME
    // WS_THICKFRAME is the resizing border
    // WS_SYSMENU is the window menu (minimize/close buttons)
    final newStyle = style & ~(WINDOW_STYLE.WS_CAPTION | WINDOW_STYLE.WS_THICKFRAME | WINDOW_STYLE.WS_SYSMENU);
    
    // Apply new style
    SetWindowLongPtr(hwnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE, newStyle);
    
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
    
    print('Applied frameless style to window HWND: $hwnd');
  }
}
