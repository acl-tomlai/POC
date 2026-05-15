import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/cart_state.dart';

/// Modal bottom sheet that edits one cart line — qty and per-line discount.
class CartLineEditSheet extends ConsumerStatefulWidget {
  const CartLineEditSheet({super.key, required this.line});

  final CartLine line;

  @override
  ConsumerState<CartLineEditSheet> createState() => _CartLineEditSheetState();
}

class _CartLineEditSheetState extends ConsumerState<CartLineEditSheet> {
  late double _qty;
  late TextEditingController _discountCtrl;

  static final NumberFormat _money =
      NumberFormat.simpleCurrency(decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _qty = widget.line.quantity;
    _discountCtrl = TextEditingController(
      text: widget.line.discountAmount == 0
          ? ''
          : widget.line.discountAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _lineTotal =>
      (widget.line.product.price * _qty) - _discount;

  void _apply() {
    final CartNotifier cart = ref.read(cartProvider.notifier);
    cart
      ..setLineQuantity(widget.line.product.id, _qty)
      ..setLineDiscount(widget.line.product.id, _discount);
    Navigator.of(context).pop();
  }

  void _remove() {
    ref
        .read(cartProvider.notifier)
        .removeLine(widget.line.product.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.line.product.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Qty:'),
                Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _qty <= 1
                          ? null
                          : () => setState(() => _qty -= 1),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        _fmtQty(_qty),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _qty += 1),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Unit price:'),
                Text(_money.format(widget.line.product.price)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Line discount',
                prefixText: '\$',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Line total:',
                    style: TextStyle(fontWeight: FontWeight.w600),),
                Text(
                  _money.format(_lineTotal),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                  onPressed: _remove,
                ),
                FilledButton(onPressed: _apply, child: const Text('Done')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtQty(double q) =>
      q == q.truncate() ? q.toInt().toString() : q.toString();
}
