import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exception.dart';
import '../app/router.dart';
import '../models/login_response.dart';
import '../models/store.dart';
import '../models/user.dart';
import '../services/secure_credentials.dart';
import '../state/providers.dart';

class DeviceSetupScreen extends ConsumerStatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  ConsumerState<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends ConsumerState<DeviceSetupScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  /// Phase 1 of the flow: sign in. Phase 2: pick a store.
  LoginResponse? _login;
  List<Store> _stores = <Store>[];
  String? _selectedStoreId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final LoginResponse resp = await ref.read(authApiProvider).login(
            LoginRequest(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            ),
          );
      if (!Roles.isAdminOrManager(resp.role)) {
        setState(() => _error = 'Only Admin or Manager can pair a tablet.');
        return;
      }
      // Stash device creds (without a store yet) so stores call carries the JWT.
      await ref.read(deviceStateProvider.notifier).setCredentials(
            DeviceCredentials(
              token: resp.token,
              userId: resp.userId,
              role: resp.role,
              restaurantId: resp.restaurantId,
              restaurantName: resp.restaurantName,
              storeId: '',
            ),
          );
      final List<Store> stores = await ref.read(storesApiProvider).list();
      setState(() {
        _login = resp;
        _stores = stores.where((Store s) => s.isActive).toList();
        if (_stores.length == 1) _selectedStoreId = _stores.first.id;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completePairing() async {
    if (_login == null || _selectedStoreId == null) return;
    await ref.read(deviceStateProvider.notifier).setCredentials(
          DeviceCredentials(
            token: _login!.token,
            userId: _login!.userId,
            role: _login!.role,
            restaurantId: _login!.restaurantId,
            restaurantName: _login!.restaurantName,
            storeId: _selectedStoreId!,
          ),
        );
    if (mounted) context.go(TillRoutes.userPicker);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pair this tablet')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              if (_login == null) ..._buildLoginStep() else ..._buildStoreStep(),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoginStep() {
    return <Widget>[
      const Text(
        'Sign in as Admin or Manager to register this device.',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _emailCtrl,
        decoration: const InputDecoration(labelText: 'Email'),
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        enabled: !_busy,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordCtrl,
        decoration: const InputDecoration(labelText: 'Password'),
        obscureText: true,
        enabled: !_busy,
        onSubmitted: (_) => _busy ? null : _signIn(),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _busy ? null : _signIn,
        child: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Sign in'),
      ),
    ];
  }

  List<Widget> _buildStoreStep() {
    return <Widget>[
      Text(
        'Signed in as ${_login!.fullName}. Pick the active store for this tablet.',
        style: const TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 16),
      const Text('Active store', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      if (_stores.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No active stores on this tenant. Create one in the admin web.'),
        )
      else
        RadioGroup<String>(
          groupValue: _selectedStoreId,
          onChanged: (String? v) => setState(() => _selectedStoreId = v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final Store s in _stores)
                RadioListTile<String>(
                  value: s.id,
                  title: Text(s.name),
                  subtitle: s.address != null ? Text(s.address!) : null,
                ),
            ],
          ),
        ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _selectedStoreId == null ? null : _completePairing,
        child: const Text('Pair tablet'),
      ),
    ];
  }
}
