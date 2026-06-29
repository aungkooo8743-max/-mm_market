class AppException implements Exception {
  final String message;
  final String code;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppException({required this.message, this.code = 'unknown', this.cause, this.stackTrace});

  @override
  String toString() => message;
}
