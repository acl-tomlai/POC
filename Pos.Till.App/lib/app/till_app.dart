import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/customer_display_server.dart';
import '../services/idle_logout.dart';
import '../services/secure_credentials.dart';
import '../state/broadcast_state.dart';
import '../state/device_state.dart';
import '../state/providers.dart';
import 'router.dart';
import 'theme.dart';

class TillApp extends ConsumerStatefulWidget {
  const TillApp({super.key});

  @override
  ConsumerState<TillApp> createState() => _TillAppState();
}

class _TillAppState extends ConsumerState<TillApp> {
  bool _serverStarted = false;
  String? _advertisedFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Keep the broadcast provider alive for the lifetime of the app —
      // the server listens to it.
      ref.read(tillBroadcastProvider);
      // Apply current credentials immediately so server + advertise come
      // up on launch (not waiting for a credentials change).
      // ignore: discarded_futures
      _ensureLanBridge(ref.read(deviceStateProvider).credentials);
    });
  }

  Future<void> _ensureLanBridge(DeviceCredentials? creds) async {
    if (creds == null) {
      // Tear down on sign-out / wipe.
      if (_serverStarted) {
        await ref.read(customerDisplayServerProvider).stop();
        _serverStarted = false;
      }
      if (_advertisedFor != null) {
        await ref.read(pairingServiceProvider).stopAdvertise();
        _advertisedFor = null;
      }
      return;
    }
    if (!_serverStarted) {
      await ref.read(customerDisplayServerProvider).start();
      _serverStarted = true;
    }
    // Re-advertise if the store / restaurant changed.
    final String key = '${creds.restaurantId}|${creds.storeId}';
    if (_advertisedFor != key) {
      await ref.read(pairingServiceProvider).advertise(
            tenantId: creds.restaurantId,
            storeId: creds.storeId,
            deviceName: creds.restaurantName.isEmpty
                ? 'POS Till'
                : '${creds.restaurantName} · Till',
            port: kCustomerDisplayPort,
          );
      _advertisedFor = key;
    }
  }

  @override
  Widget build(BuildContext context) {
    // React to device-credentials changes (pair / unpair / restaurant swap).
    ref.listen<DeviceCredentials?>(
      deviceStateProvider.select((DeviceState s) => s.credentials),
      (DeviceCredentials? prev, DeviceCredentials? next) {
        // ignore: discarded_futures
        _ensureLanBridge(next);
      },
    );

    return MaterialApp.router(
      title: 'POS Till',
      theme: buildTillTheme(),
      routerConfig: ref.watch(tillRouterProvider),
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) =>
          IdleLogoutScope(child: child ?? const SizedBox.shrink()),
    );
  }
}
