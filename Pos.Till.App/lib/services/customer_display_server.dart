import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../state/broadcast_state.dart';

/// Default port the till listens on for customer-display clients.
const int kCustomerDisplayPort = 7124;

/// Local WebSocket server the till runs while it's open. Pushes the
/// current [TillBroadcast] payload to every connected client whenever
/// the till tells it to via [pushBroadcast].
class CustomerDisplayServer {
  CustomerDisplayServer({this.port = kCustomerDisplayPort});

  final int port;
  HttpServer? _server;
  final Set<WebSocketChannel> _clients = <WebSocketChannel>{};
  TillBroadcast _last = const TillBroadcast();
  final StreamController<int> _clientCountController =
      StreamController<int>.broadcast();

  bool get isRunning => _server != null;
  int get clientCount => _clients.length;
  Stream<int> get clientCountStream => _clientCountController.stream;

  /// Starts the server on `0.0.0.0:[port]`. Safe to call when already
  /// running — no-ops in that case.
  Future<void> start() async {
    if (_server != null) return;
    final handler = webSocketHandler((WebSocketChannel ws, String? _) {
      _clients.add(ws);
      _emitCount();
      // Send the latest snapshot right after connect so the display
      // doesn't sit on a stale "welcome" until the next cart change.
      _safeSend(ws, _last);
      ws.stream.listen(
        (_) {},
        onDone: () {
          _clients.remove(ws);
          _emitCount();
        },
        onError: (_) {
          _clients.remove(ws);
          _emitCount();
        },
        cancelOnError: true,
      );
    });
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  }

  Future<void> stop() async {
    for (final WebSocketChannel ws in _clients.toList()) {
      try {
        await ws.sink.close();
      } catch (_) {
        // ignore — peer may already be gone
      }
    }
    _clients.clear();
    _emitCount();
    await _server?.close(force: true);
    _server = null;
  }

  void _emitCount() {
    if (!_clientCountController.isClosed) {
      _clientCountController.add(_clients.length);
    }
  }

  /// Fans the snapshot out to every connected client.
  void pushBroadcast(TillBroadcast b) {
    _last = b;
    for (final WebSocketChannel ws in _clients.toList()) {
      _safeSend(ws, b);
    }
  }

  void _safeSend(WebSocketChannel ws, TillBroadcast b) {
    try {
      ws.sink.add(jsonEncode(b.toJson()));
    } catch (_) {
      _clients.remove(ws);
    }
  }
}
