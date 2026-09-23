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

  /// Key used to stash a stable per-request correlation id in
  /// [RequestOptions.extra]. `RequestOptions.hashCode` (the previous
  /// correlation key) is an identity hash: if an app-level interceptor
  /// retries a request with a cloned `RequestOptions`, the hash changes and
  /// the response/error is silently orphaned, leaving the original entry
  /// stuck in the "loading" state. A monotonic id stored in `extra` survives
  /// `copyWith`/cloning because Dio carries `extra` along with the request.
  static const String _idKey = '_netSpyRequestId';

  int _nextId = 0;

  int _idFor(RequestOptions options) {
    final existing = options.extra[_idKey];
    if (existing is int) return existing;
    final id = _nextId++;
    options.extra[_idKey] = id;
    return id;
  }

  /// Maximum number of bytes kept for a captured request/response body.
  /// Bodies larger than this are truncated before being stored, independent
  /// of [NetSpyStorage.maxCalls], so a handful of large payloads (file
  /// uploads/downloads) can't blow up memory or persisted storage size.
  static const int maxBodyBytes = 200 * 1024; // 200 KB

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) {
      handler.next(options);
      return;
    }
    try {
      final call = NetSpyHttpCall(_idFor(options));
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
      httpResponse.size = _safeBodySize(data);
      httpResponse.body = _truncateBody(data, httpResponse.size);

      _storage.addResponse(_idFor(response.requestOptions), httpResponse);
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
      final id = _idFor(err.requestOptions);
      _storage.addError(id, httpError);

      final httpResponse = NetSpyHttpResponse();
      httpResponse.time = DateTime.now();

      if (err.response != null) {
        httpResponse.status = err.response?.statusCode;
        final data = err.response?.data;
        httpResponse.size = _safeBodySize(data);
        httpResponse.body = _truncateBody(data, httpResponse.size);
        httpResponse.headers = _parseResponseHeaders(err.response!.headers);
      } else {
        httpResponse.status = -1;
      }

      _storage.addResponse(id, httpResponse);
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
      // A body can contain values that are not JSON-encodable; fall back to a
      // best-effort size so an odd payload never drops the whole capture.
      request.size = _safeBodySize(data);
      request.body = _truncateBody(data, request.size);
    } else if (data is String) {
      request.size = utf8.encode(data).length;
      request.body = _truncateBody(data, request.size);
    } else if (data is List<int>) {
      request.body = '[Binary data]';
      request.size = data.length;
    } else if (data is Stream) {
      request.body = '[Stream data]';
      request.size = 0;
    } else {
      request.size = _safeBodySize(data);
      request.body = _truncateBody(data, request.size);
    }
  }

  /// Caps a captured body at [maxBodyBytes]. Maps/Lists are only truncated by
  /// falling back to their (possibly truncated) string form; this keeps
  /// memory and persisted-storage usage bounded per-call, independent of how
  /// many calls [NetSpyStorage.maxCalls] allows.
  dynamic _truncateBody(dynamic data, int size) {
    if (data == null || size <= maxBodyBytes) return data;

    final asString = data is String ? data : _bodyToDisplayString(data);
    final bytes = utf8.encode(asString);
    if (bytes.length <= maxBodyBytes) return asString;

    final truncated =
        utf8.decode(bytes.sublist(0, maxBodyBytes), allowMalformed: true);
    return '$truncated\n… [truncated, ${_safeBodySize(data)} bytes total]';
  }

  String _bodyToDisplayString(dynamic data) {
    if (data is Map || data is List) {
      try {
        return json.encode(data);
      } catch (_) {
        return data.toString();
      }
    }
    return data.toString();
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
