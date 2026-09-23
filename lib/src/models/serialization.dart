import 'dart:convert';

/// Helpers shared by the model `toJson`/`fromJson` implementations used for
/// persisting captured calls to local storage.

/// Returns a value that is guaranteed to be JSON-encodable.
///
/// Bodies captured from Dio can be anything (Map, List, String, bytes, custom
/// objects). Anything that cannot be encoded is converted to its string form so
/// persistence never fails on a single odd payload.
dynamic jsonSafe(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is Map || value is List) {
    try {
      json.encode(value);
      return value;
    } catch (_) {
      return value.toString();
    }
  }
  return value.toString();
}

/// Coerces any decoded map into a `Map<String, String>`.
Map<String, String> stringMap(dynamic value) {
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), '$val'));
  }
  return {};
}

/// Coerces any decoded map into a `Map<String, dynamic>`.
Map<String, dynamic> dynamicMap(dynamic value) {
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return {};
}

/// Restores a [DateTime] from a stored milliseconds-since-epoch value.
DateTime dateFromMillis(dynamic value) {
  final millis = (value as num?)?.toInt() ?? 0;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}
