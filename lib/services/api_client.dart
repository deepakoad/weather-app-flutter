import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client;
  final Duration timeout;

  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  Future<dynamic> getJson(Uri uri) async {
    try {
      print("--------------------------------------------------");
      print("REQUEST → $uri");

      final res = await _client.get(
        uri,
        headers: {
          'User-Agent': 'project_mohali_flutter_app',
        },
      ).timeout(timeout);

      print("STATUS  → ${res.statusCode}");
      print("BODY    → ${res.body}");
      print("--------------------------------------------------");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return json.decode(res.body);
      }

      throw HttpException('HTTP ${res.statusCode}');
    } on SocketException {
      print("SOCKET ERROR");
      throw Exception('No internet connection');
    } on TimeoutException {
      print("TIMEOUT ERROR");
      throw Exception('Request timeout');
    } catch (e) {
      print("UNKNOWN ERROR → $e");
      rethrow;
    }
  }



}

