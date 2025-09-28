class FirestoreException implements Exception {
  final String message;
  final dynamic error;
  FirestoreException(this.message, [this.error]);

  @override
  String toString() => 'FirestoreException: $message ${error ?? ''}';
}
