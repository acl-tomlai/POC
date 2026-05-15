import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../services/secure_credentials.dart';
import '../state/device_state.dart';
import '../state/providers.dart';
import '../widgets/pin_pad.dart';

class UserPickerScreen extends ConsumerWidget {
  const UserPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceState device = ref.watch(deviceStateProvider);
    final AsyncValue<List<CashierEntry>> tilesAsync =
        ref.watch(cashierEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(device.credentials?.restaurantName ?? 'POS Till'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(TillRoutes.settings),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: tilesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(child: Text('$e')),
              data: (List<CashierEntry> tiles) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Who's working?",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: <Widget>[
                          for (final CashierEntry u in tiles)
                            _CashierTile(
                              cashier: u,
                              onTap: () => _openPinSheet(context, ref, u),
                              onLongPress: () => _confirmRemove(context, ref, u),
                            ),
                          _AddCashierTile(
                            onTap: () => context.push(TillRoutes.addUser),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPinSheet(
      BuildContext context, WidgetRef ref, CashierEntry u,) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext c) => _PinUnlockSheet(cashier: u),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, CashierEntry u,) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text('Remove ${u.fullName}?'),
        content: const Text(
            'Their encrypted token will be wiped from this tablet. They can be re-added later.',),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(secureCredentialsProvider).removeCashier(u.userId);
      ref.invalidate(cashierEntriesProvider);
    }
  }
}

class _PinUnlockSheet extends ConsumerStatefulWidget {
  const _PinUnlockSheet({required this.cashier});

  final CashierEntry cashier;

  @override
  ConsumerState<_PinUnlockSheet> createState() => _PinUnlockSheetState();
}

class _PinUnlockSheetState extends ConsumerState<_PinUnlockSheet> {
  String? _error;
  bool _busy = false;
  int _wrongAttempts = 0;

  Future<void> _onPin(String pin) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? jwt = await ref
        .read(secureCredentialsProvider)
        .unlockJwt(userId: widget.cashier.userId, pin: pin);
    if (!mounted) return;
    if (jwt == null) {
      _wrongAttempts++;
      setState(() {
        _busy = false;
        _error = _wrongAttempts >= 3
            ? 'Too many wrong PINs — sign in with password.'
            : 'Wrong PIN.';
      });
      return;
    }
    ref.read(sessionStateProvider.notifier).signIn(
          token: jwt,
          userId: widget.cashier.userId,
          fullName: widget.cashier.fullName,
          role: widget.cashier.role,
        );
    if (mounted) {
      Navigator.of(context).pop();
      GoRouter.of(context).go(TillRoutes.tillHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Hi, ${widget.cashier.fullName.split(" ").first}',
                style: Theme.of(context).textTheme.titleLarge,),
            const SizedBox(height: 8),
            const Text('Enter your PIN'),
            const SizedBox(height: 16),
            PinPad(
              enabled: !_busy,
              errorText: _error,
              onComplete: _onPin,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.pop(context);
                      // TODO(phase2-future): route to a "sign in with password"
                      // flow that re-issues a fresh JWT and re-wraps under PIN.
                    },
              child: const Text('Sign in with password instead'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierTile extends StatelessWidget {
  const _CashierTile({
    required this.cashier,
    required this.onTap,
    required this.onLongPress,
  });

  final CashierEntry cashier;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  String get _initials {
    final List<String> parts = cashier.fullName.split(RegExp(r'\s+'));
    return parts.take(2).map((String p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 32,
                  child: Text(_initials, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 12),
                Text(cashier.fullName, style: Theme.of(context).textTheme.titleMedium),
                Text('(${cashier.role})', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCashierTile extends StatelessWidget {
  const _AddCashierTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: InkWell(
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.add, size: 48),
                SizedBox(height: 12),
                Text('Add cashier'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
