import 'package:net_spy/src/core/dio_spy_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetSpyConfig', () {
    test('uses default title and sensitive headers when not provided', () {
      final config = NetSpyConfig();

      expect(config.title, 'SPY x DIO');
      expect(config.sensitiveHeaders, NetSpyConfig.defaultSensitiveHeaders);
      expect(config.redactSensitive.value, isFalse);

      config.dispose();
    });

    test('lower-cases custom sensitive headers', () {
      final config = NetSpyConfig(sensitiveHeaders: {'X-My-Token', 'Custom-Secret'});

      expect(config.sensitiveHeaders, {'x-my-token', 'custom-secret'});

      config.dispose();
    });

    test('honors redactByDefault', () {
      final config = NetSpyConfig(redactByDefault: true);

      expect(config.redactSensitive.value, isTrue);

      config.dispose();
    });

    test('isSensitive is case-insensitive', () {
      final config = NetSpyConfig(sensitiveHeaders: {'authorization'});

      expect(config.isSensitive('Authorization'), isTrue);
      expect(config.isSensitive('AUTHORIZATION'), isTrue);
      expect(config.isSensitive('x-other'), isFalse);

      config.dispose();
    });

    test('default sensitive header set covers common auth headers', () {
      const defaults = NetSpyConfig.defaultSensitiveHeaders;

      expect(defaults, contains('authorization'));
      expect(defaults, contains('cookie'));
      expect(defaults, contains('set-cookie'));
      expect(defaults, contains('x-api-key'));
    });

    test('dispose() disposes the redactSensitive notifier', () {
      final config = NetSpyConfig();
      config.dispose();

      // Adding a listener after dispose throws for a disposed ValueNotifier.
      expect(
        () => config.redactSensitive.addListener(() {}),
        throwsFlutterError,
      );
    });
  });
}
