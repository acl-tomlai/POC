import 'package:flutter/material.dart';

/// 4-digit PIN entry pad with dot indicators and submit/backspace.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onComplete,
    this.length = 4,
    this.errorText,
    this.enabled = true,
  });

  final int length;
  final String? errorText;
  final bool enabled;

  /// Fires once the user has typed [length] digits.
  final ValueChanged<String> onComplete;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _value = '';

  @override
  void didUpdateWidget(covariant PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A newly-arrived error from the parent means the previous attempt
    // failed — wipe the dots so the next attempt starts fresh.
    if (widget.errorText != null && oldWidget.errorText != widget.errorText) {
      _value = '';
    }
  }

  void _tap(String d) {
    if (!widget.enabled) return;
    if (_value.length >= widget.length) return;
    setState(() => _value = '$_value$d');
    if (_value.length == widget.length) widget.onComplete(_value);
  }

  void _back() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  void _submit() {
    if (_value.length == widget.length) widget.onComplete(_value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(widget.length, (int i) {
            final bool filled = i < _value.length;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                filled ? Icons.circle : Icons.circle_outlined,
                size: 20,
              ),
            );
          }),
        ),
        if (widget.errorText != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        _Row(<Widget>[_key('1'), _key('2'), _key('3')]),
        _Row(<Widget>[_key('4'), _key('5'), _key('6')]),
        _Row(<Widget>[_key('7'), _key('8'), _key('9')]),
        _Row(<Widget>[
          _action(Icons.backspace_outlined, _back),
          _key('0'),
          _action(Icons.check, _submit),
        ]),
      ],
    );
  }

  Widget _key(String digit) {
    return _KeyTile(
      onTap: () => _tap(digit),
      child: Text(digit, style: const TextStyle(fontSize: 24)),
    );
  }

  Widget _action(IconData icon, VoidCallback onTap) {
    return _KeyTile(onTap: widget.enabled ? onTap : null, child: Icon(icon, size: 24));
  }
}

class _Row extends StatelessWidget {
  const _Row(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _KeyTile extends StatelessWidget {
  const _KeyTile({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 72,
        height: 64,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(minimumSize: const Size(72, 64)),
          child: child,
        ),
      ),
    );
  }
}
