import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../state/providers.dart';

/// Wraps the till app's body with a pointer-listener that, after [timeout] of
/// no taps, signs out the cashier and routes back to the user picker.
///
/// Plan: 5 minutes idle → bounce to user picker (encrypted blob stays on disk).
class IdleLogoutScope extends ConsumerStatefulWidget {
  const IdleLogoutScope({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 5),
  });

  final Widget child;
  final Duration timeout;

  @override
  ConsumerState<IdleLogoutScope> createState() => _IdleLogoutScopeState();
}

class _IdleLogoutScopeState extends ConsumerState<IdleLogoutScope> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    if (!ref.read(sessionStateProvider).isActive) return;
    _timer = Timer(widget.timeout, _onIdle);
  }

  void _onIdle() {
    if (!mounted) return;
    if (!ref.read(sessionStateProvider).isActive) return;
    ref.read(sessionStateProvider.notifier).signOut();
    final BuildContext ctx = context;
    if (ctx.mounted) {
      GoRouter.of(ctx).go(TillRoutes.userPicker);
      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
        const SnackBar(content: Text('Signed out — idle for 5 minutes')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-arm whenever session state flips on/off.
    ref.listen<bool>(
      sessionStateProvider.select((s) => s.isActive),
      (_, bool active) {
        if (active) {
          _restart();
        } else {
          _timer?.cancel();
        }
      },
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      child: widget.child,
    );
  }
}
