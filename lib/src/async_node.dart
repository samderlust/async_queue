import 'typedef.dart';

enum JobState { pending, running, failed, done }

///AsyncNode
///
///single node in the queue that contain an async job
class AsyncNode {
  final AsyncJob _job;
  final int maxRetry;

  AsyncNode? next;
  int retryCount = 0;
  JobState state = JobState.pending;

  AsyncNode({
    required AsyncJob job,
    this.maxRetry = 1,
  }) : _job = job;

  Future run() async {
    state = JobState.running;
    await _job();
  }
}
