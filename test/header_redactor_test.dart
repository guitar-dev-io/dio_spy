import 'package:net_spy/src/utils/header_redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeaderRedactor.redactMap', () {
    test('returns original map unchanged when disabled', () {
      final values = {'Authorization': 'Bearer secret'};

      final result = HeaderRedactor.redactMap(
        values,
        enabled: false,
        sensitiveLower: {'authorization'},
      );

      expect(result, same(values));
    });

    test('returns original map unchanged when sensitive set is empty', () {
      final values = {'Authorization': 'Bearer secret'};

      final result = HeaderRedactor.redactMap(
        values,
        enabled: true,
        sensitiveLower: {},
      );

      expect(result, same(values));
    });

    test('masks values whose key matches (case-insensitively)', () {
      final values = {
        'Authorization': 'Bearer secret',
        'Content-Type': 'application/json',
      };

      final result = HeaderRedactor.redactMap(
        values,
        enabled: true,
        sensitiveLower: {'authorization'},
      );

      expect(result['Authorization'], HeaderRedactor.mask);
      expect(result['Content-Type'], 'application/json');
    });

    test('does not mutate the input map', () {
      final values = {'Authorization': 'Bearer secret'};

      HeaderRedactor.redactMap(values, enabled: true, sensitiveLower: {'authorization'});

      expect(values['Authorization'], 'Bearer secret');
    });
  });

  group('HeaderRedactor.redactCookies', () {
    test('returns original map unchanged when disabled', () {
      final cookies = {'session': 'abc123'};

      final result = HeaderRedactor.redactCookies(
        cookies,
        enabled: false,
        sensitiveLower: {'cookie'},
      );

      expect(result, same(cookies));
    });

    test('returns original map unchanged when cookie is not in sensitive set', () {
      final cookies = {'session': 'abc123'};

      final result = HeaderRedactor.redactCookies(
        cookies,
        enabled: true,
        sensitiveLower: {'authorization'},
      );

      expect(result, same(cookies));
    });

    test('masks every cookie value when "cookie" is sensitive', () {
      final cookies = {'session': 'abc123', 'user_id': '456'};

      final result = HeaderRedactor.redactCookies(
        cookies,
        enabled: true,
        sensitiveLower: {'cookie'},
      );

      expect(result['session'], HeaderRedactor.mask);
      expect(result['user_id'], HeaderRedactor.mask);
    });

    test('masks every cookie value when "set-cookie" is sensitive', () {
      final cookies = {'session': 'abc123'};

      final result = HeaderRedactor.redactCookies(
        cookies,
        enabled: true,
        sensitiveLower: {'set-cookie'},
      );

      expect(result['session'], HeaderRedactor.mask);
    });
  });
}
