/// QueueEvent
///
/// emit by the queue listener
/// provide time of event and current size of the queue at that time
class QueueEvent {
  final DateTime time = DateTime.now();
  final int currentQueueSize;
  final QueueEventType type;
  final Object? jobLabel;

  QueueEvent({
    required this.currentQueueSize,
    required this.type,
    this.jobLabel,
  });

  @override
  String toString() =>
      'QueueEvent [currentQueueSize: $currentQueueSize, type: $type, jobLabel: $jobLabel, at: $time]';
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

  /// when queue is stopped
  queueStopped,

  /// when trying to add new job when queue is closed
  violateAddWhenClosed,

  /// emit when retry
  retryJob,

  /// emit when a job has reach it retry limit
  retryLimitReached
}
