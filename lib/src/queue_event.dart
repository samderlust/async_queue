class QueueEvent {
  final DateTime time = DateTime.now();
  final int currentQueueSize;

  QueueEvent({
    required this.currentQueueSize,
  });

  @override
  String toString() => 'QueueEvent(Queue Size: $currentQueueSize, time: $time)';
}
