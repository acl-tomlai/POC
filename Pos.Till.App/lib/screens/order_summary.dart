import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderSummaryScreen extends ConsumerWidget {
  const OrderSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order summary')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('TODO(phase3): pre-print preview before Print + Open drawer.'),
        ),
      ),
    );
  }
}
