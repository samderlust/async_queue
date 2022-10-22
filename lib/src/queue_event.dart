/// QueueEvent
///
/// emit by the queue listener
/// provide time of event and current size of the queue at that time
class QueueEvent {
  final DateTime time = DateTime.now();
  final int currentQueueSize;
  final QueueEventType type;

  QueueEvent({
    required this.currentQueueSize,
    required this.type,
  });

  @override
  String toString() =>
      'QueueEvent(Queue Size: $currentQueueSize, time: $time, type: $type)';
}

/// types of Queue Event
enum QueueEventType {
  /// when queue starts
  queueStart,

  /// before each job executing
  beforeJob,

  /// after each job executing
  afterJob,

  /// when queue ends
  queueEnd,

  /// when new job is added to the queue
  newJobAdded,

  /// when queue is closed
  queueClosed,

  /// when trying to add new job when queue is closed
  violateAddWhenClosed,
}
