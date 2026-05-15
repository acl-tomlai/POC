import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../state/broadcast_state.dart';

/// Customer-display side WebSocket client. Connects to a till's
/// `customer_display_server` and parses the JSON snapshots into
/// [TillBroadcast] objects.
///
/// Auto-reconnects with a small backoff while [_running] is true.
class CustomerDisplayClient {
  CustomerDisplayClient();

  Uri? _uri;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  bool _running = false;
  Timer? _reconnectTimer;

  final StreamController<TillBroadcast> _broadcasts =
      StreamController<TillBroadcast>.broadcast();
  final StreamController<bool> _connectionState =
      StreamController<bool>.broadcast();

  Stream<TillBroadcast> get broadcasts => _broadcasts.stream;
  Stream<bool> get connected => _connectionState.stream;

  Future<void> connectTo(Uri uri) async {
    _uri = uri;
    _running = true;
    await _open();
  }

  Future<void> _open() async {
    if (!_running || _uri == null) return;
    try {
      final WebSocketChannel ch = WebSocketChannel.connect(_uri!);
      await ch.ready;
      _channel = ch;
      _connectionState.add(true);
      _sub = ch.stream.listen(
        _onMessage,
        onDone: _onClosed,
        onError: (Object _, StackTrace __) => _onClosed(),
        cancelOnError: true,
      );
    } catch (_) {
      _onClosed();
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      _broadcasts.add(TillBroadcast.fromJson(j));
    } catch (_) {
      // ignore malformed frames
    }
  }

  void _onClosed() {
    _connectionState.add(false);
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (_running) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 2), _open);
    }
  }

  Future<void> disconnect() async {
    _running = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _sub?.cancel();
    _sub = null;
    final WebSocketChannel? ch = _channel;
    _channel = null;
    try {
      await ch?.sink.close();
    } catch (_) {}
    _connectionState.add(false);
  }

  Future<void> dispose() async {
    await disconnect();
    await _broadcasts.close();
    await _connectionState.close();
  }
}
