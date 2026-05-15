import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/idle_logout.dart';
import 'router.dart';
import 'theme.dart';

class TillApp extends ConsumerWidget {
  const TillApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
