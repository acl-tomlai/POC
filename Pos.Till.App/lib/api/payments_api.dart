import 'package:dio/dio.dart';

import '../models/order.dart' show Payment;
import '../models/payment.dart';
import 'api_client.dart';

class PaymentsApi {
  PaymentsApi(this._client);

  final ApiClient _client;

  Future<Payment> add(String orderId, PaymentCreateRequest req) {
    return _client.call<Payment>(() async {
      final Response<Map<String, dynamic>> r = await _client.dio
          .post<Map<String, dynamic>>(
        '/api/orders/$orderId/payments',
        data: req.toJson(),
      );
      return Payment.fromJson(r.data!);
    });
  }
}
