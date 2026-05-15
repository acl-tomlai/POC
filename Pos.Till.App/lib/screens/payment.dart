import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay  Order #ORD-NEW   Total \$0.00')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'TODO(phase4): split-tender payment.\n'
            'Tap a method tile → enter amount via keypad → row appears in Tendered.\n'
            'Complete sale unlocks when Remaining ≤ 0.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
