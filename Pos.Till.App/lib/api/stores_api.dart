import 'package:dio/dio.dart';

import '../models/store.dart';
import 'api_client.dart';

class StoresApi {
  StoresApi(this._client);

  final ApiClient _client;

  Future<List<Store>> list() {
    return _client.call<List<Store>>(() async {
      final Response<List<dynamic>> r = await _client.dio.get<List<dynamic>>('/api/stores');
      return r.data!
          .cast<Map<String, dynamic>>()
          .map<Store>(Store.fromJson)
          .toList();
    });
  }
}
