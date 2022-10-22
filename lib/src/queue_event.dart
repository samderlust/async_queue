/// QueueEvent
///
/// emit by the queue listener
/// provide time of event and current size of the queue at that time
class QueueEvent {
  final DateTime time = DateTime.now();
  final int currentQueueSize;

  QueueEvent({
    required this.currentQueueSize,
  });

  @override
  String toString() => 'QueueEvent(Queue Size: $currentQueueSize, time: $time)';
}
