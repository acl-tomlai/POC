import 'package:freezed_annotation/freezed_annotation.dart';

part 'printer.freezed.dart';
part 'printer.g.dart';

/// Printer type string the API stores: "Receipt" / "Kitchen".
class PrinterType {
  static const String receipt = 'Receipt';
  static const String kitchen = 'Kitchen';
}

@freezed
class Printer with _$Printer {
  const factory Printer({
    required String id,
    required String storeId,
    required String name,
    required String ipAddress,
    required int port,
    required String printerType,
    required bool isActive,
    required DateTime createdAt,
  }) = _Printer;

  factory Printer.fromJson(Map<String, dynamic> json) =>
      _$PrinterFromJson(json);
}
