/// Thrown by API services when the backend rejects a request.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final List<FieldError>? fieldErrors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => message;
}

class FieldError {
  final String field;
  final String message;
  const FieldError({required this.field, required this.message});
}
