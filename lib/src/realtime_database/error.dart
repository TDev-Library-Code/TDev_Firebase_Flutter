class RealtimeException implements Exception {
  final String message;
  final dynamic cause;

  RealtimeException(this.message, [this.cause]);

  @override
  String toString() => "RealtimeException: $message ${cause ?? ''}";
}