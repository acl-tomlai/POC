import 'package:flutter_test/flutter_test.dart';
import 'package:pos_till_app/services/eftpos/eftpos_provider.dart';
import 'package:pos_till_app/services/eftpos/mock_eftpos_provider.dart';

void main() {
  group('MockEftposProvider', () {
    test('approves when confirm returns true and emits a 5-digit auth code', () async {
      final MockEftposProvider provider = MockEftposProvider(
        confirm: (double _) async => true,
      );
      final EftposResult r = await provider.charge(amount: 17.85, orderRef: 'X');
      expect(r.approved, isTrue);
      expect(r.authCode, isNotNull);
      expect(r.authCode!.length, 5);
      expect(int.tryParse(r.authCode!), isNotNull);
    });

    test('declines when confirm returns false', () async {
      final MockEftposProvider provider = MockEftposProvider(
        confirm: (double _) async => false,
      );
      final EftposResult r = await provider.charge(amount: 17.85, orderRef: 'X');
      expect(r.approved, isFalse);
      expect(r.authCode, isNull);
      expect(r.declineReason, isNotNull);
    });

    test('confirm receives the charged amount', () async {
      double? received;
      final MockEftposProvider provider = MockEftposProvider(
        confirm: (double a) async {
          received = a;
          return true;
        },
      );
      await provider.charge(amount: 42.50, orderRef: 'X');
      expect(received, 42.50);
    });
  });
}
