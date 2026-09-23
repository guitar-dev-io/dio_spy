import '../utils/header_redactor.dart';
import 'serialization.dart';

class NetSpyHttpResponse {
  NetSpyHttpResponse();

  int? status;
  DateTime time = DateTime.now();
  int size = 0;
  dynamic body;
  Map<String, String> headers = {};

  factory NetSpyHttpResponse.fromJson(Map<String, dynamic> json) {
    return NetSpyHttpResponse()
      ..status = (json['status'] as num?)?.toInt()
      ..time = dateFromMillis(json['time'])
      ..size = (json['size'] as num?)?.toInt() ?? 0
      ..body = json['body']
      ..headers = stringMap(json['headers']);
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'time': time.millisecondsSinceEpoch,
        'size': size,
        'body': jsonSafe(body),
        'headers': headers,
      };

  /// Returns a copy with sensitive header values masked. See
  /// [NetSpyHttpRequest.redacted] for why this exists.
  NetSpyHttpResponse redacted(Set<String> sensitiveLower) {
    return NetSpyHttpResponse()
      ..status = status
      ..time = time
      ..size = size
      ..body = body
      ..headers = HeaderRedactor.redactMap(headers,
          enabled: true, sensitiveLower: sensitiveLower);
  }
}
