import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shake_gesture/shake_gesture.dart';

import '../ui/call_list/call_list_screen.dart';
import 'dio_spy_config.dart';
import 'dio_spy_interceptor.dart';
import 'dio_spy_storage.dart';

/// HTTP inspector for Dio. Captures requests/responses and shows a debug UI.
///
/// ```dart
/// final netSpy = NetSpy();
/// dio.interceptors.add(netSpy.interceptor);
/// ```
/// Then set the navigatorKey to the [NetSpy] instance.
/// ```dart
/// final navigatorKey = GlobalKey<NavigatorState>();
/// netSpy.setNavigatorKey(navigatorKey);
/// MaterialApp(
///   navigatorKey: navigatorKey,
///   home: MyHomePage(),
/// )
/// ```
///
/// If you want to use the inspector without a navigatorKey,
/// you can use the [NetSpyWrapper] widget.
/// ```dart
/// MaterialApp(
///   builder: (context, child) => NetSpyWrapper(netSpy: netSpy, child: child!),
///   home: MyHomePage(),
/// )
/// ```
///
class NetSpy {
  /// Creates a NetSpy instance.
  ///
  /// - [showOnShake]: open the inspector when the device is shaken.
  /// - [maxCalls]: size of the in-memory circular buffer.
  /// - [persistent]: when `true`, captured calls are saved to local storage
  ///   (via `shared_preferences`) and restored on the next app launch.
  /// - [retentionPeriod]: when set, captured calls older than this are pruned
  ///   automatically (useful together with [persistent]).
  /// - [enabled]: master switch. Defaults to [kDebugMode] so NetSpy captures
  ///   nothing and shows no UI in release builds. Set `true` to force-enable.
  /// - [title]: label shown on top of the inspector (override with your own
  ///   internal name).
  /// - [sensitiveHeaders]: header names to mask when redaction is on. Defaults
  ///   to [NetSpyConfig.defaultSensitiveHeaders].
  /// - [redactHeaders]: whether header/cookie redaction starts enabled. It can
  ///   also be toggled at runtime from the inspector menu.
  NetSpy({
    bool showOnShake = true,
    int maxCalls = 1000,
    bool persistent = false,
    Duration? retentionPeriod,
    bool? enabled,
    String title = 'SPY x DIO',
    Set<String>? sensitiveHeaders,
    bool redactHeaders = false,
  }) : enabled = enabled ?? kDebugMode {
    _storage = NetSpyStorage(
      maxCalls: maxCalls,
      persistent: this.enabled && persistent,
      retentionPeriod: retentionPeriod,
    );
    _interceptor = NetSpyInterceptor(_storage, enabled: this.enabled);
    _config = NetSpyConfig(
      title: title,
      sensitiveHeaders: sensitiveHeaders,
      redactByDefault: redactHeaders,
    );

    if (this.enabled && showOnShake) {
      _onShake = showInspector;
      ShakeGesture.registerCallback(onShake: _onShake!);
    }
  }

  /// Whether NetSpy is active. When `false`, nothing is captured and the
  /// inspector UI (bubble/overlay) is not shown.
  final bool enabled;

  late final NetSpyConfig _config;

  /// Inspector configuration (title, header redaction).
  NetSpyConfig get config => _config;

  late final NetSpyStorage _storage;
  late final NetSpyInterceptor _interceptor;
  final ValueNotifier<bool> _inspectorVisible = ValueNotifier(false);

  GlobalKey<NavigatorState>? _navigatorKey;
  VoidCallback? _navigatorKeyListener;
  VoidCallback? _onShake;

  /// Storage of captured HTTP calls.
  NetSpyStorage get storage => _storage;

  /// Interceptor to add to your [Dio] instance.
  Interceptor get interceptor => _interceptor;

  /// Attaches the NetSpy interceptor to a [Dio] instance and returns it,
  /// so you can chain the call:
  ///
  /// ```dart
  /// final dio = netSpy.attachTo(Dio());
  /// ```
  ///
  /// The interceptor is only added once per instance, so it is safe to call
  /// this multiple times with the same [dio].
  Dio attachTo(Dio dio) {
    if (!dio.interceptors.contains(_interceptor)) {
      dio.interceptors.add(_interceptor);
    }
    return dio;
  }

  /// Attaches the NetSpy interceptor to multiple [Dio] instances at once.
  ///
  /// ```dart
  /// netSpy.attachToAll([authDio, apiDio, uploadDio]);
  /// ```
  void attachToAll(Iterable<Dio> dios) {
    for (final dio in dios) {
      attachTo(dio);
    }
  }

  /// Whether the inspector is currently visible.
  ValueListenable<bool> get inspectorVisible => _inspectorVisible;

  /// Pushes the inspector as a route on this navigator.
  /// See [NetSpyWrapper] for an alternative approach.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;

    if (_navigatorKeyListener != null) {
      _inspectorVisible.removeListener(_navigatorKeyListener!);
    }

    _navigatorKeyListener = () {
      if (_inspectorVisible.value) {
        final navigator = _navigatorKey?.currentState;
        if (navigator == null) {
          _inspectorVisible.value = false;
          return;
        }
        navigator
            .push(MaterialPageRoute(
                builder: (_) =>
                    CallListScreen(storage: _storage, config: _config)))
            .then((_) => _inspectorVisible.value = false);
      }
    };
    _inspectorVisible.addListener(_navigatorKeyListener!);
  }

  /// Opens the inspector.
  void showInspector() {
    _inspectorVisible.value = true;
  }

  /// Closes the inspector.
  void hideInspector() {
    _inspectorVisible.value = false;
  }

  /// Releases resources. Call when no longer needed.
  void dispose() {
    if (_onShake != null) {
      ShakeGesture.unregisterCallback(onShake: _onShake!);
    }
    if (_navigatorKeyListener != null) {
      _inspectorVisible.removeListener(_navigatorKeyListener!);
      _navigatorKeyListener = null;
    }
    _storage.dispose();
    _config.dispose();
    _inspectorVisible.dispose();
  }
}
