import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_call.dart';
import '../models/http_error.dart';
import '../models/http_response.dart';

class NetSpyStorage {
  NetSpyStorage({
    this.maxCalls = 1000,
    this.persistent = false,
    this.retentionPeriod,
  }) {
    if (persistent) {
      _load();
    }
  }

  /// Maximum number of calls kept in the circular buffer.
  final int maxCalls;

  /// Whether captured calls are persisted to local storage
  /// (via `shared_preferences`) so they survive app restarts.
  final bool persistent;

  /// When set, calls older than this (by `createdTime`) are pruned
  /// automatically on insert and on load.
  final Duration? retentionPeriod;

  static const String _prefsKey = 'dio_spy_calls';

  final _calls = ValueNotifier<List<NetSpyHttpCall>>([]);
  SharedPreferences? _prefs;
  Timer? _saveTimer;

  ValueListenable<List<NetSpyHttpCall>> get calls => _calls;

  void addCall(NetSpyHttpCall call) {
    final list = List<NetSpyHttpCall>.from(_calls.value);
    list.insert(0, call);
    _pruneExpired(list);
    if (list.length > maxCalls) {
      list.removeRange(maxCalls, list.length);
    }
    _calls.value = list;
    _persist();
  }

  void addResponse(int id, NetSpyHttpResponse response) {
    final list = List<NetSpyHttpCall>.from(_calls.value);
    final index = list.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final call = list[index];
    call.response = response;
    call.loading = false;
    if (call.request != null) {
      call.duration =
          response.time.millisecondsSinceEpoch - call.request!.time.millisecondsSinceEpoch;
    }
    _calls.value = list;
    _persist();
  }

  void addError(int id, NetSpyHttpError error) {
    final list = List<NetSpyHttpCall>.from(_calls.value);
    final index = list.indexWhere((c) => c.id == id);
    if (index == -1) return;

    list[index].error = error;
    _calls.value = list;
    _persist();
  }

  /// Removes a single captured call.
  void removeCall(NetSpyHttpCall call) {
    final list = List<NetSpyHttpCall>.from(_calls.value)..remove(call);
    _calls.value = list;
    _persist();
  }

  void clear() {
    _calls.value = [];
    _persist();
  }

  // --- Persistence ---

  Future<void> _load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = json.decode(raw);
      if (decoded is! List) return;

      final restored = <NetSpyHttpCall>[];
      for (final item in decoded) {
        if (item is Map) {
          final call = NetSpyHttpCall.fromJson(item.cast<String, dynamic>());
          // Persisted calls will never complete, so drop any lingering
          // loading state to avoid a stuck spinner.
          call.loading = false;
          restored.add(call);
        }
      }

      // Keep any calls captured while loading was in-flight on top.
      final merged = [..._calls.value, ...restored];
      _pruneExpired(merged);
      if (merged.length > maxCalls) {
        merged.removeRange(maxCalls, merged.length);
      }
      _calls.value = merged;
    } catch (e) {
      debugPrint('[NetSpy] Failed to load persisted calls: $e');
    }
  }

  /// Removes calls older than [retentionPeriod] from [list] in place.
  void _pruneExpired(List<NetSpyHttpCall> list) {
    final period = retentionPeriod;
    if (period == null) return;
    final cutoff = DateTime.now().subtract(period);
    list.removeWhere((c) => c.createdTime.isBefore(cutoff));
  }

  void _persist() {
    if (!persistent) return;
    // Debounce writes so bursts of requests don't thrash local storage.
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final data = json.encode(_calls.value.map((c) => c.toJson()).toList());
      await _prefs!.setString(_prefsKey, data);
    } catch (e) {
      debugPrint('[NetSpy] Failed to persist calls: $e');
    }
  }

  /// Releases timers held by the storage.
  void dispose() {
    _saveTimer?.cancel();
  }
}
