import 'package:net_spy/src/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetSpyFormatters', () {
    group('formatBytes', () {
      test('should format 0 bytes', () {
        expect(NetSpyFormatters.formatBytes(0), '0 B');
      });

      test('should format bytes less than 1 KB', () {
        expect(NetSpyFormatters.formatBytes(100), '100 B');
        expect(NetSpyFormatters.formatBytes(512), '512 B');
        expect(NetSpyFormatters.formatBytes(1023), '1023 B');
      });

      test('should format KB', () {
        expect(NetSpyFormatters.formatBytes(1024), '1.0 KB');
        expect(NetSpyFormatters.formatBytes(2048), '2.0 KB');
        expect(NetSpyFormatters.formatBytes(1536), '1.5 KB');
        expect(NetSpyFormatters.formatBytes(10240), '10.0 KB');
      });

      test('should format MB', () {
        expect(NetSpyFormatters.formatBytes(1048576), '1.0 MB');
        expect(NetSpyFormatters.formatBytes(2097152), '2.0 MB');
        expect(NetSpyFormatters.formatBytes(1572864), '1.5 MB');
      });

      test('should handle negative values', () {
        expect(NetSpyFormatters.formatBytes(-100), '0 B');
      });
    });

    group('formatDuration', () {
      test('should format milliseconds', () {
        expect(NetSpyFormatters.formatDuration(0), '0 ms');
        expect(NetSpyFormatters.formatDuration(50), '50 ms');
        expect(NetSpyFormatters.formatDuration(999), '999 ms');
      });

      test('should format seconds', () {
        expect(NetSpyFormatters.formatDuration(1000), '1.0s');
        expect(NetSpyFormatters.formatDuration(1500), '1.5s');
        expect(NetSpyFormatters.formatDuration(5000), '5.0s');
        expect(NetSpyFormatters.formatDuration(59999), '60.0s');
      });

      test('should format minutes', () {
        expect(NetSpyFormatters.formatDuration(60000), '1.0m');
        expect(NetSpyFormatters.formatDuration(90000), '1.5m');
        expect(NetSpyFormatters.formatDuration(120000), '2.0m');
      });

      test('should handle negative values', () {
        expect(NetSpyFormatters.formatDuration(-100), '0 ms');
      });
    });

    group('formatTime', () {
      test('should format time with leading zeros', () {
        final time = DateTime(2024, 1, 1, 9, 5, 3, 7);
        expect(NetSpyFormatters.formatTime(time), '09:05:03.007');
      });

      test('should format time without leading zeros needed', () {
        final time = DateTime(2024, 1, 1, 15, 30, 45, 123);
        expect(NetSpyFormatters.formatTime(time), '15:30:45.123');
      });

      test('should format midnight', () {
        final time = DateTime(2024, 1, 1, 0, 0, 0, 0);
        expect(NetSpyFormatters.formatTime(time), '00:00:00.000');
      });
    });

    group('formatDateTime', () {
      test('should format full date time', () {
        final dateTime = DateTime(2024, 1, 15, 9, 30, 45, 123);
        expect(
          NetSpyFormatters.formatDateTime(dateTime),
          '2024-01-15 09:30:45.123',
        );
      });

      test('should format with single digit month and day', () {
        final dateTime = DateTime(2024, 3, 5, 14, 22, 10, 50);
        expect(
          NetSpyFormatters.formatDateTime(dateTime),
          '2024-03-05 14:22:10.050',
        );
      });
    });

    group('formatBody', () {
      test('should return empty string for null', () {
        expect(NetSpyFormatters.formatBody(null), '');
      });

      test('should format Map as indented JSON', () {
        final body = {'name': 'John', 'age': 30};
        final formatted = NetSpyFormatters.formatBody(body);

        expect(formatted, contains('"name": "John"'));
        expect(formatted, contains('"age": 30'));
        expect(formatted, contains('\n'));
      });

      test('should format List as indented JSON', () {
        final body = [1, 2, 3];
        final formatted = NetSpyFormatters.formatBody(body);

        expect(formatted, contains('1'));
        expect(formatted, contains('2'));
        expect(formatted, contains('3'));
        expect(formatted, contains('\n'));
      });

      test('should parse and format JSON string', () {
        final body = '{"name":"John","age":30}';
        final formatted = NetSpyFormatters.formatBody(body);

        expect(formatted, contains('"name": "John"'));
        expect(formatted, contains('"age": 30'));
        expect(formatted, contains('\n'));
      });

      test('should return plain string if not valid JSON', () {
        final body = 'plain text content';
        final formatted = NetSpyFormatters.formatBody(body);

        expect(formatted, 'plain text content');
      });

      test('should convert other types to string', () {
        expect(NetSpyFormatters.formatBody(123), '123');
        expect(NetSpyFormatters.formatBody(true), 'true');
      });
    });

    group('formatStatusCode', () {
      test('should format valid status codes', () {
        expect(NetSpyFormatters.formatStatusCode(200), '200');
        expect(NetSpyFormatters.formatStatusCode(404), '404');
        expect(NetSpyFormatters.formatStatusCode(500), '500');
      });

      test('should return "Error" for null status', () {
        expect(NetSpyFormatters.formatStatusCode(null), 'Error');
      });

      test('should return "Error" for -1 status', () {
        expect(NetSpyFormatters.formatStatusCode(-1), 'Error');
      });
    });
  });
}
