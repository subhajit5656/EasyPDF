import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/recent_document.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const _baseUrl = String.fromEnvironment('EASYPDF_API_BASE_URL');
  static const _requestTimeout = Duration(seconds: 15);

  Future<List<RecentDocument>> getRecentDocuments() async {
    final response = await _request('GET', '/v1/documents?limit=10');
    try {
      final documents = jsonDecode(response);
      if (documents is! List<dynamic>) {
        throw const ApiException('The document service returned invalid data.');
      }
      return documents
          .map(
            (document) => RecentDocument.fromJson(
              document as Map<String, dynamic>,
            ),
          )
          .toList();
    } on FormatException {
      throw const ApiException('The document service returned invalid data.');
    } on TypeError {
      throw const ApiException('The document service returned invalid data.');
    }
  }

  Future<RecentDocument> recordDocument({
    required String fileName,
    required int pageCount,
    required int fileSizeBytes,
  }) async {
    final response = await _request(
      'POST',
      '/v1/documents',
      body: jsonEncode({
        'file_name': fileName,
        'page_count': pageCount,
        'file_size_bytes': fileSizeBytes,
      }),
    );
    return _parseDocument(response);
  }

  Future<void> deleteDocument(String id) async {
    await _request('DELETE', '/v1/documents/$id');
  }

  Future<String> _request(
    String method,
    String path, {
    String? body,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const ApiException(
        'Backend is not configured. Set EASYPDF_API_BASE_URL to your HTTPS API URL.',
      );
    }

    final baseUri = Uri.tryParse(_baseUrl);
    if (baseUri == null ||
        !baseUri.hasAuthority ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        (baseUri.scheme != 'https' &&
            !(kDebugMode && baseUri.scheme == 'http'))) {
      throw const ApiException(
        'The API URL must use HTTPS (HTTP is allowed only in debug builds).',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ApiException('Sign in to access your document history.');
    }

    String? token;
    try {
      token = await user.getIdToken();
    } on FirebaseAuthException {
      throw const ApiException('Could not obtain an authentication token.');
    }
    if (token == null || token.isEmpty) {
      throw const ApiException('Could not obtain an authentication token.');
    }

    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final uri = baseUri.resolve(path);
      final request = await client.openUrl(method, uri).timeout(_requestTimeout);
      request.followRedirects = false;
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(body);
      }

      final response = await request.close().timeout(_requestTimeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'The document service could not complete the request.';
        try {
          final error = jsonDecode(responseBody) as Map<String, dynamic>;
          if (error['detail'] is String) {
            message = error['detail'] as String;
          }
        } on FormatException {
          // Keep the generic message when an intermediary returns non-JSON.
        } on TypeError {
          // Keep the generic message when an intermediary returns invalid JSON.
        }
        throw ApiException(message);
      }
      return responseBody;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('The document service request timed out.');
    } on SocketException {
      throw const ApiException('Could not reach the document service.');
    } on HttpException {
      throw const ApiException('The document service returned an HTTP error.');
    } on FormatException {
      throw const ApiException('The document service returned invalid data.');
    } on IOException {
      throw const ApiException('Could not complete the document service request.');
    } finally {
      client.close(force: true);
    }
  }

  RecentDocument _parseDocument(String response) {
    try {
      final document = jsonDecode(response);
      if (document is! Map<String, dynamic>) {
        throw const ApiException('The document service returned invalid data.');
      }
      return RecentDocument.fromJson(document);
    } on FormatException {
      throw const ApiException('The document service returned invalid data.');
    } on TypeError {
      throw const ApiException('The document service returned invalid data.');
    }
  }
}
