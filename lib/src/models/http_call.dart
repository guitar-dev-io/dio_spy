import 'http_error.dart';
import 'http_request.dart';
import 'http_response.dart';
import 'serialization.dart';

class NetSpyHttpCall {
  NetSpyHttpCall(this.id, {DateTime? createdTime})
      : createdTime = createdTime ?? DateTime.now();

  factory NetSpyHttpCall.fromJson(Map<String, dynamic> json) {
    final call = NetSpyHttpCall(
      (json['id'] as num?)?.toInt() ?? 0,
      createdTime: dateFromMillis(json['createdTime']),
    )
      ..method = json['method'] as String? ?? ''
      ..endpoint = json['endpoint'] as String? ?? ''
      ..server = json['server'] as String? ?? ''
      ..uri = json['uri'] as String? ?? ''
      ..secure = json['secure'] as bool? ?? false
      ..loading = json['loading'] as bool? ?? false
      ..duration = (json['duration'] as num?)?.toInt() ?? 0;

    final request = json['request'];
    if (request is Map) {
      call.request = NetSpyHttpRequest.fromJson(dynamicMap(request));
    }

    final response = json['response'];
    if (response is Map) {
      call.response = NetSpyHttpResponse.fromJson(dynamicMap(response));
    }

    final error = json['error'];
    if (error is Map) {
      call.error = NetSpyHttpError.fromJson(dynamicMap(error));
    }

    return call;
  }

  final int id;
  final DateTime createdTime;
  String method = '';
  String endpoint = '';
  String server = '';
  String uri = '';
  bool secure = false;
  bool loading = true;
  int duration = 0;

  NetSpyHttpRequest? request;
  NetSpyHttpResponse? response;
  NetSpyHttpError? error;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdTime': createdTime.millisecondsSinceEpoch,
        'method': method,
        'endpoint': endpoint,
        'server': server,
        'uri': uri,
        'secure': secure,
        'loading': loading,
        'duration': duration,
        'request': request?.toJson(),
        'response': response?.toJson(),
        'error': error?.toJson(),
      };

  /// Returns a copy of this call with sensitive header/cookie values masked
  /// on its request and response. Used before persisting to disk so stored
  /// data never contains plaintext secrets, independent of the inspector's
  /// (display-only) redaction toggle.
  NetSpyHttpCall redacted(Set<String> sensitiveLower) {
    final call = NetSpyHttpCall(id, createdTime: createdTime)
      ..method = method
      ..endpoint = endpoint
      ..server = server
      ..uri = uri
      ..secure = secure
      ..loading = loading
      ..duration = duration
      ..error = error;
    call.request = request?.redacted(sensitiveLower);
    call.response = response?.redacted(sensitiveLower);
    return call;
  }
}
