import 'package:flutter_test/flutter_test.dart';
import 'package:pos_till_app/state/broadcast_state.dart';

void main() {
  group('TillBroadcast JSON round-trip', () {
    test('idle status', () {
      const TillBroadcast original = TillBroadcast();
      final TillBroadcast decoded =
          TillBroadcast.fromJson(original.toJson());
      expect(decoded.status, BroadcastStatus.idle);
      expect(decoded.lines, isEmpty);
      expect(decoded.total, 0);
    });

    test('order status with lines and totals', () {
      const TillBroadcast original = TillBroadcast(
        status: BroadcastStatus.order,
        orderNumber: 'ORD-1',
        lines: <BroadcastLine>[
          BroadcastLine(
            name: 'Beef Pho',
            nameLocalized: 'Phở Bò',
            qty: 1,
            unit: 12.0,
            total: 12.0,
          ),
          BroadcastLine(name: 'Coke', qty: 2, unit: 3.0, total: 6.0),
        ],
        subtotal: 18.0,
        tax: 2.7,
        total: 20.7,
      );
      final TillBroadcast decoded =
          TillBroadcast.fromJson(original.toJson());
      expect(decoded.status, BroadcastStatus.order);
      expect(decoded.orderNumber, 'ORD-1');
      expect(decoded.lines, hasLength(2));
      expect(decoded.lines[0].name, 'Beef Pho');
      expect(decoded.lines[0].nameLocalized, 'Phở Bò');
      expect(decoded.lines[1].nameLocalized, isNull);
      expect(decoded.subtotal, 18.0);
      expect(decoded.tax, 2.7);
      expect(decoded.total, 20.7);
    });

    test('payment status carries payments + remaining', () {
      const TillBroadcast original = TillBroadcast(
        status: BroadcastStatus.payment,
        total: 37.85,
        payments: <BroadcastPayment>[
          BroadcastPayment(method: 'Cash', amount: 20),
        ],
        remaining: 17.85,
      );
      final TillBroadcast decoded =
          TillBroadcast.fromJson(original.toJson());
      expect(decoded.status, BroadcastStatus.payment);
      expect(decoded.payments, hasLength(1));
      expect(decoded.payments[0].method, 'Cash');
      expect(decoded.payments[0].amount, 20);
      expect(decoded.remaining, 17.85);
    });

    test('unknown status string decodes as idle', () {
      final TillBroadcast decoded = TillBroadcast.fromJson(<String, dynamic>{
        'status': 'something-new',
      });
      expect(decoded.status, BroadcastStatus.idle);
    });
  });
}
