import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../api/api_exception.dart';
import '../app/router.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../models/printer.dart';
import '../services/eftpos/eftpos_provider.dart';
import '../services/eftpos/mock_eftpos_provider.dart';
import '../services/printer_service.dart';
import '../state/broadcast_state.dart';
import '../state/cart_state.dart';
import '../state/device_state.dart';
import '../state/payment_state.dart';
import '../state/providers.dart';
import '../widgets/amount_keypad.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  TenderMethod _selected = TenderMethod.cash;
  bool _busy = false;

  static final NumberFormat _money =
      NumberFormat.simpleCurrency(decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(paymentDraftProvider.notifier).enter();
    });
  }

  @override
  void dispose() {
    // Exit payment mode if the cashier leaves the screen for any reason
    // other than a completed sale (which also calls exit explicitly).
    ref.read(paymentDraftProvider.notifier).exit();
    super.dispose();
  }

  Future<void> _onAdd(double amount) async {
    if (amount <= 0) return;
    if (_selected == TenderMethod.eftpos) {
      final EftposProvider eftpos = MockEftposProvider(
        confirm: (double a) async {
          final bool? ok = await showDialog<bool>(
            context: context,
            builder: (BuildContext c) => AlertDialog(
              title: Text('EFTPOS · ${_money.format(a)}'),
              content: const Text(
                'Mock terminal. Approve to record an authorisation code; '
                'decline to leave the row off the order.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Decline'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Approve'),
                ),
              ],
            ),
          );
          return ok ?? false;
        },
      );
      final OrderDraft draft = ref.read(cartProvider);
      final EftposResult result = await eftpos.charge(
        amount: amount,
        orderRef: draft.serverOrderNumber ?? 'NEW',
      );
      if (!result.approved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Declined: ${result.declineReason ?? "no reason"}',),
            ),
          );
        }
        return;
      }
      ref.read(paymentDraftProvider.notifier).addRow(
            TenderedRow(
              method: TenderMethod.eftpos,
              amount: amount,
              reference: result.authCode,
            ),
          );
    } else {
      ref
          .read(paymentDraftProvider.notifier)
          .addRow(TenderedRow(method: _selected, amount: amount));
    }
  }

  void _removeRow(int index) {
    ref.read(paymentDraftProvider.notifier).removeAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final OrderDraft draft = ref.watch(cartProvider);
    final PaymentDraft pay = ref.watch(paymentDraftProvider);
    final double total = draft.total;
    final double remaining = pay.remaining(total);
    final bool canComplete = !_busy && pay.rows.isNotEmpty && remaining <= 0.0001;

    if (draft.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(TillRoutes.tillHome);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pay  ${draft.serverOrderNumber ?? "(new)"}    Total ${_money.format(total)}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildTenderedHeader(pay, total, remaining),
                  const SizedBox(height: 8),
                  Expanded(child: _buildTenderedList(pay)),
                  const SizedBox(height: 12),
                  _buildMethodTiles(),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: canComplete ? _completeSale : null,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            pay.isEmpty
                                ? 'Tap a method to start'
                                : remaining > 0
                                    ? 'Remaining ${_money.format(remaining)}'
                                    : 'Complete sale ▸',
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: AmountKeypad(
                exactAmount: remaining,
                enabled: !_busy,
                onAdd: _onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenderedHeader(PaymentDraft pay, double total, double remaining) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text('Tendered', style: Theme.of(context).textTheme.titleMedium),
          Text(
            remaining > 0
                ? 'Remaining ${_money.format(remaining)}'
                : 'Change ${_money.format(pay.change(total))}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderedList(PaymentDraft pay) {
    if (pay.isEmpty) {
      return Center(
        child: Text(
          'No tenders yet — pick a method and enter an amount',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.separated(
      itemCount: pay.rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext c, int i) {
        final TenderedRow r = pay.rows[i];
        return ListTile(
          dense: true,
          leading: Icon(r.method.icon),
          title: Text(r.method.displayLabel),
          subtitle: r.reference == null ? null : Text('auth ${r.reference}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _money.format(r.amount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _busy ? null : () => _removeRow(i),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMethodTiles() {
    return SizedBox(
      height: 80,
      child: Row(
        children: <Widget>[
          for (final TenderMethod m in TenderMethod.values) ...<Widget>[
            Expanded(
              child: _MethodTile(
                method: m,
                selected: _selected == m,
                onTap: _busy ? null : () => setState(() => _selected = m),
              ),
            ),
            if (m != TenderMethod.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Future<void> _completeSale() async {
    final OrderDraft draft = ref.read(cartProvider);
    final PaymentDraft pay = ref.read(paymentDraftProvider);
    final DeviceState device = ref.read(deviceStateProvider);
    final String? storeId = device.credentials?.storeId;
    if (draft.isEmpty || storeId == null || storeId.isEmpty) return;

    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      // 1. Create or bind the server order.
      Order order;
      if (draft.serverOrderId == null) {
        final OrderCreateRequest req = OrderCreateRequest(
          storeId: storeId,
          discountAmount: draft.orderDiscount,
          taxAmount: draft.tax,
          lines: draft.lines
              .map((CartLine l) => OrderLineRequest(
                    productId: l.product.id,
                    quantity: l.quantity,
                    unitPrice: l.product.price,
                    discountAmount: l.discountAmount,
                  ),)
              .toList(),
        );
        order = await ref.read(ordersApiProvider).create(req);
      } else {
        order = await ref.read(ordersApiProvider).get(draft.serverOrderId!);
      }

      // 2. POST each tender row.
      for (final TenderedRow r in pay.rows) {
        await ref.read(paymentsApiProvider).add(
              order.id,
              PaymentCreateRequest(
                paymentMethod: r.method.apiMethod,
                amount: r.amount,
                reference: r.reference,
              ),
            );
      }

      // 3. Status -> Paid; pull the canonical order back.
      final Order paid = await ref
          .read(ordersApiProvider)
          .updateStatus(order.id, OrderStatus.paid);

      // 4. Print receipt + kick drawer if any cash.
      final List<String> printErrors = await _printReceipt(paid);
      if (pay.rows.any((TenderedRow r) => r.method == TenderMethod.cash)) {
        printErrors.addAll(await _kickDrawer());
      }

      // 5. Flash thank-you on the customer display before the cart reset
      //    wipes it back to "Welcome".
      ref.read(tillBroadcastProvider.notifier).flashThankYou();

      // 6. Reset cart + payment draft and bounce home.
      ref.read(cartProvider.notifier).reset();
      ref.read(paymentDraftProvider.notifier).exit();
      if (!mounted) return;
      final double change = pay.change(paid.totalAmount);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            <String>[
              'Order paid · ${paid.orderNumber}',
              if (change > 0) 'change ${_money.format(change)}',
              if (printErrors.isNotEmpty)
                'print/drawer issues: ${printErrors.join("; ")}',
            ].join(' · '),
          ),
        ),
      );
      context.go(TillRoutes.tillHome);
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<String>> _printReceipt(Order order) async {
    final DeviceState device = ref.read(deviceStateProvider);
    final String? receiptId = device.receiptPrinterId;
    if (receiptId == null || receiptId.isEmpty) {
      return <String>['no receipt printer configured'];
    }
    final List<Printer> printers =
        await ref.read(activeStorePrintersProvider.future);
    Printer? receipt;
    for (final Printer p in printers) {
      if (p.id == receiptId) {
        receipt = p;
        break;
      }
    }
    if (receipt == null) {
      return <String>['receipt printer is no longer on the active store'];
    }
    final List<int> bytes =
        await ref.read(printerServiceProvider).buildReceipt(
              order: order,
              lang: device.receiptLang,
              restaurantName: device.credentials?.restaurantName ?? '',
              cashierName: ref.read(sessionStateProvider).fullName,
            );
    final PrintResult result = await ref
        .read(printerServiceProvider)
        .send(printer: receipt, bytes: bytes);
    return result.ok ? <String>[] : <String>[result.error ?? 'print failed'];
  }

  Future<List<String>> _kickDrawer() async {
    final DeviceState device = ref.read(deviceStateProvider);
    final String? receiptId = device.receiptPrinterId;
    if (receiptId == null || receiptId.isEmpty) return <String>[];
    final List<Printer> printers =
        await ref.read(activeStorePrintersProvider.future);
    Printer? receipt;
    for (final Printer p in printers) {
      if (p.id == receiptId) {
        receipt = p;
        break;
      }
    }
    if (receipt == null) return <String>[];
    final PrintResult result =
        await ref.read(drawerServiceProvider).kick(receipt);
    return result.ok ? <String>[] : <String>[result.error ?? 'drawer kick failed'];
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final TenderMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: selected ? cs.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(method.icon, size: 28),
              const SizedBox(height: 4),
              Text(method.displayLabel,
                  style: Theme.of(context).textTheme.titleSmall,),
            ],
          ),
        ),
      ),
    );
  }
}
