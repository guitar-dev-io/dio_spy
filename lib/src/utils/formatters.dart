import 'dart:convert';

class NetSpyFormatters {
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatDuration(int milliseconds) {
    if (milliseconds < 0) return '0 ms';
    if (milliseconds < 1000) return '$milliseconds ms';
    final seconds = milliseconds / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(1)}m';
  }

  static String formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  static String formatDateTime(DateTime time) {
    final date =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    return '$date ${formatTime(time)}';
  }

  static String formatBody(dynamic body) {
    if (body == null) return '';
    if (body is String) {
      try {
        final decoded = json.decode(body);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return body;
      }
    }
    if (body is Map || body is List) {
      // The body can contain values that are not JSON-encodable (e.g. a Color
      // or any custom object). Fall back to a plain string form so rendering a
      // captured call never throws.
      try {
        return const JsonEncoder.withIndent('  ').convert(body);
      } catch (_) {
        return body.toString();
      }
    }
    return body.toString();
  }

  /// Whether [body] can be safely serialized with `json.encode`.
  ///
  /// Used to decide whether a body is safe to hand to the interactive JSON
  /// viewer, which walks and encodes the value and would otherwise throw on a
  /// non-encodable entry (e.g. a `Color` nested in a request/response body).
  static bool isJsonEncodable(dynamic body) {
    if (body == null || body is String || body is num || body is bool) {
      return true;
    }
    if (body is Map || body is List) {
      try {
        json.encode(body);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Recursively converts [body] into a structure the interactive JSON viewer
  /// can consume, where every map is a `Map<String, dynamic>` and every list is
  /// a `List<dynamic>`.
  ///
  /// `JsonVisualizer` hard-casts map values with `as Map<String, dynamic>`,
  /// which throws for a `Map<dynamic, dynamic>` / `Map<String, Object?>` or a
  /// nested map with non-`String` keys — shapes Dio commonly produces. This
  /// returns `null` when the body can't be represented that way (e.g. a map
  /// with non-`String` keys), signalling the caller to fall back to raw text.
  static dynamic normalizeForVisualizer(dynamic body) {
    if (body == null || body is String || body is num || body is bool) {
      return body;
    }
    if (body is Map) {
      final result = <String, dynamic>{};
      for (final entry in body.entries) {
        if (entry.key is! String) return null;
        result[entry.key as String] = normalizeForVisualizer(entry.value);
      }
      return result;
    }
    if (body is List) {
      return body.map(normalizeForVisualizer).toList();
    }
    // Any other type isn't something the viewer can render safely.
    return null;
  }

  static String formatStatusCode(int? statusCode) {
    if (statusCode == null || statusCode == -1) return 'Error';
    return statusCode.toString();
  }
}
