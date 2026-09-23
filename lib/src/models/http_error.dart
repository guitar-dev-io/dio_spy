class NetSpyHttpError {
  NetSpyHttpError({this.error, this.stackTrace});

  factory NetSpyHttpError.fromJson(Map<String, dynamic> json) {
    return NetSpyHttpError(
      error: json['error'],
      // A StackTrace cannot be reconstructed from a string, so it is kept only
      // in memory. The textual form is preserved in [stackTraceText].
      stackTrace: null,
    )..stackTraceText = json['stackTrace'] as String?;
  }

  dynamic error;
  StackTrace? stackTrace;

  /// Textual stack trace, used when the error was restored from storage
  /// (where the original [StackTrace] object is not available).
  String? stackTraceText;

  /// The stack trace as text, whether it came from a live [StackTrace] or from
  /// persisted storage.
  String? get stackTraceString => stackTrace?.toString() ?? stackTraceText;

  Map<String, dynamic> toJson() => {
        'error': error?.toString(),
        'stackTrace': stackTraceString,
      };
}
