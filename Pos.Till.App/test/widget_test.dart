// Smoke test for cart math. Widget-level tests for PinPad and the till
// will land in phase 6 polish per PLAN.md.

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_till_app/models/product.dart';
import 'package:pos_till_app/state/cart_state.dart';

void main() {
  group('OrderDraft', () {
    final Product flatWhite = Product(
      id: 'p1',
      categoryId: 'c1',
      categoryName: 'Coffee',
      name: 'Flat White',
      price: 5.50,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );

    final Product croissant = Product(
      id: 'p2',
      categoryId: 'c2',
      categoryName: 'Bakery',
      name: 'Croissant',
      price: 4.20,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );

    test('empty draft has zero totals', () {
      const OrderDraft d = OrderDraft();
      expect(d.subtotal, 0);
      expect(d.tax, 0);
      expect(d.total, 0);
      expect(d.isEmpty, isTrue);
    });

    test('adding two products sums and taxes correctly at 15%', () {
      final CartNotifier cart = CartNotifier()
        ..addProduct(flatWhite)
        ..addProduct(croissant);
      final OrderDraft d = cart.state;
      expect(d.subtotal, closeTo(9.70, 0.0001));
      expect(d.tax, closeTo(1.455, 0.0001));
      expect(d.total, closeTo(11.155, 0.0001));
    });

    test('tapping the same product twice merges into qty 2', () {
      final CartNotifier cart = CartNotifier()
        ..addProduct(flatWhite)
        ..addProduct(flatWhite);
      expect(cart.state.lines, hasLength(1));
      expect(cart.state.lines.first.quantity, 2);
      expect(cart.state.subtotal, closeTo(11.0, 0.0001));
    });

    test('setting qty to 0 removes the line', () {
      final CartNotifier cart = CartNotifier()..addProduct(flatWhite);
      cart.setLineQuantity('p1', 0);
      expect(cart.state.lines, isEmpty);
    });

    test('order-level discount is applied before tax', () {
      final CartNotifier cart = CartNotifier()..addProduct(flatWhite);
      cart.setOrderDiscount(1.50);
      // (5.50 - 1.50) * 1.15 = 4.60
      expect(cart.state.total, closeTo(4.60, 0.0001));
    });
  });
}
