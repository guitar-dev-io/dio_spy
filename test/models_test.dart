import 'package:net_spy/src/models/form_data_models.dart';
import 'package:net_spy/src/models/http_call.dart';
import 'package:net_spy/src/models/http_error.dart';
import 'package:net_spy/src/models/http_request.dart';
import 'package:net_spy/src/models/http_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models', () {
    group('NetSpyHttpCall', () {
      test('should initialize with id and created time', () {
        final call = NetSpyHttpCall(123);

        expect(call.id, 123);
        expect(call.createdTime, isNotNull);
        expect(call.loading, true);
        expect(call.duration, 0);
        expect(call.method, '');
        expect(call.endpoint, '');
        expect(call.server, '');
        expect(call.uri, '');
        expect(call.secure, false);
      });

      test('should allow setting properties', () {
        final call = NetSpyHttpCall(1);
        call.method = 'POST';
        call.endpoint = '/api/users';
        call.server = 'example.com';
        call.uri = 'https://example.com/api/users';
        call.secure = true;
        call.loading = false;
        call.duration = 250;

        expect(call.method, 'POST');
        expect(call.endpoint, '/api/users');
        expect(call.server, 'example.com');
        expect(call.uri, 'https://example.com/api/users');
        expect(call.secure, true);
        expect(call.loading, false);
        expect(call.duration, 250);
      });

      test('should allow setting request, response, and error', () {
        final call = NetSpyHttpCall(1);
        final request = NetSpyHttpRequest();
        final response = NetSpyHttpResponse();
        final error = NetSpyHttpError(error: 'Test error');

        call.request = request;
        call.response = response;
        call.error = error;

        expect(call.request, request);
        expect(call.response, response);
        expect(call.error, error);
      });
    });

    group('NetSpyHttpRequest', () {
      test('should initialize with default values', () {
        final request = NetSpyHttpRequest();

        expect(request.time, isNotNull);
        expect(request.size, 0);
        expect(request.headers, isEmpty);
        expect(request.body, isNull);
        expect(request.contentType, isNull);
        expect(request.cookies, isEmpty);
        expect(request.queryParameters, isEmpty);
        expect(request.formDataFiles, isNull);
        expect(request.formDataFields, isNull);
      });

      test('should allow setting properties', () {
        final request = NetSpyHttpRequest();
        final now = DateTime.now();

        request.time = now;
        request.size = 1024;
        request.headers = {'Content-Type': 'application/json'};
        request.body = {'key': 'value'};
        request.contentType = 'application/json';
        request.cookies = {'session': 'abc'};
        request.queryParameters = {'page': '1'};

        expect(request.time, now);
        expect(request.size, 1024);
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.body, {'key': 'value'});
        expect(request.contentType, 'application/json');
        expect(request.cookies['session'], 'abc');
        expect(request.queryParameters['page'], '1');
      });

      test('should allow setting form data fields and files', () {
        final request = NetSpyHttpRequest();
        final fields = [
          NetSpyFormDataField(name: 'field1', value: 'value1'),
          NetSpyFormDataField(name: 'field2', value: 'value2'),
        ];
        final files = [
          NetSpyFormDataFile(
            fileName: 'test.txt',
            contentType: 'text/plain',
            length: 100,
          ),
        ];

        request.formDataFields = fields;
        request.formDataFiles = files;

        expect(request.formDataFields?.length, 2);
        expect(request.formDataFiles?.length, 1);
        expect(request.formDataFields?[0].name, 'field1');
        expect(request.formDataFiles?[0].fileName, 'test.txt');
      });
    });

    group('NetSpyHttpResponse', () {
      test('should initialize with default values', () {
        final response = NetSpyHttpResponse();

        expect(response.status, isNull);
        expect(response.time, isNotNull);
        expect(response.size, 0);
        expect(response.body, isNull);
        expect(response.headers, isEmpty);
      });

      test('should allow setting properties', () {
        final response = NetSpyHttpResponse();
        final now = DateTime.now();

        response.status = 200;
        response.time = now;
        response.size = 2048;
        response.body = {'message': 'success'};
        response.headers = {'Content-Type': 'application/json'};

        expect(response.status, 200);
        expect(response.time, now);
        expect(response.size, 2048);
        expect(response.body, {'message': 'success'});
        expect(response.headers['Content-Type'], 'application/json');
      });

      test('should handle different body types', () {
        final response = NetSpyHttpResponse();

        // String body
        response.body = 'plain text';
        expect(response.body, 'plain text');

        // Map body
        response.body = {'key': 'value'};
        expect(response.body, isA<Map>());

        // List body
        response.body = [1, 2, 3];
        expect(response.body, isA<List>());
      });
    });

    group('NetSpyHttpError', () {
      test('should initialize with error message', () {
        final error = NetSpyHttpError(error: 'Connection timeout');

        expect(error.error, 'Connection timeout');
        expect(error.stackTrace, isNull);
      });

      test('should store stack trace', () {
        final stackTrace = StackTrace.current;
        final error = NetSpyHttpError(
          error: 'Network error',
          stackTrace: stackTrace,
        );

        expect(error.error, 'Network error');
        expect(error.stackTrace, stackTrace);
      });
    });

    group('NetSpyFormDataFile', () {
      test('should initialize with required properties', () {
        final file = NetSpyFormDataFile(
          fileName: 'document.pdf',
          contentType: 'application/pdf',
          length: 1024,
        );

        expect(file.fileName, 'document.pdf');
        expect(file.contentType, 'application/pdf');
        expect(file.length, 1024);
      });
    });

    group('NetSpyFormDataField', () {
      test('should initialize with name and value', () {
        final field = NetSpyFormDataField(
          name: 'username',
          value: 'john_doe',
        );

        expect(field.name, 'username');
        expect(field.value, 'john_doe');
      });
    });
  });
}
