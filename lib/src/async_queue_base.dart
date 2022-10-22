import 'package:async_queue/src/exceptions.dart';

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
  ///
  /// [forceStop] if true, all remain jobs will be canceled;
  void close({bool forceStop = false}) {
    _isClosed = true;
    _isForcedClosed = forceStop;

    return _emitEvent(QueueEventType.queueClosed);
  }

  /// Add new job into the queue
  void addJob(AsyncJob job) {
    if (isClosed) {
      return _emitEvent(QueueEventType.violateAddWhenClosed);
    }

    final newNode = AsyncNode(job: job);
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

    await _first!.job();

    if (_size == 1) {
      _first = null;
      _last = null;
    } else {
      _first = currentNode?.next;
      currentNode?.next = null;
    }
    _size--;

    _emitEvent(QueueEventType.afterJob);
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
