import 'package:dio/dio.dart';

import '../models/tenant.dart';
import 'api_client.dart';

class TenantsApi {
  TenantsApi(this._client);

  final ApiClient _client;

  Future<Tenant> me() {
    return _client.call<Tenant>(() async {
      final Response<Map<String, dynamic>> r =
          await _client.dio.get<Map<String, dynamic>>('/api/tenants/me');
      return Tenant.fromJson(r.data!);
    });
  }
}
