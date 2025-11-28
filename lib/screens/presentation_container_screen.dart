import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import 'bible_presentation_screen.dart';
import 'ghs_presentation_screen.dart';
import 'sermon_presentation_screen.dart';
import '../models/presentation_config.dart';

class PresentationContainerScreen extends StatefulWidget {
  final int windowId;
  final Map<String, dynamic>? initialData;

  const PresentationContainerScreen({
    super.key,
    required this.windowId,
    this.initialData,
  });

  @override
  State<PresentationContainerScreen> createState() => _PresentationContainerScreenState();
}

class _PresentationContainerScreenState extends State<PresentationContainerScreen> with WindowListener {
  String _currentMode = 'none'; // 'bible', 'hymn', 'sermon', 'none'
  Map<String, dynamic>? _currentData;
  PresentationConfig _config = PresentationConfig();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _setupMethodHandler();
    
    if (widget.initialData != null) {
      _handleUpdate(widget.initialData!);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Prevent window from closing, just hide it
    await windowManager.hide();
    // Notify main window that we are hidden? Optional.
  }

  void _setupMethodHandler() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      print('Container received method: ${call.method}');
      
      switch (call.method) {
        case 'switch_content':
          final args = call.arguments as Map;
          _handleUpdate(Map<String, dynamic>.from(args));
          break;
          
        case 'update_verse':
        case 'update_hymn':
        case 'update_sermon':
          // Pass through to children via state update or re-render
          // For simplicity, we treat these as a data update which rebuilds the child
          final args = call.arguments as Map;
          // We need to know the type to update correctly, but usually update_verse implies bible
          if (call.method == 'update_verse') _updateData('bible', args);
          if (call.method == 'update_hymn') _updateData('hymn', args);
          if (call.method == 'update_sermon') _updateData('sermon', args);
          break;

        case 'init_config':
          final configData = call.arguments as Map;
          setState(() {
            _config = PresentationConfig.fromMap(Map<String, dynamic>.from(configData));
            // Also update data config if it exists so children get it
            if (_currentData != null) {
              _currentData!['config'] = configData;
            }
          });
          break;
          
        case 'clear_content':
          setState(() {
            _currentMode = 'none';
            _currentData = null;
          });
          break;
          
        case 'navigate_slide':
          // Forward to child? 
          // Since children listen to method channel too, they might receive this directly?
          // Actually, setMethodHandler replaces the handler. 
          // So WE are the only one listening now. We must pass it down.
          // But our children are Widgets, not separate windows. 
          // We can use a GlobalKey or just rely on the fact that children are rebuilt with new data.
          // For navigation, we might need a different approach or pass a controller.
          // HOWEVER, the previous implementation had children listening to DesktopMultiWindow.
          // Only ONE handler can exist per window. So we must handle EVERYTHING here.
          // This means we need to pass events to children.
          // Let's use a GlobalKey or a Stream.
          _eventBus.emit('navigate_slide', call.arguments);
          break;
      }
      return null;
    });
  }

  void _handleUpdate(Map<String, dynamic> args) {
    final type = args['type'] as String;
    final data = args['data'] as Map;
    _updateData(type, Map<String, dynamic>.from(data));
  }

  void _updateData(String type, Map<String, dynamic> data) {
    setState(() {
      _currentMode = type;
      _currentData = data;
      
      // Extract config if present
      if (data.containsKey('config')) {
        _config = PresentationConfig.fromMap(Map<String, dynamic>.from(data['config']));
      } else {
        // Inject current config into data so child gets it
        data['config'] = _config.toMap();
      }
    });
  }

  // Simple event bus for passing commands to children
  final _EventBus _eventBus = _EventBus();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_currentMode == 'none' || _currentData == null) {
      return const Center(
        child: Text('Ready', style: TextStyle(color: Colors.white24)),
      );
    }

    // We pass the event stream to children so they can listen for navigation
    switch (_currentMode) {
      case 'bible':
        return BiblePresentationScreen(
          data: _currentData!, 
          // We might need to modify children to accept an event stream or controller
          // For now, let's assume they just take data. 
          // Navigation is the tricky part.
          // Let's modify the children to accept a 'commandStream' if needed, 
          // OR we can just re-implement the listener in the child?
          // NO, setMethodHandler is global for the window.
          // So we must modify children to NOT setMethodHandler, but expose a method we can call.
        );
      case 'hymn':
        return GhsPresentationScreen(data: _currentData!);
      case 'sermon':
        return SermonPresentationScreen(data: _currentData!);
      default:
        return const Center(child: Text('Unknown mode', style: TextStyle(color: Colors.red)));
    }
  }
}

// Helper for event bus
class _EventBus {
  final Map<String, List<Function>> _listeners = {};

  void on(String event, Function callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, Function callback) {
    _listeners[event]?.remove(callback);
  }

  void emit(String event, dynamic data) {
    _listeners[event]?.forEach((callback) => callback(data));
  }
}
