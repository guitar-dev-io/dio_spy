/// Helper for masking sensitive header and cookie values.
class HeaderRedactor {
  /// The placeholder shown in place of a redacted value.
  static const String mask = '••••••••';

  /// Returns a copy of [values] with entries whose (lower-cased) key is in
  /// [sensitiveLower] replaced by [mask]. When [enabled] is `false` the
  /// original map is returned unchanged.
  static Map<String, String> redactMap(
    Map<String, String> values, {
    required bool enabled,
    required Set<String> sensitiveLower,
  }) {
    if (!enabled || sensitiveLower.isEmpty) return values;
    return values.map(
      (key, value) => MapEntry(
        key,
        sensitiveLower.contains(key.toLowerCase()) ? mask : value,
      ),
    );
  }

  /// Masks every value in [cookies] when cookies are treated as sensitive.
  static Map<String, String> redactCookies(
    Map<String, String> cookies, {
    required bool enabled,
    required Set<String> sensitiveLower,
  }) {
    final cookieIsSensitive = sensitiveLower.contains('cookie') ||
        sensitiveLower.contains('set-cookie');
    if (!enabled || !cookieIsSensitive) return cookies;
    return cookies.map((key, _) => MapEntry(key, mask));
  }
}
