import 'dart:async';
import 'dart:io';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../models/printer.dart';
import '../state/device_state.dart';
import 'localization_service.dart';

class PrintResult {
  const PrintResult({required this.ok, this.error});
  final bool ok;
  final String? error;
}

/// Generates ESC/POS byte payloads and sends them to a printer over TCP.
///
/// Three rendering pipelines:
/// * [buildReceipt] — full order with tendered payments, opens drawer if
///   any tender was Cash.
/// * [buildKitchen] — line items only, filtered to kitchen-relevant ones.
/// * [drawerKickBytes] — standalone drawer kick.
///
/// The `build*` methods are pure and unit-testable; the network side is
/// confined to [send].
class PrinterService {
  PrinterService({LocalizationService? l10n})
      : _l10n = l10n ?? const LocalizationService();

  final LocalizationService _l10n;
  CapabilityProfile? _profile;

  Future<CapabilityProfile> _loadProfile() async {
    return _profile ??= await CapabilityProfile.load();
  }

  /// Opens a TCP connection, writes bytes, closes. Returns ok/error so the
  /// caller can surface a snackbar; the order itself is already persisted
  /// server-side, so a print failure is recoverable.
  Future<PrintResult> send({
    required Printer printer,
    required List<int> bytes,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final Socket socket = await Socket.connect(
        printer.ipAddress,
        printer.port,
        timeout: timeout,
      );
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      return const PrintResult(ok: true);
    } on SocketException catch (e) {
      return PrintResult(ok: false, error: 'Printer ${printer.name}: ${e.message}');
    } on TimeoutException {
      return PrintResult(
        ok: false,
        error: 'Printer ${printer.name}: connection timed out',
      );
    }
  }

  // ---------- byte builders ----------

  Future<List<int>> buildKitchen({
    required Order order,
    required NameLang lang,
    required String restaurantName,
    String? storeName,
  }) async {
    final Generator g = Generator(PaperSize.mm80, await _loadProfile());
    final List<int> b = <int>[];
    b.addAll(g.reset());
    b.addAll(g.text(
      'KITCHEN',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ),);
    if (storeName != null && storeName.isNotEmpty) {
      b.addAll(g.text(
        '$restaurantName · $storeName',
        styles: const PosStyles(align: PosAlign.center),
      ),);
    }
    b.addAll(g.text(
      order.orderNumber,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ),);
    b.addAll(g.text(
      _fmtDateTime(order.createdAt),
      styles: const PosStyles(align: PosAlign.center),
    ),);
    b.addAll(g.hr());
    for (final OrderLine line in order.lines) {
      final String rendered = _renderLineName(line, lang);
      b.addAll(g.row(<PosColumn>[
        PosColumn(
          width: 2,
          text: '${_fmtQty(line.quantity)}×',
          styles: const PosStyles(bold: true, height: PosTextSize.size2),
        ),
        PosColumn(
          width: 10,
          text: rendered,
          styles: const PosStyles(bold: true, height: PosTextSize.size2),
        ),
      ]),);
    }
    b.addAll(g.feed(1));
    b.addAll(g.cut());
    return b;
  }

  Future<List<int>> buildReceipt({
    required Order order,
    required NameLang lang,
    required String restaurantName,
    String? storeName,
    String? cashierName,
  }) async {
    final Generator g = Generator(PaperSize.mm80, await _loadProfile());
    final List<int> b = <int>[];
    b.addAll(g.reset());
    b.addAll(g.text(
      restaurantName,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ),);
    if (storeName != null && storeName.isNotEmpty) {
      b.addAll(g.text(
        storeName,
        styles: const PosStyles(align: PosAlign.center),
      ),);
    }
    b.addAll(g.hr());
    b.addAll(g.row(<PosColumn>[
      PosColumn(width: 8, text: order.orderNumber, styles: const PosStyles(bold: true)),
      PosColumn(
        width: 4,
        text: _fmtDateTime(order.createdAt),
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]),);
    if (cashierName != null && cashierName.isNotEmpty) {
      b.addAll(g.text('Cashier: $cashierName'));
    }
    b.addAll(g.hr());
    for (final OrderLine line in order.lines) {
      final String rendered = _renderLineName(line, lang);
      b.addAll(g.row(<PosColumn>[
        PosColumn(width: 2, text: '${_fmtQty(line.quantity)}×'),
        PosColumn(width: 7, text: rendered),
        PosColumn(
          width: 3,
          text: _fmtMoney(line.lineTotal),
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),);
      if (line.discountAmount > 0) {
        b.addAll(g.row(<PosColumn>[
          PosColumn(width: 2, text: ''),
          PosColumn(width: 7, text: '  Discount'),
          PosColumn(
            width: 3,
            text: '-${_fmtMoney(line.discountAmount)}',
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),);
      }
    }
    b.addAll(g.hr());
    b.addAll(_amountRow(g, 'Subtotal', order.subtotal));
    if (order.discountAmount > 0) {
      b.addAll(_amountRow(g, 'Discount', -order.discountAmount));
    }
    b.addAll(_amountRow(g, 'Tax', order.taxAmount));
    b.addAll(_amountRow(
      g,
      'TOTAL',
      order.totalAmount,
      bold: true,
      size2: true,
    ),);
    if (order.payments.isNotEmpty) {
      b.addAll(g.hr());
      b.addAll(g.text('Paid', styles: const PosStyles(bold: true)));
      for (final Payment p in order.payments) {
        final String label = p.reference == null || p.reference!.isEmpty
            ? p.paymentMethod
            : '${p.paymentMethod} (${p.reference})';
        b.addAll(_amountRow(g, '  $label', p.amount));
      }
      final double tendered =
          order.payments.fold<double>(0, (double a, Payment p) => a + p.amount);
      final double change = tendered - order.totalAmount;
      if (change > 0) {
        b.addAll(_amountRow(g, '  Change', change));
      }
    }
    b.addAll(g.feed(1));
    b.addAll(g.text('Thanks!', styles: const PosStyles(align: PosAlign.center)));
    b.addAll(g.feed(1));
    b.addAll(g.cut());
    return b;
  }

  /// Standalone drawer-kick payload (used by the Settings "Test drawer
  /// kick" button and by the receipt-print path when at least one tender
  /// is Cash).
  Future<List<int>> drawerKickBytes() async {
    final Generator g = Generator(PaperSize.mm80, await _loadProfile());
    return g.drawer();
  }

  // ---------- formatting helpers ----------

  String _renderLineName(OrderLine line, NameLang lang) {
    // OrderLineResponse only carries the primary `productName`. If we ever
    // pass `nameLocalized` through the order DTO, plumb it here. For v1 the
    // kitchen ticket falls back to the primary; the cart-side path (used
    // by the customer display + receipt-from-cart in phase 4) passes the
    // localized name through `LocalizationService.resolve` directly.
    return _l10n.resolve(name: line.productName, lang: lang);
  }

  List<int> _amountRow(
    Generator g,
    String label,
    double amount, {
    bool bold = false,
    bool size2 = false,
  }) {
    final PosStyles style = PosStyles(
      bold: bold,
      height: size2 ? PosTextSize.size2 : PosTextSize.size1,
      width: size2 ? PosTextSize.size2 : PosTextSize.size1,
    );
    return g.row(<PosColumn>[
      PosColumn(width: 8, text: label, styles: style),
      PosColumn(
        width: 4,
        text: _fmtMoney(amount),
        styles: style.copyWith(align: PosAlign.right),
      ),
    ]);
  }

  static final NumberFormat _money = NumberFormat.simpleCurrency(decimalDigits: 2);
  static final DateFormat _dt = DateFormat('yyyy-MM-dd HH:mm');

  static String _fmtMoney(double n) => _money.format(n);
  static String _fmtDateTime(DateTime t) => _dt.format(t.toLocal());
  static String _fmtQty(double q) => q == q.truncate() ? q.toInt().toString() : q.toString();
}
