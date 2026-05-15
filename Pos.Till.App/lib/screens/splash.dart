import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../state/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    // Give DeviceStateNotifier a tick to hydrate from secure_storage.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final bool paired = ref.read(deviceStateProvider).isPaired;
    if (paired) {
      context.go(TillRoutes.userPicker);
    } else {
      context.go(TillRoutes.deviceSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? restaurant =
        ref.watch(deviceStateProvider).credentials?.restaurantName;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.point_of_sale, size: 72),
            const SizedBox(height: 16),
            Text(
              restaurant == null || restaurant.isEmpty
                  ? 'POS TILL'
                  : restaurant.toUpperCase(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Checking device…'),
          ],
        ),
      ),
    );
  }
}
