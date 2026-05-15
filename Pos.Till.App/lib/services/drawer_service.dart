import '../models/printer.dart';
import 'printer_service.dart';

/// Cash-drawer wrapper. The drawer is wired to the receipt printer via RJ12;
/// kicking it is just an ESC/POS `drawer` command sent to that printer.
class DrawerService {
  DrawerService(this._printers);

  final PrinterService _printers;

  Future<PrintResult> kick(Printer receiptPrinter) async {
    final List<int> bytes = await _printers.drawerKickBytes();
    return _printers.send(printer: receiptPrinter, bytes: bytes);
  }
}
