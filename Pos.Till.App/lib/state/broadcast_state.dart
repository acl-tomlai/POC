import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_state.dart';
import 'payment_state.dart';

/// State of the customer display, broadcast from the till over the LAN.
enum BroadcastStatus { idle, order, payment, thankYou }

/// One line of the cart, as it appears on the display payload.
///
/// Carries both `name` (primary) and `nameLocalized` (alt) so the display
/// can pick the right one per its own preference.
class BroadcastLine {
  const BroadcastLine({
    required this.name,
    this.nameLocalized,
    required this.qty,
    required this.unit,
    required this.total,
  });

  factory BroadcastLine.fromJson(Map<String, dynamic> j) => BroadcastLine(
        name: j['name'] as String,
        nameLocalized: j['nameLocalized'] as String?,
        qty: (j['qty'] as num).toDouble(),
        unit: (j['unit'] as num).toDouble(),
        total: (j['total'] as num).toDouble(),
      );

  final String name;
  final String? nameLocalized;
  final double qty;
  final double unit;
  final double total;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        if (nameLocalized != null) 'nameLocalized': nameLocalized,
        'qty': qty,
        'unit': unit,
        'total': total,
      };
}

/// One tendered payment row on the display payload.
class BroadcastPayment {
  const BroadcastPayment({required this.method, required this.amount});

  factory BroadcastPayment.fromJson(Map<String, dynamic> j) => BroadcastPayment(
        method: j['method'] as String,
        amount: (j['amount'] as num).toDouble(),
      );

  final String method;
  final double amount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'method': method,
        'amount': amount,
      };
}

/// The single source of truth the till streams to the display.
class TillBroadcast {
  const TillBroadcast({
    this.status = BroadcastStatus.idle,
    this.orderNumber,
    this.lines = const <BroadcastLine>[],
    this.subtotal = 0,
    this.tax = 0,
    this.total = 0,
    this.payments = const <BroadcastPayment>[],
    this.remaining = 0,
  });

  factory TillBroadcast.fromJson(Map<String, dynamic> j) => TillBroadcast(
        status: BroadcastStatus.values.firstWhere(
          (BroadcastStatus s) => s.name == j['status'],
          orElse: () => BroadcastStatus.idle,
        ),
        orderNumber: j['orderNumber'] as String?,
        lines: (j['lines'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>()
            .map(BroadcastLine.fromJson)
            .toList(),
        subtotal: (j['subtotal'] as num? ?? 0).toDouble(),
        tax: (j['tax'] as num? ?? 0).toDouble(),
        total: (j['total'] as num? ?? 0).toDouble(),
        payments: (j['payments'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>()
            .map(BroadcastPayment.fromJson)
            .toList(),
        remaining: (j['remaining'] as num? ?? 0).toDouble(),
      );

  final BroadcastStatus status;
  final String? orderNumber;
  final List<BroadcastLine> lines;
  final double subtotal;
  final double tax;
  final double total;
  final List<BroadcastPayment> payments;
  final double remaining;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status.name,
        if (orderNumber != null) 'orderNumber': orderNumber,
        'lines': lines.map((BroadcastLine l) => l.toJson()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'payments':
            payments.map((BroadcastPayment p) => p.toJson()).toList(),
        'remaining': remaining,
      };
}

/// Owns the till's current display payload. Subscribes to [cartProvider]
/// and [paymentDraftProvider] internally so screens don't have to push
/// updates by hand — they just mutate cart/payment state and the display
/// follows. The "thank-you → idle" flash is the one exception, kick-
/// triggered explicitly by the payment screen on complete-sale.
class TillBroadcastNotifier extends StateNotifier<TillBroadcast> {
  TillBroadcastNotifier(this._ref) : super(const TillBroadcast());

  final Ref _ref;
  Timer? _thankYouTimer;

  /// Called from the provider factory once both upstream listeners are
  /// wired. Idempotent on repeat calls.
  void recompute() => _recompute();

  void _recompute() {
    // Skip if the thank-you flash is still on screen.
    if (state.status == BroadcastStatus.thankYou) return;

    final OrderDraft cart = _ref.read(cartProvider);
    final PaymentDraft pay = _ref.read(paymentDraftProvider);

    if (cart.isEmpty) {
      state = const TillBroadcast();
      return;
    }

    final List<BroadcastLine> lines = cart.lines
        .map((CartLine l) => BroadcastLine(
              name: l.product.name,
              nameLocalized: l.product.nameLocalized,
              qty: l.quantity,
              unit: l.product.price,
              total: l.lineTotal,
            ),)
        .toList();

    if (pay.active) {
      state = TillBroadcast(
        status: BroadcastStatus.payment,
        orderNumber: cart.serverOrderNumber,
        lines: lines,
        subtotal: cart.subtotal,
        tax: cart.tax,
        total: cart.total,
        payments: pay.rows
            .map((TenderedRow r) =>
                BroadcastPayment(method: r.method.apiMethod, amount: r.amount),)
            .toList(),
        remaining: pay.remaining(cart.total),
      );
    } else {
      state = TillBroadcast(
        status: BroadcastStatus.order,
        orderNumber: cart.serverOrderNumber,
        lines: lines,
        subtotal: cart.subtotal,
        tax: cart.tax,
        total: cart.total,
      );
    }
  }

  /// Flashes the thank-you state for [hold], then unlatches and lets the
  /// cart-reset broadcast take over.
  void flashThankYou({Duration hold = const Duration(seconds: 5)}) {
    _thankYouTimer?.cancel();
    state = state.toThankYou();
    _thankYouTimer = Timer(hold, () {
      if (mounted) {
        _recompute();
      }
    });
  }

  @override
  void dispose() {
    _thankYouTimer?.cancel();
    super.dispose();
  }
}

extension on TillBroadcast {
  TillBroadcast toThankYou() => TillBroadcast(
        status: BroadcastStatus.thankYou,
        orderNumber: orderNumber,
        lines: lines,
        subtotal: subtotal,
        tax: tax,
        total: total,
        payments: payments,
        remaining: 0,
      );
}

final StateNotifierProvider<PaymentDraftNotifier, PaymentDraft>
    paymentDraftProvider =
    StateNotifierProvider<PaymentDraftNotifier, PaymentDraft>(
  (Ref ref) => PaymentDraftNotifier(),
);

final StateNotifierProvider<TillBroadcastNotifier, TillBroadcast>
    tillBroadcastProvider =
    StateNotifierProvider<TillBroadcastNotifier, TillBroadcast>(
  (Ref ref) {
    final TillBroadcastNotifier notifier = TillBroadcastNotifier(ref);
    ref.listen<OrderDraft>(
      cartProvider,
      (OrderDraft? prev, OrderDraft next) => notifier.recompute(),
      fireImmediately: true,
    );
    ref.listen<PaymentDraft>(
      paymentDraftProvider,
      (PaymentDraft? prev, PaymentDraft next) => notifier.recompute(),
    );
    return notifier;
  },
);
