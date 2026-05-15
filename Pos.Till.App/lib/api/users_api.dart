import 'package:dio/dio.dart';

import '../models/user.dart';
import 'api_client.dart';

class UsersApi {
  UsersApi(this._client);

  final ApiClient _client;

  Future<List<User>> list() {
    return _client.call<List<User>>(() async {
      final Response<List<dynamic>> r = await _client.dio.get<List<dynamic>>('/api/users');
      return r.data!
          .cast<Map<String, dynamic>>()
          .map<User>(User.fromJson)
          .toList();
    });
  }
}
