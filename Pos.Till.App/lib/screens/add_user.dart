import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exception.dart';
import '../models/login_response.dart';
import '../models/user.dart';
import '../services/secure_credentials.dart';
import '../state/providers.dart';
import '../widgets/pin_pad.dart';

/// Flow:
/// 1. Show the tenant's user list (the device JWT seeds GET /api/users).
/// 2. Cashier picks themselves and enters their **password** once.
/// 3. We do a real login → fresh JWT.
/// 4. Cashier picks a 4-digit PIN.
/// 5. JWT is encrypted under the PIN-derived key and persisted.
class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

enum _Step { pickUser, password, choosePin, confirmPin }

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  _Step _step = _Step.pickUser;
  AsyncValue<List<User>> _usersAsync = const AsyncValue<List<User>>.loading();

  User? _picked;
  final TextEditingController _passwordCtrl = TextEditingController();
  String? _freshJwt;
  String? _firstPin;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final List<User> users = await ref.read(usersApiProvider).list();
      if (!mounted) return;
      setState(() => _usersAsync = AsyncValue<List<User>>.data(
            users.where((User u) => u.isActive).toList(),
          ),);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _usersAsync =
          AsyncValue<List<User>>.error(e, StackTrace.current),);
    }
  }

  Future<void> _doPasswordLogin() async {
    if (_picked == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final LoginResponse resp = await ref.read(authApiProvider).login(
            LoginRequest(email: _picked!.email, password: _passwordCtrl.text),
          );
      if (resp.userId != _picked!.id) {
        setState(() => _error = 'That login returned a different user.');
        return;
      }
      setState(() {
        _freshJwt = resp.token;
        _step = _Step.choosePin;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePin(String pin) async {
    if (_picked == null || _freshJwt == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(secureCredentialsProvider).addCashier(
            entry: CashierEntry(
              userId: _picked!.id,
              fullName: _picked!.fullName,
              email: _picked!.email,
              role: _picked!.role,
            ),
            jwt: _freshJwt!,
            pin: pin,
          );
      ref.invalidate(cashierEntriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_picked!.fullName} added')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForStep()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  String _titleForStep() {
    switch (_step) {
      case _Step.pickUser:
        return 'Pick cashier';
      case _Step.password:
        return 'Verify password';
      case _Step.choosePin:
        return 'Choose a PIN';
      case _Step.confirmPin:
        return 'Confirm PIN';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.pickUser:
        return _usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, _) => Column(
            children: <Widget>[
              Text('$e', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _loadUsers, child: const Text('Retry')),
            ],
          ),
          data: (List<User> users) => _buildPickList(users),
        );
      case _Step.password:
        return _buildPasswordStep();
      case _Step.choosePin:
        return _buildPinStep(
          prompt: 'Pick a 4-digit PIN for ${_picked!.fullName.split(" ").first}.',
          onComplete: (String pin) {
            setState(() {
              _firstPin = pin;
              _step = _Step.confirmPin;
              _error = null;
            });
          },
        );
      case _Step.confirmPin:
        return _buildPinStep(
          prompt: 'Re-enter the PIN.',
          onComplete: (String pin) {
            if (pin != _firstPin) {
              setState(() => _error = "PINs don't match. Try again.");
              return;
            }
            _savePin(pin);
          },
        );
    }
  }

  Widget _buildPickList(List<User> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users on this tenant yet.'));
    }
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext c, int i) {
        final User u = users[i];
        return ListTile(
          leading: CircleAvatar(child: Text(u.fullName.isEmpty ? '?' : u.fullName[0])),
          title: Text(u.fullName),
          subtitle: Text('${u.email} · ${u.role}'),
          onTap: () => setState(() {
            _picked = u;
            _step = _Step.password;
            _passwordCtrl.clear();
            _error = null;
          }),
        );
      },
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Enter the password for ${_picked!.fullName} (${_picked!.email}).\n'
          'We use this once to fetch a fresh JWT — the password itself is never stored.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordCtrl,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          enabled: !_busy,
          onSubmitted: (_) => _busy ? null : _doPasswordLogin(),
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _doPasswordLogin,
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildPinStep({required String prompt, required ValueChanged<String> onComplete}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(prompt, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        PinPad(
          enabled: !_busy,
          errorText: _error,
          onComplete: onComplete,
        ),
      ],
    );
  }
}
