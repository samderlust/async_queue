import 'package:async_queue/src/exceptions.dart';

import 'async_node.dart';
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
  QueueListener? _listener;
  bool _isClosed = false;
  bool _isForcedClosed = false;

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

  /// Queue listener, emit event that indicate state of the queue
  void addQueueListener(QueueListener listener) => _listener = listener;

  /// current size of the queue
  ///
  /// equal to number of jobs that left in the queue
  int get size => _size;

  /// true if the queue is closed, no more job can be added
  bool get isClosed => _isClosed;

  /// close the queue so that no more job can be added
  void close() {
    _isClosed = true;
    _emitEvent(QueueEventType.queueClosed);
  }

  /// stop and remove all remain jobs in queue
  ///
  /// would be useful if want to stop the queue when a job fails
  void stop() {
    _isForcedClosed = true;
    _isRunning = false;
    _first = null;
    _last = null;
    _size = 0;
    _emitEvent(QueueEventType.queueStopped);
  }

  /// retry
  void retry() {
    if (_first!.retryCount >= _first!.maxRetry) return;

    _first!.retryCount++;
    _first!.state = JobState.failed;
  }

  /// Add new job into the queue
  ///
  /// [retryTime] set the time that this job should retry if failed
  /// default to 1
  /// setting [retryTime] does not make the job auto retry
  /// you must explicitly call retry when adding job.
  void addJob(AsyncJob job, {int retryTime = 1}) {
    if (isClosed) {
      return _emitEvent(QueueEventType.violateAddWhenClosed);
    }

    final newNode = AsyncNode(job: job, maxRetry: retryTime);
    _enqueue(newNode);

    if (_autoRun) start();
  }

  /// Add new job in to the queue
  ///
  /// if the queue is closed, throw [ClosedQueueException]
  void addJobThrow(AsyncJob job) {
    if (isClosed) {
      throw ClosedQueueException("Closed Queue");
    } else {
      addJob(job);
    }
  }

  /// to start the execution of jobs in queue
  Future start() async {
    if (size == 0 || _isRunning) return;

    _isRunning = true;
    _emitEvent(QueueEventType.queueStart);

    while (size > 0) {
      if (_isForcedClosed) break;
      await _dequeue();
    }

    _isRunning = false;
    _emitEvent(QueueEventType.queueEnd);
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

    _emitEvent(QueueEventType.newJobAdded);
  }

  /// remove node, execute job
  Future _dequeue() async {
    if (_first == null) return;

    var currentNode = _first;

    _emitEvent(QueueEventType.beforeJob);

    await _first!.run();

    //incase [stop] is called
    if (_first == null) return;

    if (_first!.state == JobState.running) {
      _first!.state = JobState.done;
    }

    if (_first!.state == JobState.done) {
      if (_size == 1) {
        _first = null;
        _last = null;
      } else {
        _first = currentNode?.next;
        currentNode?.next = null;
      }
      _size--;

      _emitEvent(QueueEventType.afterJob);
    } else {
      _emitEvent(QueueEventType.retryJob);
    }
  }

  void _emitEvent(QueueEventType type) {
    if (_listener != null) {
      _listener!(QueueEvent(
        currentQueueSize: _size,
        type: type,
      ));
    }
  }
}
