import 'dart:convert';

/// Helpers shared by the model `toJson`/`fromJson` implementations used for
/// persisting captured calls to local storage.

/// Returns a value that is safe to embed in a `toJson()` map.
///
/// Bodies captured from Dio can be anything (Map, List, String, bytes, custom
/// objects). Primitives, Maps and Lists are passed through unchanged —
/// [encodeJsonSafe] handles any non-encodable values they contain (via
/// `toEncodable`) in a single pass at the point of actual serialization, so
/// callers no longer pay for a separate probe-encode of the whole body here.
/// Anything else is converted to its string form up front since it can never
/// be JSON-encoded directly.
dynamic jsonSafe(dynamic value) {
  if (value == null ||
      value is String ||
      value is num ||
      value is bool ||
      value is Map ||
      value is List) {
    return value;
  }
  return value.toString();
}

/// Encodes [value] to a JSON string, falling back to `toString()` for any
/// value (nested arbitrarily deep) that [json.encode] cannot serialize
/// natively. This does the "is it encodable" work exactly once, at the point
/// where the JSON string is actually produced.
String encodeJsonSafe(dynamic value) {
  return json.encode(value,
      toEncodable: (dynamic nonEncodable) => nonEncodable.toString());
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
