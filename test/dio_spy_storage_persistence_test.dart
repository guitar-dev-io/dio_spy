import 'dart:convert';

import 'package:net_spy/src/core/dio_spy_storage.dart';
import 'package:net_spy/src/models/http_call.dart';
import 'package:net_spy/src/models/http_request.dart';
import 'package:net_spy/src/models/http_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<T> _pumpDebounce<T>(Future<T> Function() action) async {
  final result = await action();
  // _persist() debounces writes by 400ms.
  await Future.delayed(const Duration(milliseconds: 450));
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NetSpyStorage persistence', () {
    test('save then reload restores calls from shared_preferences', () async {
      final storage = NetSpyStorage(maxCalls: 10, persistent: true);

      final call = NetSpyHttpCall(1);
      call.method = 'GET';
      call.endpoint = '/api/users';
      call.request = NetSpyHttpRequest();
      await _pumpDebounce(() async => storage.addCall(call));

      final response = NetSpyHttpResponse()..status = 200;
      await _pumpDebounce(() async => storage.addResponse(1, response));

      storage.dispose();

      final reloaded = NetSpyStorage(maxCalls: 10, persistent: true);
      // _load() is async; give it a turn to complete.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(reloaded.calls.value.length, 1);
      expect(reloaded.calls.value.first.endpoint, '/api/users');
      expect(reloaded.calls.value.first.response?.status, 200);
      // Restored calls should never be stuck "loading".
      expect(reloaded.calls.value.first.loading, isFalse);

      reloaded.dispose();
    });

    test('migrates calls stored under the legacy dio_spy_calls key', () async {
      final legacyCall = NetSpyHttpCall(1)
        ..method = 'GET'
        ..endpoint = '/legacy';
      SharedPreferences.setMockInitialValues({
        'dio_spy_calls': json.encode([legacyCall.toJson()]),
      });

      final storage = NetSpyStorage(maxCalls: 10, persistent: true);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(storage.calls.value.length, 1);
      expect(storage.calls.value.first.endpoint, '/legacy');

      // The legacy key should be cleared after migration, and re-saving
      // should go to the new key.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('dio_spy_calls'), isNull);

      storage.dispose();
    });

    test('redacts sensitive headers/cookies before writing to disk', () async {
      final storage = NetSpyStorage(
        maxCalls: 10,
        persistent: true,
        sensitiveHeaders: {'authorization'},
      );

      final call = NetSpyHttpCall(1);
      call.request = NetSpyHttpRequest()
        ..headers = {'Authorization': 'Bearer super-secret', 'Content-Type': 'application/json'};
      await _pumpDebounce(() async => storage.addCall(call));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('net_spy_calls');
      expect(raw, isNotNull);
      expect(raw, isNot(contains('super-secret')));
      expect(raw, contains('application/json'));

      storage.dispose();
    });

    test('does not mutate the in-memory call when persisting', () async {
      final storage = NetSpyStorage(
        maxCalls: 10,
        persistent: true,
        sensitiveHeaders: {'authorization'},
      );

      final call = NetSpyHttpCall(1);
      call.request = NetSpyHttpRequest()..headers = {'Authorization': 'Bearer super-secret'};
      await _pumpDebounce(() async => storage.addCall(call));

      // The redaction toggle only affects display; the stored in-memory
      // object must still carry the real header value.
      expect(storage.calls.value.first.request?.headers['Authorization'], 'Bearer super-secret');

      storage.dispose();
    });

    test('pruneExpired removes calls older than retentionPeriod on load', () async {
      final oldCall = NetSpyHttpCall(
        1,
        createdTime: DateTime.now().subtract(const Duration(days: 2)),
      )..endpoint = '/old';
      final recentCall = NetSpyHttpCall(
        2,
        createdTime: DateTime.now(),
      )..endpoint = '/recent';

      SharedPreferences.setMockInitialValues({
        'net_spy_calls': json.encode([oldCall.toJson(), recentCall.toJson()]),
      });

      final storage = NetSpyStorage(
        maxCalls: 10,
        persistent: true,
        retentionPeriod: const Duration(hours: 1),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(storage.calls.value.length, 1);
      expect(storage.calls.value.first.endpoint, '/recent');

      storage.dispose();
    });
  });

  group('NetSpyStorage non-persistent mode', () {
    test('does not write to shared_preferences when persistent is false', () async {
      final storage = NetSpyStorage(maxCalls: 10, persistent: false);

      await _pumpDebounce(() async => storage.addCall(NetSpyHttpCall(1)));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('net_spy_calls'), isNull);

      storage.dispose();
    });
  });

  group('NetSpyStorage.dispose', () {
    test('disposes the calls ValueNotifier', () {
      final storage = NetSpyStorage(maxCalls: 10);
      storage.dispose();

      expect(() => storage.calls.addListener(() {}), throwsFlutterError);
    });
  });
}
