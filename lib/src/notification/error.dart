class NotificationException implements Exception {
  final String message;
  final dynamic originalError;

  NotificationException(this.message, [this.originalError]);

  @override
  String toString() {
    return 'NotificationException: $message. Original Error: $originalError';
  }
}