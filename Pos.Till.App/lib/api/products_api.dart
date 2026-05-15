import 'package:dio/dio.dart';

import '../models/product.dart';
import 'api_client.dart';

class ProductsApi {
  ProductsApi(this._client);

  final ApiClient _client;

  Future<List<Product>> list() {
    return _client.call<List<Product>>(() async {
      final Response<List<dynamic>> r =
          await _client.dio.get<List<dynamic>>('/api/products');
      return r.data!
          .cast<Map<String, dynamic>>()
          .map<Product>(Product.fromJson)
          .toList();
    });
  }

  Future<Product> byBarcode(String barcode) {
    return _client.call<Product>(() async {
      final Response<Map<String, dynamic>> r =
          await _client.dio.get<Map<String, dynamic>>('/api/products/barcode/$barcode');
      return Product.fromJson(r.data!);
    });
  }
}
