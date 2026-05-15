import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class CustomerPairingScreen extends ConsumerWidget {
  const CustomerPairingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Display')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Pair this screen with a till',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text('Discovered tills nearby',
                    style: Theme.of(context).textTheme.titleSmall,),
                const SizedBox(height: 8),
                const Card(
                  child: ListTile(
                    title: Text('TODO(phase5): bonsoir mDNS discovery'),
                    subtitle: Text('_postill._tcp'),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Or enter IP manually',
                    style: Theme.of(context).textTheme.titleSmall,),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(hintText: '192.168.1.__'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => context.go(CustomerRoutes.display),
                      child: const Text('Pair'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
