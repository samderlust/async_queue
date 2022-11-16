import 'job_info.dart';
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

  /// limit of retry time
  final int maxRetry;

  /// unique label of the job
  final String label;

  ///description
  final String? description;

  /// extra data
  Object? extra;

  AsyncNode? next;
  int retryCount = 0;
  JobState state = JobState.pending;

  AsyncNode({
    required AsyncJob job,
    required this.label,
    this.description,
    this.maxRetry = 1,
    this.extra,
  }) : _job = job;

  Future run() async {
    state = JobState.running;
    await _job();
  }

  @override
  String toString() {
    return 'AsyncNode(maxRetry: $maxRetry, label: $label, description: $description, retryCount: $retryCount)';
  }

  JobInfo get info => JobInfo(
        label: label,
        description: description,
        maxRetry: maxRetry,
        retryCount: retryCount,
        state: state,
      );
}
