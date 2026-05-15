import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Numeric pad for tender entry.
///
/// * `Exact` fills the [exactAmount] (typically `remaining`).
/// * `+5 / +10 / +20` round-up shortcuts when the customer hands over a
///   bigger note than the remaining.
/// * `Add` commits the current value via [onAdd].
class AmountKeypad extends StatefulWidget {
  const AmountKeypad({
    super.key,
    required this.exactAmount,
    required this.onAdd,
    this.enabled = true,
  });

  final double exactAmount;
  final ValueChanged<double> onAdd;
  final bool enabled;

  @override
  State<AmountKeypad> createState() => _AmountKeypadState();
}

class _AmountKeypadState extends State<AmountKeypad> {
  String _value = '';
  static final NumberFormat _money =
      NumberFormat.simpleCurrency(decimalDigits: 2);

  double get _parsed => double.tryParse(_value) ?? 0;

  void _append(String s) {
    if (!widget.enabled) return;
    if (s == '.' && _value.contains('.')) return;
    setState(() => _value = _value + s);
  }

  void _back() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  void _clear() {
    setState(() => _value = '');
  }

  void _setExact() {
    setState(() => _value = widget.exactAmount.toStringAsFixed(2));
  }

  void _roundUpTo(double note) {
    // Smallest multiple of [note] that meets or exceeds the exact amount.
    if (widget.exactAmount <= 0) {
      setState(() => _value = note.toStringAsFixed(2));
      return;
    }
    final double n = (widget.exactAmount / note).ceil() * note;
    setState(() => _value = n.toStringAsFixed(2));
  }

  void _commit() {
    if (!widget.enabled) return;
    final double v = _parsed;
    if (v <= 0) return;
    widget.onAdd(v);
    _clear();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? amountStyle = Theme.of(context).textTheme.headlineSmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Amount', style: Theme.of(context).textTheme.labelMedium),
              Text(
                _value.isEmpty ? '\$0.00' : '\$$_value',
                style: amountStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: widget.enabled ? _setExact : null,
                child: Text('Exact ${_money.format(widget.exactAmount)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: widget.enabled ? () => _roundUpTo(5) : null,
                child: const Text('+5'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: widget.enabled ? () => _roundUpTo(10) : null,
                child: const Text('+10'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: widget.enabled ? () => _roundUpTo(20) : null,
                child: const Text('+20'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _row(<String>['7', '8', '9']),
        _row(<String>['4', '5', '6']),
        _row(<String>['1', '2', '3']),
        Row(
          children: <Widget>[
            Expanded(child: _key('.')),
            Expanded(child: _key('0')),
            Expanded(
              child: _PadButton(
                onTap: widget.enabled ? _back : null,
                child: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: widget.enabled && _parsed > 0 ? _commit : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      children: <Widget>[
        for (final String d in digits) Expanded(child: _key(d)),
      ],
    );
  }

  Widget _key(String digit) {
    return _PadButton(
      onTap: widget.enabled ? () => _append(digit) : null,
      child: Text(digit, style: const TextStyle(fontSize: 22)),
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: onTap,
          child: child,
        ),
      ),
    );
  }
}
