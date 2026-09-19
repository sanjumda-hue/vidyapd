/// A failure the UI can show a student, as opposed to a stack trace.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;

  /// class-validator returns an array of human-readable strings; we surface
  /// them as-is rather than inventing our own copy.
  final List<String>? fieldErrors;

  bool get isNetwork => statusCode == null;

  @override
  String toString() => message;
}
