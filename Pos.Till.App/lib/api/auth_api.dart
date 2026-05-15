import 'package:dio/dio.dart';

import '../models/login_response.dart';
import 'api_client.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<LoginResponse> login(LoginRequest req) {
    return _client.call<LoginResponse>(() async {
      final Response<Map<String, dynamic>> r = await _client.dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: req.toJson(),
      );
      return LoginResponse.fromJson(r.data!);
    });
  }
}
