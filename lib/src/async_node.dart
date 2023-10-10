import 'typedef.dart';

/// states of a job
enum JobState {
  ///pending
  pending,

  /// job is running
  running,

  ///job failed and removed from the queue
  failed,

  ///job done and removed from the queue
  done,

  ///job failed and pending retry
  pendingRetry,
}

///AsyncNode
///
///single node in the queue that contain an async job
class AsyncNode {
  final AsyncJob _job;
  final int maxRetry;
  final Object label;
  final String? description;

  AsyncNode? next;
  int retryCount = 0;
  JobState state = JobState.pending;

  AsyncNode({
    required AsyncJob job,
    required this.label,
    this.description,
    this.maxRetry = 1,
  }) : _job = job;

  dynamic run(PreviousResult previousResult) async {
    state = JobState.running;
    return await _job(previousResult);
  }

  @override
  String toString() {
    return 'AsyncNode(maxRetry: $maxRetry, label: $label, description: $description, retryCount: $retryCount)';
  }
}
