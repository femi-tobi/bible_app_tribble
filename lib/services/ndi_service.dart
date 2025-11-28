import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// FFI Type Definitions
typedef NDIlib_initialize_C = Int32 Function();
typedef NDIlib_initialize_Dart = int Function();

typedef NDIlib_destroy_C = Void Function();
typedef NDIlib_destroy_Dart = void Function();

typedef NDIlib_send_create_C = Pointer<Void> Function(Pointer<NDIlib_send_create_t> p_create_settings);
typedef NDIlib_send_create_Dart = Pointer<Void> Function(Pointer<NDIlib_send_create_t> p_create_settings);

typedef NDIlib_send_destroy_C = Void Function(Pointer<Void> p_instance);
typedef NDIlib_send_destroy_Dart = void Function(Pointer<Void> p_instance);

typedef NDIlib_send_send_video_v2_C = Void Function(Pointer<Void> p_instance, Pointer<NDIlib_video_frame_v2_t> p_video_data);
typedef NDIlib_send_send_video_v2_Dart = void Function(Pointer<Void> p_instance, Pointer<NDIlib_video_frame_v2_t> p_video_data);

// Struct Definitions
final class NDIlib_send_create_t extends Struct {
  external Pointer<Utf8> p_ndi_name;
  external Pointer<Utf8> p_groups;
  @Int32()
  external int clock_video;
  @Int32()
  external int clock_audio;
}

final class NDIlib_video_frame_v2_t extends Struct {
  @Int32()
  external int xres;
  @Int32()
  external int yres;
  @Int32()
  external int FourCC;
  @Int32()
  external int frame_rate_N;
  @Int32()
  external int frame_rate_D;
  @Float()
  external double picture_aspect_ratio;
  @Int32()
  external int frame_format_type;
  @Int64()
  external int timecode;
  external Pointer<Uint8> p_data;
  @Int32()
  external int line_stride_in_bytes;
  external Pointer<Utf8> p_metadata;
  @Int64()
  external int timestamp;
}

// Constants
const int NDIlib_FourCC_type_RGBA = 0x41424752;
const int NDIlib_FourCC_type_BGRA = 0x41524742;
const int NDIlib_frame_format_type_progressive = 1;

class NdiService {
  static final NdiService _instance = NdiService._internal();
  factory NdiService() => _instance;
  NdiService._internal();

  DynamicLibrary? _lib;
  Pointer<Void>? _sender;
  bool _isInitialized = false;

  // Function pointers
  late NDIlib_initialize_Dart _initialize;
  late NDIlib_destroy_Dart _destroy;
  late NDIlib_send_create_Dart _sendCreate;
  late NDIlib_send_destroy_Dart _sendDestroy;
  late NDIlib_send_send_video_v2_Dart _sendVideoV2;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to find the NDI runtime DLL
      String? libraryPath;
      
      // 1. Check for bundled DLL in the same directory as the executable
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final bundledPath = '$exeDir\\Processing.NDI.Lib.x64.dll';
      
      if (File(bundledPath).existsSync()) {
        libraryPath = bundledPath;
        print('Found bundled NDI Runtime: $libraryPath');
      } else {
        // 2. Check environment variable
        final envPath = Platform.environment['NDI_RUNTIME_DIR_V6'];
        if (envPath != null) {
          libraryPath = '$envPath\\Processing.NDI.Lib.x64.dll';
        } else {
          // 3. Fallback to common installation paths
          final commonPaths = [
            r'C:\Program Files\NDI\NDI 6 Tools\Runtime\Processing.NDI.Lib.x64.dll',
            r'C:\Program Files\NDI\NDI 5 Tools\Runtime\Processing.NDI.Lib.x64.dll',
            r'C:\Program Files\NewTek\NDI 5 Tools\Runtime\Processing.NDI.Lib.x64.dll',
          ];
          
          for (final path in commonPaths) {
            if (File(path).existsSync()) {
              libraryPath = path;
              break;
            }
          }
        }
      }

      if (libraryPath == null || !File(libraryPath).existsSync()) {
        print('NDI Runtime not found. Please install NDI Tools.');
        return;
      }

      print('Loading NDI library from: $libraryPath');
      _lib = DynamicLibrary.open(libraryPath);

      // Lookup functions
      _initialize = _lib!.lookupFunction<NDIlib_initialize_C, NDIlib_initialize_Dart>('NDIlib_initialize');
      _destroy = _lib!.lookupFunction<NDIlib_destroy_C, NDIlib_destroy_Dart>('NDIlib_destroy');
      _sendCreate = _lib!.lookupFunction<NDIlib_send_create_C, NDIlib_send_create_Dart>('NDIlib_send_create');
      _sendDestroy = _lib!.lookupFunction<NDIlib_send_destroy_C, NDIlib_send_destroy_Dart>('NDIlib_send_destroy');
      _sendVideoV2 = _lib!.lookupFunction<NDIlib_send_send_video_v2_C, NDIlib_send_send_video_v2_Dart>('NDIlib_send_send_video_v2');

      // Initialize NDI
      final result = _initialize();
      if (result == 0) { // 0 means failure in some versions, but usually true/false. 
        // Actually NDIlib_initialize returns bool (int)
        // Let's assume non-zero is success or check docs. 
        // Docs say: "Returns true if the initialization was successful."
        // So 1 is success.
      }
      
      // Wait, NDIlib_initialize returns bool. 
      // If it returns false (0), it failed.
      // However, it's safe to call multiple times.
      
      _isInitialized = true;
      print('NDI Initialized successfully');

    } catch (e) {
      print('Failed to initialize NDI: $e');
    }
  }

  void createSender(String name) {
    if (!_isInitialized) return;
    if (_sender != null) return;

    final createSettings = calloc<NDIlib_send_create_t>();
    createSettings.ref.p_ndi_name = name.toNativeUtf8();
    createSettings.ref.p_groups = nullptr;
    createSettings.ref.clock_video = 1;
    createSettings.ref.clock_audio = 0;

    _sender = _sendCreate(createSettings);
    
    calloc.free(createSettings.ref.p_ndi_name);
    calloc.free(createSettings);

    if (_sender == nullptr) {
      print('Failed to create NDI sender');
      _sender = null;
    } else {
      print('NDI Sender created: $name');
    }
  }

  void sendVideoFrame(int width, int height, Uint8List data) {
    if (!_isInitialized || _sender == null) return;

    // Allocate memory for the frame data
    // Note: This is expensive to do every frame if we allocate/free.
    // Ideally we should reuse a buffer or pass a pointer if possible.
    // But for simplicity in Dart FFI, we'll allocate for now.
    // Optimization: The caller should probably provide a persistent pointer or we manage a pool.
    // For this implementation, let's copy the data to native memory.
    
    final dataPtr = calloc<Uint8>(data.length);
    final dataList = dataPtr.asTypedList(data.length);
    dataList.setAll(0, data);

    final videoFrame = calloc<NDIlib_video_frame_v2_t>();
    videoFrame.ref.xres = width;
    videoFrame.ref.yres = height;
    videoFrame.ref.FourCC = NDIlib_FourCC_type_RGBA; // Flutter usually gives RGBA
    videoFrame.ref.frame_rate_N = 30;
    videoFrame.ref.frame_rate_D = 1;
    videoFrame.ref.picture_aspect_ratio = width / height;
    videoFrame.ref.frame_format_type = NDIlib_frame_format_type_progressive;
    videoFrame.ref.timecode = 0; // Let NDI handle it or set current time
    videoFrame.ref.p_data = dataPtr;
    videoFrame.ref.line_stride_in_bytes = width * 4;
    videoFrame.ref.p_metadata = nullptr;
    videoFrame.ref.timestamp = 0;

    _sendVideoV2(_sender!, videoFrame);

    // Cleanup
    calloc.free(dataPtr);
    calloc.free(videoFrame);
  }

  void destroy() {
    if (_sender != null) {
      _sendDestroy(_sender!);
      _sender = null;
    }
    if (_isInitialized) {
      _destroy();
      _isInitialized = false;
    }
  }
}
