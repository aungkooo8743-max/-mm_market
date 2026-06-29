class Failure {
  final String message;
  final String code;
  final Object? cause;

  const Failure({required this.message, this.code = 'unknown', this.cause});

  factory Failure.fromException(Object error) =>
      Failure(message: error.toString(), cause: error);
}
