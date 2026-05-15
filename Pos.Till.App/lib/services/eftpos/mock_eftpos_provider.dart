import 'dart:math';

import 'eftpos_provider.dart';

/// Confirmation-dialog stand-in for a real terminal. The screen wires
/// [confirm] to a Material dialog; the provider only knows it as a yes/no.
class MockEftposProvider implements EftposProvider {
  MockEftposProvider({required this.confirm});

  /// Called once per charge. Returning true approves; false declines.
  final Future<bool> Function(double amount) confirm;

  static final Random _rng = Random();

  @override
  Future<EftposResult> charge({
    required double amount,
    required String orderRef,
  }) async {
    final bool ok = await confirm(amount);
    if (!ok) {
      return const EftposResult.declined('Cashier declined');
    }
    return EftposResult.approved(
      authCode: _genAuthCode(),
      cardLast4: '4242',
      terminalReceipt: 'MOCK $orderRef',
    );
  }

  @override
  Future<EftposResult> refund({
    required double amount,
    required String authCode,
  }) async {
    // Not used in v1.
    return EftposResult.approved(authCode: 'R${_genAuthCode()}');
  }

  static String _genAuthCode() =>
      _rng.nextInt(90000).toString().padLeft(5, '0');
}
