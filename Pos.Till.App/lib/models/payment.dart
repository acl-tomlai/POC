import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

/// Payment method strings the till sends to the API.
class PaymentMethods {
  static const String cash = 'Cash';
  static const String eftpos = 'EFTPOS';
  static const String card = 'Card';
}

@freezed
class PaymentCreateRequest with _$PaymentCreateRequest {
  const factory PaymentCreateRequest({
    required String paymentMethod,
    required double amount,
    String? reference,
  }) = _PaymentCreateRequest;

  factory PaymentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateRequestFromJson(json);
}
