import 'package:flutter/foundation.dart';

/// Runtime configuration for the NetSpy inspector UI.
///
/// A single instance is created by [NetSpy] and shared with every inspector
/// screen so options like the title and header redaction stay consistent.
class NetSpyConfig {
  NetSpyConfig({
    this.title = 'SPY x DIO',
    Set<String>? sensitiveHeaders,
    bool redactByDefault = false,
  })  : sensitiveHeaders = (sensitiveHeaders ?? defaultSensitiveHeaders)
            .map((e) => e.toLowerCase())
            .toSet(),
        redactSensitive = ValueNotifier<bool>(redactByDefault);

  /// Header names (compared case-insensitively) whose values are hidden when
  /// redaction is enabled.
  static const Set<String> defaultSensitiveHeaders = {
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'api-key',
    'x-auth-token',
    'access-token',
    'refresh-token',
  };

  /// Title shown on the inspector's call-list screen.
  final String title;

  /// Lower-cased set of header names considered sensitive.
  final Set<String> sensitiveHeaders;

  /// Whether sensitive header/cookie values are currently masked in the UI and
  /// in generated cURL commands. Toggle this to update all inspector screens.
  final ValueNotifier<bool> redactSensitive;

  bool isSensitive(String headerName) => sensitiveHeaders.contains(headerName.toLowerCase());

  void dispose() => redactSensitive.dispose();
}
