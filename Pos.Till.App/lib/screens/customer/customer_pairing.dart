import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router.dart';
import '../../services/customer_display_server.dart';
import '../../services/pairing_service.dart';
import '../../state/providers.dart';

/// Shared-preferences key for the paired till's host+port so we can
/// auto-reconnect on next boot.
const String kPairedTillUriKey = 'customer.paired_till_uri';

class CustomerPairingScreen extends ConsumerStatefulWidget {
  const CustomerPairingScreen({super.key});

  @override
  ConsumerState<CustomerPairingScreen> createState() => _State();
}

class _State extends ConsumerState<CustomerPairingScreen> {
  late final TextEditingController _manualHost;
  late final TextEditingController _manualPort;
  StreamSubscription<List<DiscoveredTill>>? _sub;
  List<DiscoveredTill> _found = <DiscoveredTill>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _manualHost = TextEditingController();
    _manualPort = TextEditingController(text: kCustomerDisplayPort.toString());
    _start();
  }

  Future<void> _start() async {
    try {
      final PairingService p = ref.read(pairingServiceProvider);
      _sub = p.discoveredTills().listen(
        (List<DiscoveredTill> tills) {
          if (mounted) setState(() => _found = tills);
        },
        onError: (Object e) {
          if (mounted) setState(() => _error = e.toString());
        },
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _manualHost.dispose();
    _manualPort.dispose();
    super.dispose();
  }

  Future<void> _pair(Uri uri) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPairedTillUriKey, uri.toString());
    if (!mounted) return;
    context.go(CustomerRoutes.display);
  }

  void _pairManual() {
    final String host = _manualHost.text.trim();
    final int? port = int.tryParse(_manualPort.text.trim());
    if (host.isEmpty || port == null || port <= 0) {
      setState(() => _error = 'Enter a valid host and port.');
      return;
    }
    _pair(Uri(scheme: 'ws', host: host, port: port, path: '/cart'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Display')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Pair this screen with a till',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Text(
                  'Discovered tills nearby',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildDiscoveredList()),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Or enter the till\'s LAN address manually',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _manualHost,
                        decoration: const InputDecoration(
                          labelText: 'Host or IP',
                          hintText: '192.168.1.45',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _manualPort,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Port'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _pairManual, child: const Text('Pair')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveredList() {
    if (_found.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Looking for tills on this network…'),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _found.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext c, int i) {
        final DiscoveredTill t = _found[i];
        return ListTile(
          leading: const Icon(Icons.point_of_sale),
          title: Text(t.name),
          subtitle: Text('${t.host}:${t.port}'),
          trailing: FilledButton(
            onPressed: () => _pair(t.wsUri),
            child: const Text('Pair'),
          ),
        );
      },
    );
  }
}
