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
}
