import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/cart_state.dart';
import 'cart_line_edit_sheet.dart';

/// Right-hand pane on the till: cart line list + totals + Send/Pay actions.
class CartPanel extends ConsumerWidget {
  const CartPanel({
    super.key,
    required this.onSendToKitchen,
    required this.onPay,
    this.sending = false,
  });

  /// Triggered by the Send-to-kitchen button. Disabled when [sending] is
  /// true or the cart is empty.
  final VoidCallback onSendToKitchen;

  /// Triggered by the Pay button. Phase 4 wires this to the payment screen.
  final VoidCallback onPay;

  final bool sending;

  static final NumberFormat _money =
      NumberFormat.simpleCurrency(decimalDigits: 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrderDraft draft = ref.watch(cartProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  draft.serverOrderNumber == null
                      ? 'New order'
                      : 'Order ${draft.serverOrderNumber}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (!draft.isEmpty)
                IconButton(
                  tooltip: 'Discard',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDiscard(context, ref),
                ),
            ],
          ),
          const Divider(),
          Expanded(child: _buildLines(context, ref, draft)),
          const Divider(),
          _summaryRow('Subtotal', draft.subtotal),
          if (draft.orderDiscount > 0) _summaryRow('Discount', -draft.orderDiscount),
          _summaryRow('Tax', draft.tax),
          const SizedBox(height: 4),
          _summaryRow('Total', draft.total, bold: true),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: draft.isEmpty || sending ? null : onSendToKitchen,
            child: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send to kitchen'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: draft.isEmpty ? null : onPay,
            child: Text(draft.isEmpty ? 'Pay' : 'Pay ${_money.format(draft.total)} ▸'),
          ),
        ],
      ),
    );
  }

  Widget _buildLines(BuildContext context, WidgetRef ref, OrderDraft draft) {
    if (draft.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text('Tap a product to start'),
        ),
      );
    }
    return ListView.separated(
      itemCount: draft.lines.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext c, int i) {
        final CartLine line = draft.lines[i];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(line.product.name),
          subtitle: Text(
            '${_fmtQty(line.quantity)} × ${_money.format(line.product.price)}'
            '${line.discountAmount > 0 ? '  −${_money.format(line.discountAmount)}' : ''}',
          ),
          trailing: Text(
            _money.format(line.lineTotal),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext c) => CartLineEditSheet(line: line),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, double amount, {bool bold = false}) {
    final TextStyle? base = bold
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: base),
          Text(_money.format(amount), style: base),
        ],
      ),
    );
  }

  static String _fmtQty(double q) =>
      q == q.truncate() ? q.toInt().toString() : q.toString();

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Discard order?'),
        content: const Text('All lines on this draft order will be cleared.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
        ],
      ),
    );
    if (ok ?? false) ref.read(cartProvider.notifier).reset();
  }
}
