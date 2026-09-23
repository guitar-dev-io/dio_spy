class NetSpyFormDataFile {
  NetSpyFormDataFile({
    required this.fileName,
    required this.contentType,
    required this.length,
  });

  factory NetSpyFormDataFile.fromJson(Map<String, dynamic> json) {
    return NetSpyFormDataFile(
      fileName: json['fileName'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      length: (json['length'] as num?)?.toInt() ?? 0,
    );
  }

  final String fileName;
  final String contentType;
  final int length;

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'contentType': contentType,
        'length': length,
      };
}

class NetSpyFormDataField {
  NetSpyFormDataField({
    required this.name,
    required this.value,
  });

  factory NetSpyFormDataField.fromJson(Map<String, dynamic> json) {
    return NetSpyFormDataField(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  final String name;
  final String value;

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
      };
}
