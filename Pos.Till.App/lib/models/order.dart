import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// API order status strings.
class OrderStatus {
  static const String open = 'Open';
  static const String sent = 'Sent';
  static const String paid = 'Paid';
  static const String cancelled = 'Cancelled';
}

/// API payment status strings.
class PaymentStatus {
  static const String unpaid = 'Unpaid';
  static const String partial = 'Partial';
  static const String paid = 'Paid';
}

@freezed
class OrderLineRequest with _$OrderLineRequest {
  const factory OrderLineRequest({
    required String productId,
    required double quantity,
    required double unitPrice,
    required double discountAmount,
  }) = _OrderLineRequest;

  factory OrderLineRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderLineRequestFromJson(json);
}

@freezed
class OrderCreateRequest with _$OrderCreateRequest {
  const factory OrderCreateRequest({
    required String storeId,
    required double discountAmount,
    required double taxAmount,
    String? paymentMethod,
    String? paymentReference,
    double? paymentAmount,
    required List<OrderLineRequest> lines,
  }) = _OrderCreateRequest;

  factory OrderCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderCreateRequestFromJson(json);
}

@freezed
class OrderStatusUpdateRequest with _$OrderStatusUpdateRequest {
  const factory OrderStatusUpdateRequest({
    required String status,
  }) = _OrderStatusUpdateRequest;

  factory OrderStatusUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusUpdateRequestFromJson(json);
}

@freezed
class OrderLine with _$OrderLine {
  const factory OrderLine({
    required String id,
    required String productId,
    required String productName,
    required double quantity,
    required double unitPrice,
    required double discountAmount,
    required double lineTotal,
  }) = _OrderLine;

  factory OrderLine.fromJson(Map<String, dynamic> json) =>
      _$OrderLineFromJson(json);
}

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String paymentMethod,
    required double amount,
    String? reference,
    required DateTime paidAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String storeId,
    required String orderNumber,
    required String status,
    required double subtotal,
    required double taxAmount,
    required double discountAmount,
    required double totalAmount,
    required String paymentStatus,
    required String createdByUserId,
    required DateTime createdAt,
    required List<OrderLine> lines,
    required List<Payment> payments,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
