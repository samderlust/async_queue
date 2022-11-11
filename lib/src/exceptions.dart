class ClosedQueueException implements Exception {
  final String message;
  ClosedQueueException(this.message);
}

class DuplicatedLabelException implements Exception {
  final String message;
  DuplicatedLabelException(this.message);
}

class InvalidJobLabelException implements Exception {
  final String message;
  InvalidJobLabelException(this.message);
}
