import 'package:dio/dio.dart';

import '../models/category.dart';
import 'api_client.dart';

class CategoriesApi {
  CategoriesApi(this._client);

  final ApiClient _client;

  Future<List<Category>> list() {
    return _client.call<List<Category>>(() async {
      final Response<List<dynamic>> r =
          await _client.dio.get<List<dynamic>>('/api/categories');
      return r.data!
          .cast<Map<String, dynamic>>()
          .map<Category>(Category.fromJson)
          .toList();
    });
  }
}
