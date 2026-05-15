import 'package:dio/dio.dart';

import '../models/printer.dart';
import 'api_client.dart';

class PrintersApi {
  PrintersApi(this._client);

  final ApiClient _client;

  Future<List<Printer>> listForStore(String storeId) {
    return _client.call<List<Printer>>(() async {
      final Response<List<dynamic>> r = await _client.dio
          .get<List<dynamic>>('/api/stores/$storeId/printers');
      return r.data!
          .cast<Map<String, dynamic>>()
          .map<Printer>(Printer.fromJson)
          .toList();
    });
  }
}
