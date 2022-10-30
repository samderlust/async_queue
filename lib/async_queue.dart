/// This dart package ensure your pack of async task perform in order, one after the other.
///
/// - (Normal Queue) Add multiple jobs into queue before firing
/// - (Auto Queue) Firing job as soon as any job is added to the queue
/// - (Both) Option to add queue listener that happens before or after execute every job

library async_queue;

export 'src/async_queue_base.dart';
