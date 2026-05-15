import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class CustomerDisplayApp extends ConsumerWidget {
  const CustomerDisplayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Customer Display',
      theme: buildCustomerTheme(),
      routerConfig: ref.watch(customerRouterProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
