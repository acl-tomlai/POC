import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';

/// One tender row collected on the payment screen.
class TenderedRow {
  const TenderedRow({
    required this.method,
    required this.amount,
    this.reference,
  });

  final TenderMethod method;
  final double amount;
  final String? reference;
}

/// Tender method selectable on the payment screen. Maps to the API
/// payment-method string via [apiMethod].
enum TenderMethod {
  cash(PaymentMethods.cash, 'Cash', Icons.attach_money),
  eftpos(PaymentMethods.eftpos, 'EFTPOS', Icons.contactless),
  card(PaymentMethods.card, 'Card', Icons.credit_card);

  const TenderMethod(this.apiMethod, this.displayLabel, this.icon);

  final String apiMethod;
  final String displayLabel;
  final IconData icon;
}

/// Persistent state for the in-flight payment.
///
/// Lives outside the payment screen so the customer-display broadcast can
/// reflect tendered rows in real time, and so the screen can survive a
/// rebuild (e.g. orientation change) without losing the tender list.
class PaymentDraft {
  const PaymentDraft({this.active = false, this.rows = const <TenderedRow>[]});

  /// `true` while the cashier is on the Payment screen.
  final bool active;

  final List<TenderedRow> rows;

  double get tendered =>
      rows.fold<double>(0, (double a, TenderedRow r) => a + r.amount);

  double remaining(double total) {
    final double r = total - tendered;
    return r < 0 ? 0 : r;
  }

  double change(double total) {
    final double c = tendered - total;
    return c < 0 ? 0 : c;
  }

  bool get isEmpty => rows.isEmpty;

  PaymentDraft copyWith({bool? active, List<TenderedRow>? rows}) =>
      PaymentDraft(active: active ?? this.active, rows: rows ?? this.rows);
}

class PaymentDraftNotifier extends StateNotifier<PaymentDraft> {
  PaymentDraftNotifier() : super(const PaymentDraft());

  void enter() {
    state = const PaymentDraft(active: true);
  }

  void exit() {
    state = const PaymentDraft();
  }

  void addRow(TenderedRow r) {
    state = state.copyWith(rows: <TenderedRow>[...state.rows, r]);
  }

  void removeAt(int i) {
    final List<TenderedRow> next = List<TenderedRow>.of(state.rows);
    if (i < 0 || i >= next.length) return;
    next.removeAt(i);
    state = state.copyWith(rows: next);
  }
}
