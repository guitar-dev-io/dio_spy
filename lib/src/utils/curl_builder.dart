import 'dart:convert';

import '../models/http_call.dart';
import 'header_redactor.dart';

class CurlBuilder {
  /// Builds a cURL command for [call].
  ///
  /// [redactHeaders] is a lower-cased set of header names whose values (and
  /// cookies, when `cookie`/`set-cookie` is included) are masked. Pass `null`
  /// or an empty set to include real values.
  static String build(NetSpyHttpCall call, {Set<String>? redactHeaders}) {
    final request = call.request;
    if (request == null) return '';

    final redact = redactHeaders ?? const <String>{};

    final parts = <String>[];
    parts.add('curl -X ${call.method}');
    parts.add(_quote(call.uri));

    // Headers
    request.headers.forEach((key, value) {
      final shown = redact.contains(key.toLowerCase()) ? HeaderRedactor.mask : value;
      parts.add('-H ${_quote('$key: $shown')}');
    });

    // Cookies
    if (request.cookies.isNotEmpty) {
      final cookieSensitive = redact.contains('cookie') || redact.contains('set-cookie');
      final cookieStr = cookieSensitive
          ? HeaderRedactor.mask
          : request.cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      parts.add('--cookie ${_quote(cookieStr)}');
    }

    // Body
    final bodyStr = _bodyToString(request.body);
    if (bodyStr.isNotEmpty) {
      parts.add('-d ${_quote(bodyStr)}');
    }

    return parts.join(' \\\n  ');
  }

  static String buildAll(List<NetSpyHttpCall> calls, {Set<String>? redactHeaders}) {
    return calls
        .map((c) => build(c, redactHeaders: redactHeaders))
        .where((s) => s.isNotEmpty)
        .join('\n\n');
  }

  /// Serializes a request body for a shell command.
  ///
  /// Maps and lists are encoded as compact JSON so the resulting command is a
  /// valid payload (Dart's `toString()` would produce non-JSON output).
  static String _bodyToString(dynamic body) {
    if (body == null) return '';
    if (body is String) return body;
    if (body is Map || body is List) {
      try {
        return json.encode(body);
      } catch (_) {
        return body.toString();
      }
    }
    return body.toString();
  }

  /// Wraps [value] in single quotes with POSIX-safe escaping.
  ///
  /// A single quote cannot be escaped inside single quotes, so it is closed,
  /// an escaped quote is inserted, and the quote is reopened: `'\''`.
  static String _quote(String value) {
    return "'${value.replaceAll("'", r"'\''")}'";
  }
}
