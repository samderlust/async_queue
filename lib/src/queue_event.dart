class QueueEvent {
  final DateTime time = DateTime.now();
  final int currentQueueSize;

  QueueEvent({
    required this.currentQueueSize,
  });

  @override
  String toString() =>
      'QueueEvent(currentQueueSize: $currentQueueSize, time: $time)';
}
