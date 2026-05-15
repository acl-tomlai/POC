import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

/// mDNS service type the till advertises and the customer display
/// discovers. Plan: `_postill._tcp`.
const String kBonsoirServiceType = '_postill._tcp';

/// Wrapper around `bonsoir` for both broadcast (till side) and discovery
/// (customer-display side). Use one instance per role.
class PairingService {
  PairingService();

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  final Map<String, DiscoveredTill> _discovered = <String, DiscoveredTill>{};
  StreamController<List<DiscoveredTill>>? _discoveryController;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;

  // ---------- broadcast (till side) ----------

  Future<void> advertise({
    required String tenantId,
    required String storeId,
    required String deviceName,
    int port = 7124,
  }) async {
    await stopAdvertise();
    final BonsoirService service = BonsoirService(
      name: deviceName,
      type: kBonsoirServiceType,
      port: port,
      attributes: <String, String>{
        'tenantId': tenantId,
        'storeId': storeId,
        'deviceName': deviceName,
      },
    );
    final BonsoirBroadcast b = BonsoirBroadcast(service: service);
    await b.ready;
    await b.start();
    _broadcast = b;
  }

  Future<void> stopAdvertise() async {
    final BonsoirBroadcast? b = _broadcast;
    _broadcast = null;
    if (b != null && !b.isStopped) {
      await b.stop();
    }
  }

  // ---------- discovery (customer-display side) ----------

  /// Stream of currently-resolved tills. Each emission is the full list
  /// (lost services are removed).
  Stream<List<DiscoveredTill>> discoveredTills() {
    _discoveryController?.close();
    _discoveryController = StreamController<List<DiscoveredTill>>.broadcast();
    _startDiscovery();
    return _discoveryController!.stream;
  }

  Future<void> _startDiscovery() async {
    await stopDiscovery();
    _discovered.clear();
    final BonsoirDiscovery d = BonsoirDiscovery(type: kBonsoirServiceType);
    await d.ready;
    await d.start();
    _discovery = d;
    _discoverySub = d.eventStream?.listen((BonsoirDiscoveryEvent e) {
      final BonsoirService? svc = e.service;
      switch (e.type) {
        case BonsoirDiscoveryEventType.discoveryServiceFound:
          // ignore: discarded_futures
          d.serviceResolver.resolveService(svc!);
          break;
        case BonsoirDiscoveryEventType.discoveryServiceResolved:
          if (svc is ResolvedBonsoirService) {
            _discovered[_keyFor(svc)] = DiscoveredTill(
              name: svc.name,
              host: svc.host ?? '',
              port: svc.port,
              attributes: svc.attributes,
            );
            _emit();
          }
          break;
        case BonsoirDiscoveryEventType.discoveryServiceLost:
          if (svc != null) {
            _discovered.remove(_keyFor(svc));
            _emit();
          }
          break;
        default:
          break;
      }
    });
  }

  String _keyFor(BonsoirService s) =>
      '${s.name}|${s is ResolvedBonsoirService ? s.host : ''}|${s.port}';

  void _emit() {
    final StreamController<List<DiscoveredTill>>? c = _discoveryController;
    if (c != null && !c.isClosed) {
      c.add(_discovered.values.toList());
    }
  }

  Future<void> stopDiscovery() async {
    await _discoverySub?.cancel();
    _discoverySub = null;
    final BonsoirDiscovery? d = _discovery;
    _discovery = null;
    if (d != null && !d.isStopped) {
      await d.stop();
    }
    final StreamController<List<DiscoveredTill>>? c = _discoveryController;
    _discoveryController = null;
    await c?.close();
  }

  Future<void> dispose() async {
    await stopAdvertise();
    await stopDiscovery();
  }
}

/// A till the customer-display has resolved on the LAN.
class DiscoveredTill {
  const DiscoveredTill({
    required this.name,
    required this.host,
    required this.port,
    this.attributes = const <String, String>{},
  });

  final String name;
  final String host;
  final int port;
  final Map<String, String> attributes;

  /// `ws://host:port/cart` — what the client passes to WebSocketChannel.
  Uri get wsUri => Uri(scheme: 'ws', host: host, port: port, path: '/cart');

  @override
  String toString() => '$name @ $host:$port';
}

/// Helper: best-effort local-IP lookup, used in Settings to remind the
/// cashier what to type into the customer display if mDNS isn't working.
Future<String?> localIpAddress() async {
  try {
    final List<NetworkInterface> ifs = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final NetworkInterface i in ifs) {
      for (final InternetAddress a in i.addresses) {
        if (!a.isLoopback) return a.address;
      }
    }
  } catch (_) {
    // ignore
  }
  return null;
}
