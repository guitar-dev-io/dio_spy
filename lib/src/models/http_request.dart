import '../utils/header_redactor.dart';
import 'form_data_models.dart';
import 'serialization.dart';

class NetSpyHttpRequest {
  NetSpyHttpRequest();

  DateTime time = DateTime.now();
  int size = 0;
  Map<String, String> headers = {};
  dynamic body;
  String? contentType;
  Map<String, String> cookies = {};
  Map<String, dynamic> queryParameters = {};
  List<NetSpyFormDataFile>? formDataFiles;
  List<NetSpyFormDataField>? formDataFields;

  factory NetSpyHttpRequest.fromJson(Map<String, dynamic> json) {
    final request = NetSpyHttpRequest()
      ..time = dateFromMillis(json['time'])
      ..size = (json['size'] as num?)?.toInt() ?? 0
      ..headers = stringMap(json['headers'])
      ..body = json['body']
      ..contentType = json['contentType'] as String?
      ..cookies = stringMap(json['cookies'])
      ..queryParameters = dynamicMap(json['queryParameters']);

    final files = json['formDataFiles'] as List?;
    if (files != null) {
      request.formDataFiles =
          files.map((e) => NetSpyFormDataFile.fromJson(dynamicMap(e))).toList();
    }

    final fields = json['formDataFields'] as List?;
    if (fields != null) {
      request.formDataFields = fields
          .map((e) => NetSpyFormDataField.fromJson(dynamicMap(e)))
          .toList();
    }

    return request;
  }

  Map<String, dynamic> toJson() => {
        'time': time.millisecondsSinceEpoch,
        'size': size,
        'headers': headers,
        'body': jsonSafe(body),
        'contentType': contentType,
        'cookies': cookies,
        'queryParameters':
            queryParameters.map((k, v) => MapEntry(k, jsonSafe(v))),
        'formDataFiles': formDataFiles?.map((e) => e.toJson()).toList(),
        'formDataFields': formDataFields?.map((e) => e.toJson()).toList(),
      };

  /// Returns a copy with sensitive header/cookie values masked.
  ///
  /// Used before writing calls to disk: the in-memory/UI redaction toggle is
  /// a display convenience, but persisted data should never contain
  /// plaintext secrets regardless of that toggle's state.
  NetSpyHttpRequest redacted(Set<String> sensitiveLower) {
    return NetSpyHttpRequest()
      ..time = time
      ..size = size
      ..headers = HeaderRedactor.redactMap(headers,
          enabled: true, sensitiveLower: sensitiveLower)
      ..body = body
      ..contentType = contentType
      ..cookies = HeaderRedactor.redactCookies(cookies,
          enabled: true, sensitiveLower: sensitiveLower)
      ..queryParameters = queryParameters
      ..formDataFiles = formDataFiles
      ..formDataFields = formDataFields;
  }
}
