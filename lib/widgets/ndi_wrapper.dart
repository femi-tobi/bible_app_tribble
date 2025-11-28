import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/ndi_service.dart';

class NdiWrapper extends StatefulWidget {
  final Widget child;
  final String streamName;
  final bool enabled;

  const NdiWrapper({
    super.key,
    required this.child,
    required this.streamName,
    this.enabled = true,
  });

  @override
  State<NdiWrapper> createState() => _NdiWrapperState();
}

class _NdiWrapperState extends State<NdiWrapper> {
  final GlobalKey _globalKey = GlobalKey();
  Timer? _timer;
  final NdiService _ndiService = NdiService();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _initNdi();
    }
  }

  Future<void> _initNdi() async {
    await _ndiService.initialize();
    if (_ndiService.isInitialized) {
      _ndiService.createSender(widget.streamName);
      _startCapture();
    } else {
      print('NDI initialization failed. Disabling NDI for this session.');
      // Optionally update state to reflect disabled status
    }
  }

  void _startCapture() {
    // Capture at 30 FPS
    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      _captureFrame();
    });
  }

  Future<void> _captureFrame() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture image
      // Note: toByteData is somewhat expensive.
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        _ndiService.sendVideoFrame(image.width, image.height, buffer);
      }
      image.dispose();
    } catch (e) {
      print('Error capturing frame: $e');
    } finally {
      _isCapturing = false;
    }
  }

  @override
  void didUpdateWidget(NdiWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _initNdi();
      } else {
        _stopCapture();
      }
    }
  }

  void _stopCapture() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopCapture();
    // We don't destroy the NDI service here as it might be a singleton used elsewhere,
    // or we might want to keep the sender alive? 
    // Actually, for this specific wrapper, we probably want to stop sending if the widget is removed.
    // But NdiService is a singleton.
    // Let's just stop the timer.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: widget.child,
    );
  }
}
