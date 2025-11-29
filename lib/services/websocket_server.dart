import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WebSocketServer {
  static WebSocketServer? _instance;
  HttpServer? _server;
  int _port = 8080;
  final List<WebSocketChannel> _clients = [];
  final StreamController<Map<String, dynamic>> _commandController = StreamController.broadcast();
  
  // Current presentation state
  Map<String, dynamic> _currentState = {
    'type': 'none', // bible, ghs, sermon
    'book': '',
    'chapter': 0,
    'verse': 0,
    'text': '',
    'part': 0,
    'totalParts': 1,
  };

  WebSocketServer._();

  static WebSocketServer get instance {
    _instance ??= WebSocketServer._();
    return _instance!;
  }

  /// Stream of commands received from clients
  Stream<Map<String, dynamic>> get commands => _commandController.stream;

  /// Start the WebSocket server
  Future<String?> start({int port = 8080}) async {
    if (_server != null) {
      print('WebSocket server already running');
      return null;
    }

    _port = port;

    try {
      // Create WebSocket handler
      final handler = webSocketHandler((WebSocketChannel webSocket) {
        print('Client connected');
        _clients.add(webSocket);

        // Send current state to new client
        webSocket.sink.add(jsonEncode({
          'type': 'state',
          'data': _currentState,
        }));

        // Listen for messages from client
        webSocket.stream.listen(
          (message) {
            try {
              final data = jsonDecode(message as String);
              _handleClientMessage(data);
            } catch (e) {
              print('Error parsing client message: $e');
            }
          },
          onDone: () {
            print('Client disconnected');
            _clients.remove(webSocket);
          },
          onError: (error) {
            print('WebSocket error: $error');
            _clients.remove(webSocket);
          },
        );
      });

      // Create HTTP server with WebSocket upgrade
      final cascade = shelf.Cascade()
          .add(_createHttpHandler())
          .add(handler);

      _server = await shelf_io.serve(
        cascade.handler,
        InternetAddress.anyIPv4,
        _port,
      );

      print('WebSocket server started on port $_port');
      return await _getLocalIpAddress();
    } catch (e) {
      print('Error starting WebSocket server: $e');
      return null;
    }
  }

  /// Stop the WebSocket server
  Future<void> stop() async {
    if (_server == null) return;

    // Close all client connections
    for (final client in _clients) {
      await client.sink.close();
    }
    _clients.clear();

    await _server?.close();
    _server = null;
    print('WebSocket server stopped');
  }

  /// Update presentation state and broadcast to all clients
  void updateState(Map<String, dynamic> state) {
    _currentState = state;
    _broadcastState();
  }

  /// Broadcast current state to all connected clients
  void _broadcastState() {
    final message = jsonEncode({
      'type': 'state',
      'data': _currentState,
    });

    for (final client in _clients) {
      try {
        client.sink.add(message);
      } catch (e) {
        print('Error sending to client: $e');
      }
    }
  }

  /// Handle messages from clients
  void _handleClientMessage(Map<String, dynamic> data) {
    print('Received command: ${data['command']}');
    _commandController.add(data);
  }

  /// Create HTTP handler for serving the web interface
  shelf.Handler _createHttpHandler() {
    return (shelf.Request request) {
      if (request.url.path == '' || request.url.path == 'index.html') {
        return shelf.Response.ok(
          _getWebInterface(),
          headers: {'Content-Type': 'text/html'},
        );
      }
      return shelf.Response.notFound('Not Found');
    };
  }

  /// Get local IP address
  Future<String?> _getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      return wifiIP;
    } catch (e) {
      print('Error getting IP address: $e');
      return null;
    }
  }

  /// Get the web interface HTML
  String _getWebInterface() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Bible App Remote</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #1a1a1a;
            color: #fff;
            height: 100vh;
            display: flex;
            flex-direction: column;
            touch-action: manipulation;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            text-align: center;
        }
        .status {
            padding: 10px;
            background: #2a2a2a;
            text-align: center;
            font-size: 14px;
        }
        .status.connected { background: #2d5016; }
        .status.disconnected { background: #5c1a1a; }
        .preview {
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 20px;
            text-align: center;
            overflow: auto;
        }
        .verse-ref {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 20px;
            color: #667eea;
        }
        .verse-text {
            font-size: 18px;
            line-height: 1.6;
        }
        .controls {
            padding: 20px;
            background: #2a2a2a;
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
        }
        button {
            padding: 20px;
            font-size: 18px;
            font-weight: bold;
            border: none;
            border-radius: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            cursor: pointer;
            transition: transform 0.1s, opacity 0.2s;
            touch-action: manipulation;
        }
        button:active {
            transform: scale(0.95);
            opacity: 0.8;
        }
        button:disabled {
            opacity: 0.3;
            cursor: not-allowed;
        }
        .btn-prev { grid-column: 1; }
        .btn-next { grid-column: 2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📖 Bible App Remote</h1>
    </div>
    <div class="status" id="status">Connecting...</div>
    <div class="preview">
        <div class="verse-ref" id="verseRef">-</div>
        <div class="verse-text" id="verseText">Waiting for presentation...</div>
    </div>
    <div class="controls">
        <button class="btn-prev" id="btnPrev" onclick="sendCommand('previous')">⬅️ Previous</button>
        <button class="btn-next" id="btnNext" onclick="sendCommand('next')">Next ➡️</button>
    </div>

    <script>
        let ws = null;
        let currentState = null;

        function connect() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            ws = new WebSocket(protocol + '//' + window.location.host);

            ws.onopen = () => {
                document.getElementById('status').textContent = 'Connected';
                document.getElementById('status').className = 'status connected';
            };

            ws.onclose = () => {
                document.getElementById('status').textContent = 'Disconnected';
                document.getElementById('status').className = 'status disconnected';
                setTimeout(connect, 3000);
            };

            ws.onmessage = (event) => {
                const data = JSON.parse(event.data);
                if (data.type === 'state') {
                    updateUI(data.data);
                }
            };
        }

        function updateUI(state) {
            currentState = state;
            const ref = document.getElementById('verseRef');
            const text = document.getElementById('verseText');

            if (state.type === 'bible') {
                const part = state.totalParts > 1 ? String.fromCharCode(97 + state.part) : '';
                ref.textContent = state.book + ' ' + state.chapter + ':' + state.verse + part;
                text.textContent = state.text;
            } else if (state.type === 'none') {
                ref.textContent = '-';
                text.textContent = 'No presentation active';
            }
        }

        function sendCommand(command) {
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ command: command }));
            }
        }

        // Swipe gestures
        let touchStartX = 0;
        let touchEndX = 0;

        document.addEventListener('touchstart', e => {
            touchStartX = e.changedTouches[0].screenX;
        });

        document.addEventListener('touchend', e => {
            touchEndX = e.changedTouches[0].screenX;
            handleSwipe();
        });

        function handleSwipe() {
            if (touchEndX < touchStartX - 50) sendCommand('next');
            if (touchEndX > touchStartX + 50) sendCommand('previous');
        }

        // Keyboard shortcuts
        document.addEventListener('keydown', e => {
            if (e.key === 'ArrowLeft') sendCommand('previous');
            if (e.key === 'ArrowRight') sendCommand('next');
        });

        connect();
    </script>
</body>
</html>
    ''';
  }

  bool get isRunning => _server != null;
  int get port => _port;
  int get clientCount => _clients.length;
}
