import 'async_job.dart';
import 'queue_event.dart';
import 'typedef.dart';

/// AsyncQueue
///
/// a queue of async jobs that ensure those jobs will be execute in order,
/// first come first serve
class AsyncQueue {
  AsyncNode? _first;
  AsyncNode? _last;
  int _size = 0;
  bool _autoRun = false;
  bool _isRunning = false;
  QueueListener? _beforeListener;
  QueueListener? _afterListener;

  /// initialize normal queue
  ///
  /// which require user to explicitly call [start()]
  /// in order to execute all the jobs in the queue
  AsyncQueue();

  /// initialize auto queue
  ///
  /// which will execute the job when it added into the queue
  /// if there is an executing job, the new will have to wait for its turn
  factory AsyncQueue.autoStart() => AsyncQueue().._autoRun = true;

  /// Add Before Listener
  ///
  /// happens before every job
  void addQueueBeforeListener(QueueListener listener) =>
      _beforeListener = listener;

  /// Add After Listener
  ///
  /// happens after every job
  void addQueueAfterListener(QueueListener listener) =>
      _afterListener = listener;

  /// current size of the queue
  ///
  /// equal to number of jobs that left in the queue
  int get size => _size;

  /// Add new job into the queue
  void addJob(AsyncJob job) {
    final newNode = AsyncNode(job: job);
    _enqueue(newNode);

    if (_autoRun) start();
  }

  /// to start the execution of jobs in queue
  Future start() async {
    if (size == 0 || _isRunning) return;

    _isRunning = true;

    while (size > 0) {
      await _dequeue();
    }

    _isRunning = false;
  }

  /// to add node into queue
  void _enqueue(AsyncNode node) {
    if (_first == null) {
      _first = node;
      _last = node;
    } else {
      _last!.next = node;
      _last = node;
    }
    _size++;
  }

  /// remove node, execute job
  Future _dequeue() async {
    if (_first == null) return;

    var currentNode = _first;

    if (_beforeListener != null) {
      _beforeListener!(QueueEvent(currentQueueSize: _size));
    }

    await _first!.job();

    if (_size == 1) {
      _first = null;
      _last = null;
    } else {
      _first = currentNode?.next;
      currentNode?.next = null;
    }
    _size--;

    if (_afterListener != null) {
      _afterListener!(QueueEvent(currentQueueSize: _size));
    }
  }
}
