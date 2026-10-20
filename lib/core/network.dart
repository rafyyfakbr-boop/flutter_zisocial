import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'Terjadi kesalahan pada server.',
    );
  }

  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }
  
    Future<Map<String, dynamic>> upload(
    String url, {
    required String filePath,
    required String fieldName,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        filePath,
      ),
    );

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    return _handleResponse(response);
  }
}

