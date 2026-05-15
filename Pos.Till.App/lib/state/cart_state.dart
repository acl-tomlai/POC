import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';

/// Cart line — a Product plus mutable quantity and per-line discount.
class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    this.discountAmount = 0,
  });

  final Product product;
  final double quantity;
  final double discountAmount;

  double get lineTotal => (product.price * quantity) - discountAmount;

  CartLine copyWith({double? quantity, double? discountAmount}) => CartLine(
        product: product,
        quantity: quantity ?? this.quantity,
        discountAmount: discountAmount ?? this.discountAmount,
      );
}

/// Draft order — the right-hand cart panel.
class OrderDraft {
  const OrderDraft({
    this.serverOrderId,
    this.serverOrderNumber,
    this.lines = const <CartLine>[],
    this.orderDiscount = 0,
    this.taxRate = 0.15,
  });

  /// Set after the API has created the order (Send-to-kitchen / Pay).
  final String? serverOrderId;
  final String? serverOrderNumber;
  final List<CartLine> lines;
  final double orderDiscount;
  final double taxRate;

  double get subtotal => lines.fold<double>(0, (double acc, CartLine l) => acc + l.lineTotal);
  double get taxableBase => (subtotal - orderDiscount).clamp(0, double.infinity);
  double get tax => taxableBase * taxRate;
  double get total => taxableBase + tax;

  bool get isEmpty => lines.isEmpty;

  OrderDraft copyWith({
    String? serverOrderId,
    String? serverOrderNumber,
    List<CartLine>? lines,
    double? orderDiscount,
  }) =>
      OrderDraft(
        serverOrderId: serverOrderId ?? this.serverOrderId,
        serverOrderNumber: serverOrderNumber ?? this.serverOrderNumber,
        lines: lines ?? this.lines,
        orderDiscount: orderDiscount ?? this.orderDiscount,
        taxRate: taxRate,
      );
}

class CartNotifier extends StateNotifier<OrderDraft> {
  CartNotifier() : super(const OrderDraft());

  void addProduct(Product p) {
    final int idx = state.lines.indexWhere((CartLine l) => l.product.id == p.id);
    final List<CartLine> next = List<CartLine>.of(state.lines);
    if (idx == -1) {
      next.add(CartLine(product: p, quantity: 1));
    } else {
      next[idx] = next[idx].copyWith(quantity: next[idx].quantity + 1);
    }
    state = state.copyWith(lines: next);
  }

  void setLineQuantity(String productId, double qty) {
    if (qty <= 0) {
      removeLine(productId);
      return;
    }
    final List<CartLine> next = <CartLine>[
      for (final CartLine l in state.lines)
        if (l.product.id == productId) l.copyWith(quantity: qty) else l,
    ];
    state = state.copyWith(lines: next);
  }

  void setLineDiscount(String productId, double discount) {
    final List<CartLine> next = <CartLine>[
      for (final CartLine l in state.lines)
        if (l.product.id == productId) l.copyWith(discountAmount: discount) else l,
    ];
    state = state.copyWith(lines: next);
  }

  void removeLine(String productId) {
    state = state.copyWith(
      lines: state.lines.where((CartLine l) => l.product.id != productId).toList(),
    );
  }

  void setOrderDiscount(double amount) {
    state = state.copyWith(orderDiscount: amount);
  }

  void bindServerOrder({required String id, required String number}) {
    state = state.copyWith(serverOrderId: id, serverOrderNumber: number);
  }

  void reset() {
    state = const OrderDraft();
  }
}
