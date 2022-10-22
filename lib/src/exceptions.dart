class ClosedQueueException implements Exception {
  final String message;

  ClosedQueueException(this.message);
}
