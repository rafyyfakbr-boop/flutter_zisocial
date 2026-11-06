import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is List) {
        return {'data': data};
      }
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      (data is Map && data['message'] != null)
          ? data['message']
          : 'Terjadi kesalahan pada server (${response.statusCode}).',
    );
  }

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        if (!kIsWeb) 'Content-Type': 'application/json',
        if (!kIsWeb) 'ngrok-skip-browser-warning': 'true',
        ...?headers,
      },
    );

    return _handleResponse(response);
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
        if (!kIsWeb) 'ngrok-skip-browser-warning': 'true',
        ...?headers,
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (!kIsWeb) 'ngrok-skip-browser-warning': 'true',
        ...?headers,
      },
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> upload(
    String url, {
    required String filePath,
    Uint8List? fileBytes,
    String? fileName,
    required String fieldName,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (!kIsWeb) {
      request.headers['ngrok-skip-browser-warning'] = 'true';
    }

    if (kIsWeb && fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: fileName ?? 'upload.jpg',
        ),
      );
    } else {
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }
}
