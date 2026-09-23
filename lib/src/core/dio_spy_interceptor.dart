import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/form_data_models.dart';
import '../models/http_call.dart';
import '../models/http_error.dart';
import '../models/http_request.dart';
import '../models/http_response.dart';
import 'dio_spy_storage.dart';

class NetSpyInterceptor extends InterceptorsWrapper {
  NetSpyInterceptor(this._storage, {this.enabled = true});

  final NetSpyStorage _storage;

  /// When `false`, requests/responses pass through without being captured.
  final bool enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) {
      handler.next(options);
      return;
    }
    try {
      final call = NetSpyHttpCall(options.hashCode);
      call.method = options.method;
      call.endpoint = options.uri.path;
      call.server = options.uri.host;
      call.uri = options.uri.toString();
      call.secure = options.uri.scheme == 'https';

      final request = NetSpyHttpRequest();
      request.time = DateTime.now();
      request.headers = _parseHeaders(options.headers);
      request.contentType = options.contentType;
      request.queryParameters = _parseQueryParameters(options);

      // Cookies
      final cookieHeader =
          options.headers['cookie'] ?? options.headers['Cookie'];
      if (cookieHeader is String && cookieHeader.isNotEmpty) {
        request.cookies = _parseCookies(cookieHeader);
      }

      // Body
      _parseRequestBody(options.data, request);

      call.request = request;
      call.response = NetSpyHttpResponse();
      _storage.addCall(call);
    } catch (e) {
      debugPrint('[NetSpy] Error in onRequest: $e');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled) {
      handler.next(response);
      return;
    }
    try {
      final httpResponse = NetSpyHttpResponse();
      httpResponse.status = response.statusCode;
      httpResponse.time = DateTime.now();
      httpResponse.headers = _parseResponseHeaders(response.headers);

      final data = response.data;
      httpResponse.body = data ?? '';
      httpResponse.size = _safeBodySize(data);

      _storage.addResponse(response.requestOptions.hashCode, httpResponse);
    } catch (e) {
      debugPrint('[NetSpy] Error in onResponse: $e');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) {
      handler.next(err);
      return;
    }
    try {
      final httpError =
          NetSpyHttpError(error: err.toString(), stackTrace: err.stackTrace);
      _storage.addError(err.requestOptions.hashCode, httpError);

      final httpResponse = NetSpyHttpResponse();
      httpResponse.time = DateTime.now();

      if (err.response != null) {
        httpResponse.status = err.response?.statusCode;
        final data = err.response?.data;
        httpResponse.body = data ?? '';
        httpResponse.size = _safeBodySize(data);
        httpResponse.headers = _parseResponseHeaders(err.response!.headers);
      } else {
        httpResponse.status = -1;
      }

      _storage.addResponse(err.requestOptions.hashCode, httpResponse);
    } catch (e) {
      debugPrint('[NetSpy] Error in onError: $e');
    }
    handler.next(err);
  }

  // --- Helpers ---

  void _parseRequestBody(dynamic data, NetSpyHttpRequest request) {
    if (data == null) {
      request.body = '';
      request.size = 0;
    } else if (data is FormData) {
      request.body = 'Form data';
      request.formDataFields = data.fields
          .map((e) => NetSpyFormDataField(name: e.key, value: e.value))
          .toList();
      request.formDataFiles = data.files
          .map(
            (e) => NetSpyFormDataFile(
              fileName: e.value.filename ?? '',
              contentType: e.value.contentType?.mimeType ?? '',
              length: e.value.length,
            ),
          )
          .toList();
      request.size = data.length;
    } else if (data is Map || data is List) {
      request.body = data;
      // A body can contain values that are not JSON-encodable; fall back to a
      // best-effort size so an odd payload never drops the whole capture.
      request.size = _safeBodySize(data);
    } else if (data is String) {
      request.body = data;
      request.size = utf8.encode(data).length;
    } else if (data is List<int>) {
      request.body = '[Binary data]';
      request.size = data.length;
    } else if (data is Stream) {
      request.body = '[Stream data]';
      request.size = 0;
    } else {
      request.body = data.toString();
      request.size = _safeBodySize(data);
    }
  }

  Map<String, dynamic> _parseQueryParameters(RequestOptions options) {
    if (options.uri.queryParameters.isNotEmpty) {
      return Map<String, dynamic>.from(options.uri.queryParameters);
    }
    if (options.queryParameters.isNotEmpty) {
      return Map<String, dynamic>.from(options.queryParameters);
    }
    return {};
  }

  int _safeBodySize(dynamic data) {
    if (data == null) return 0;
    try {
      if (data is Map || data is List) {
        // Prefer the encoded JSON size, but fall back to the string form when
        // the payload holds a non-encodable value.
        try {
          return utf8.encode(json.encode(data)).length;
        } catch (_) {
          return utf8.encode(data.toString()).length;
        }
      }
      return utf8.encode(data.toString()).length;
    } catch (_) {
      return 0;
    }
  }

  Map<String, String> _parseHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) => MapEntry(key, value.toString()));
  }

  Map<String, String> _parseResponseHeaders(Headers headers) {
    final map = <String, String>{};
    headers.forEach((name, values) {
      map[name] = values.join(', ');
    });
    return map;
  }

  /// Parse cookie header string into key-value map.
  Map<String, String> _parseCookies(String cookieHeader) {
    final map = <String, String>{};
    for (final part in cookieHeader.split(';')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex > 0) {
        map[trimmed.substring(0, eqIndex).trim()] =
            trimmed.substring(eqIndex + 1).trim();
      } else {
        map[trimmed] = '';
      }
    }
    return map;
  }
}
