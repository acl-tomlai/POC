import 'package:dio/dio.dart';

import '../models/order.dart';
import 'api_client.dart';

class OrdersApi {
  OrdersApi(this._client);

  final ApiClient _client;

  Future<Order> create(OrderCreateRequest req) {
    return _client.call<Order>(() async {
      final Response<Map<String, dynamic>> r = await _client.dio
          .post<Map<String, dynamic>>('/api/orders', data: req.toJson());
      return Order.fromJson(r.data!);
    });
  }

  Future<Order> updateStatus(String id, String status) {
    return _client.call<Order>(() async {
      final Response<Map<String, dynamic>> r = await _client.dio
          .put<Map<String, dynamic>>(
        '/api/orders/$id/status',
        data: OrderStatusUpdateRequest(status: status).toJson(),
      );
      return Order.fromJson(r.data!);
    });
  }

  Future<Order> get(String id) {
    return _client.call<Order>(() async {
      final Response<Map<String, dynamic>> r =
          await _client.dio.get<Map<String, dynamic>>('/api/orders/$id');
      return Order.fromJson(r.data!);
    });
  }
}
