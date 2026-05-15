import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router.dart';
import '../../models/payment.dart';
import '../../services/customer_display_client.dart';
import '../../state/broadcast_state.dart';
import '../../state/device_state.dart';
import '../../state/providers.dart';
import 'customer_pairing.dart';

class CustomerDisplayScreen extends ConsumerStatefulWidget {
  const CustomerDisplayScreen({super.key});

  @override
  ConsumerState<CustomerDisplayScreen> createState() => _State();
}

class _State extends ConsumerState<CustomerDisplayScreen> {
  TillBroadcast _state = const TillBroadcast();
  bool _connected = false;
  StreamSubscription<TillBroadcast>? _broadcastSub;
  StreamSubscription<bool>? _connSub;
  Uri? _uri;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(kPairedTillUriKey);
    if (raw == null) {
      if (mounted) context.go(CustomerRoutes.pairing);
      return;
    }
    _uri = Uri.parse(raw);
    final CustomerDisplayClient client = ref.read(customerDisplayClientProvider);
    _broadcastSub = client.broadcasts.listen((TillBroadcast b) {
      if (mounted) setState(() => _state = b);
    });
    _connSub = client.connected.listen((bool ok) {
      if (mounted) setState(() => _connected = ok);
    });
    await client.connectTo(_uri!);
  }

  @override
  void dispose() {
    _broadcastSub?.cancel();
    _connSub?.cancel();
    ref.read(customerDisplayClientProvider).disconnect();
    super.dispose();
  }

  Future<void> _unpair() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(kPairedTillUriKey);
    await ref.read(customerDisplayClientProvider).disconnect();
    if (mounted) context.go(CustomerRoutes.pairing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            _buildBody(),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: <Widget>[
                  Icon(
                    _connected ? Icons.wifi : Icons.wifi_off,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: _unpair,
                    tooltip: 'Unpair',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state.status) {
      case BroadcastStatus.idle:
        return const _IdleView();
      case BroadcastStatus.order:
        return _OrderView(state: _state);
      case BroadcastStatus.payment:
        return _PaymentView(state: _state);
      case BroadcastStatus.thankYou:
        return const _ThankYouView();
    }
  }
}

class _IdleView extends ConsumerWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String restaurant =
        ref.watch(deviceStateProvider).credentials?.restaurantName ?? '';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (restaurant.isNotEmpty)
            Text(
              restaurant.toUpperCase(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          const SizedBox(height: 24),
          Text(
            'Welcome',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Tap to begin',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _OrderView extends ConsumerWidget {
  const _OrderView({required this.state});
  final TillBroadcast state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NameLang lang = ref.watch(deviceStateProvider).displayLang;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Your order', style: Theme.of(context).textTheme.headlineMedium),
              if (state.orderNumber != null)
                Text(
                  state.orderNumber!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
            ],
          ),
          const Divider(),
          Expanded(child: _LineList(lines: state.lines, lang: lang)),
          const Divider(),
          _SummaryRow(label: 'Subtotal', value: state.subtotal),
          _SummaryRow(label: 'Tax', value: state.tax),
          const SizedBox(height: 8),
          _SummaryRow(label: 'TOTAL DUE', value: state.total, big: true),
        ],
      ),
    );
  }
}

class _PaymentView extends ConsumerWidget {
  const _PaymentView({required this.state});
  final TillBroadcast state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Please pay',
              style: Theme.of(context).textTheme.headlineMedium,),
          const Divider(),
          _SummaryRow(label: 'TOTAL DUE', value: state.total, big: true),
          const SizedBox(height: 16),
          if (state.payments.isNotEmpty) ...<Widget>[
            Text('Paid so far',
                style: Theme.of(context).textTheme.titleMedium,),
            const SizedBox(height: 8),
            for (final BroadcastPayment p in state.payments)
              _SummaryRow(label: '  ${p.method}', value: p.amount),
            const SizedBox(height: 16),
          ],
          _SummaryRow(label: 'Remaining', value: state.remaining, big: true),
          const Spacer(),
          if (state.remaining > 0 &&
              state.payments.any((BroadcastPayment p) =>
                  p.method == PaymentMethods.eftpos ||
                  p.method == PaymentMethods.card,))
            Center(
              child: Column(
                children: <Widget>[
                  Text(
                    'Insert or tap your card on the terminal',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.arrow_downward,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ThankYouView extends StatelessWidget {
  const _ThankYouView();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.check_circle, size: 96, color: cs.primary),
          const SizedBox(height: 16),
          Text('Thank you!',
              style: Theme.of(context).textTheme.displaySmall,),
          const SizedBox(height: 16),
          Text(
            'Your receipt is being printed.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _LineList extends StatelessWidget {
  const _LineList({required this.lines, required this.lang});

  final List<BroadcastLine> lines;
  final NameLang lang;

  static final NumberFormat _money =
      NumberFormat.simpleCurrency(decimalDigits: 2);

  String _renderName(BroadcastLine l) {
    final String alt = (l.nameLocalized ?? '').trim();
    switch (lang) {
      case NameLang.en:
        return l.name;
      case NameLang.vi:
        return alt.isEmpty ? l.name : alt;
      case NameLang.both:
        return alt.isEmpty ? l.name : '${l.name}\n$alt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: lines.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext c, int i) {
        final BroadcastLine l = lines[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _renderName(l),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: Text(
            '${_fmtQty(l.qty)} ×',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          trailing: Text(
            _money.format(l.total),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  static String _fmtQty(double q) =>
      q == q.truncate() ? q.toInt().toString() : q.toString();
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.big = false,
  });

  final String label;
  final double value;
  final bool big;

  static final NumberFormat _money =
      NumberFormat.simpleCurrency(decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = big
        ? Theme.of(context)
            .textTheme
            .headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: style),
          Text(_money.format(value), style: style),
        ],
      ),
    );
  }
}
