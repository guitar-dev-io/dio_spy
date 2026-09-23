import 'package:dio/dio.dart';
import 'package:net_spy/net_spy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetSpy', () {
    test('enabled defaults to kDebugMode when not provided', () {
      final netSpy = NetSpy(showOnShake: false);

      expect(netSpy.enabled, kDebugMode);

      netSpy.dispose();
    });

    test('enabled can be forced regardless of kDebugMode', () {
      final enabledSpy = NetSpy(showOnShake: false, enabled: true);
      final disabledSpy = NetSpy(showOnShake: false, enabled: false);

      expect(enabledSpy.enabled, isTrue);
      expect(disabledSpy.enabled, isFalse);

      enabledSpy.dispose();
      disabledSpy.dispose();
    });

    test('exposes a config with the given title and redaction default', () {
      final netSpy = NetSpy(
        showOnShake: false,
        title: 'My Inspector',
        redactHeaders: true,
      );

      expect(netSpy.config.title, 'My Inspector');
      expect(netSpy.config.redactSensitive.value, isTrue);

      netSpy.dispose();
    });

    group('attachTo', () {
      test('adds the interceptor to a Dio instance', () {
        final netSpy = NetSpy(showOnShake: false, enabled: true);
        final dio = Dio();

        final returned = netSpy.attachTo(dio);

        expect(returned, same(dio));
        expect(dio.interceptors.contains(netSpy.interceptor), isTrue);

        netSpy.dispose();
      });

      test('does not attach the interceptor twice to the same Dio instance', () {
        final netSpy = NetSpy(showOnShake: false, enabled: true);
        final dio = Dio();

        netSpy.attachTo(dio);
        netSpy.attachTo(dio);

        final count =
            dio.interceptors.where((i) => i == netSpy.interceptor).length;
        expect(count, 1);

        netSpy.dispose();
      });
    });

    group('attachToAll', () {
      test('attaches the interceptor to every Dio instance', () {
        final netSpy = NetSpy(showOnShake: false, enabled: true);
        final dioA = Dio();
        final dioB = Dio();

        netSpy.attachToAll([dioA, dioB]);

        expect(dioA.interceptors.contains(netSpy.interceptor), isTrue);
        expect(dioB.interceptors.contains(netSpy.interceptor), isTrue);

        netSpy.dispose();
      });
    });

    group('showInspector / hideInspector', () {
      test('toggle inspectorVisible', () {
        final netSpy = NetSpy(showOnShake: false);

        expect(netSpy.inspectorVisible.value, isFalse);

        netSpy.showInspector();
        expect(netSpy.inspectorVisible.value, isTrue);

        netSpy.hideInspector();
        expect(netSpy.inspectorVisible.value, isFalse);

        netSpy.dispose();
      });
    });

    group('dispose', () {
      test('disposes inspectorVisible and config notifiers', () {
        final netSpy = NetSpy(showOnShake: false);
        netSpy.dispose();

        expect(
          () => netSpy.inspectorVisible.addListener(() {}),
          throwsFlutterError,
        );
        expect(
          () => netSpy.config.redactSensitive.addListener(() {}),
          throwsFlutterError,
        );
      });

      test('is safe to call even if setNavigatorKey was never called', () {
        final netSpy = NetSpy(showOnShake: false);
        expect(() => netSpy.dispose(), returnsNormally);
      });
    });
  });
}
