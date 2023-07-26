import 'dart:async';

import 'package:async_queue/src/interfaces.dart';
import 'package:async_queue/src/exceptions.dart';

import 'async_node.dart';
import 'job_info.dart';
import 'queue_event.dart';
import 'typedef.dart';

/// AsyncQueue
///
/// a queue of async jobs that ensure those jobs will be execute in order,
/// first come first serve
final class AsyncQueue implements AsyncQueueInterface {
  AsyncNode? _first;
  AsyncNode? _last;
  int _size = 0;
  bool _autoRun = false;
  bool _isRunning = false;
  QueueListener? _listener;
  bool _isClosed = false;
  bool _isForcedClosed = false;
  final Map<String, JobInfo> _map = {};
  final Map<String, Timer> _debounceMap = {};

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
  @override
  void close() {
    _isClosed = true;
    _emitEvent(QueueEventType.queueClosed);
  }

  /// stop and remove all remain jobs in queue
  ///
  /// would be useful if want to stop the queue when a job fails
  /// [callBack] is where use can call cancelToken or side effect
  @override
  void stop([Function? callBack]) {
    if (callBack != null) callBack();
    _isForcedClosed = true;
    _isRunning = false;
    _first = null;
    _last = null;
    _size = 0;
    _map.clear();
    _emitEvent(QueueEventType.queueStopped);
  }

  /// stop the queue and clear the history
  ///
  /// [callBack] is where use can call cancelToken or side effect
  @override
  void clear([Function? callBack]) {
    stop();
    _map.clear();
  }

  /// retry
  @override
  void retry() {
    if (_first!.maxRetry == -1) {
      _first!.state = JobState.pendingRetry;
      _updateQueueMap(_first!.info);
      return;
    }

    if (_first!.retryCount >= _first!.maxRetry) {
      _emitEvent(QueueEventType.retryLimitReached, _first!.label);
      _first!.state = JobState.failed;
      _updateQueueMap(_first!.info);

      return;
    }

    _first!.retryCount++;
    _first!.state = JobState.pendingRetry;
    _updateQueueMap(_first!.info);
  }

  /// Add new job into the queue
  ///
  /// [retryTime] set the time that this job should retry if failed, default to 1,
  /// set [retryTime] to `-1` will make it retry infinitely, until job is done "be careful what you wish for!"
  /// setting [retryTime] does not make the job auto retry
  /// you must explicitly call retry when adding job.
  /// [label] must be unique, this can be use to get the [AsyncNode] that contains the related job
  /// will throw [DuplicatedLabelException] if you the label is already in the queue
  /// [description] description for the job
  @override
  void addJob(AsyncJob job,
      {String? label,
      String? description,
      int retryTime = 1,
      int debounceTime = 0}) {
    if (isClosed) {
      return _emitEvent(QueueEventType.violateAddWhenClosed);
    }

    final newNode = AsyncNode(
      job: job,
      maxRetry: retryTime,
      label: label ?? job.runtimeType.toString(),
      description: description,
    );

    // if (_map.containsKey(newNode.label)) {
    //   throw DuplicatedLabelException("A job with this label already exists");
    // }
    _map[newNode.label] = newNode.info;
    _enqueue(newNode);

    if (_autoRun) start();
  }

  /// Add new job in to the queue
  ///
  /// if the queue is closed, throw [ClosedQueueException]
  @override
  void addJobThrow(
    AsyncJob job, {
    String? label,
    String? description,
    int retryTime = 1,
  }) {
    if (isClosed) {
      throw ClosedQueueException("Closed Queue");
    } else {
      addJob(
        job,
        retryTime: retryTime,
        label: label,
        description: description,
      );
    }
  }

  /// to start the execution of jobs in queue
  @override
  Future<void> start() async {
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

    _emitEvent(QueueEventType.newJobAdded, _first!.label);
  }

  /// remove node, execute job
  Future _dequeue() async {
    if (_first == null) return;
    final jobLabel = _first!.label;

    var currentNode = _first!;

    _emitEvent(QueueEventType.beforeJob, _first!.label);

    _updateQueueMap(_first!.info.copyWith(state: JobState.running));
    await _first!.run();

    //incase [stop] is called
    if (_first == null) return;

    if (_first!.state == JobState.running) {
      _first!.state = JobState.done;
    }

    if (_first!.state == JobState.done || _first!.state == JobState.failed) {
      _updateQueueMap(_first!.info);
      if (_size == 1) {
        _first = null;
        _last = null;
      } else {
        _first = currentNode.next;
        currentNode.next = null;
      }
      _size--;
      _emitEvent(QueueEventType.afterJob, jobLabel);
    } else {
      _emitEvent(QueueEventType.retryJob, jobLabel);
    }
  }

  void _emitEvent(QueueEventType type, [String? label]) {
    if (_listener != null) {
      _listener!(QueueEvent(
        currentQueueSize: _size,
        type: type,
        jobLabel: label,
      ));
    }
  }

  void _updateQueueMap(
    JobInfo info,
  ) {
    if (_map.containsKey(info.label)) {
      _map.update(info.label, (value) => info);
    }
  }

  /// get the list of job info of the queue
  ///
  /// this list still remain after the queue finished
  /// call [clear] would clear this history, also stop the queue if it's still running
  @override
  List<JobInfo> list() {
    return _map.values.toList();
  }

  /// get job info of a specific job by its label
  @override
  JobInfo getJobInfo(String label) {
    if (!_map.containsKey(label)) {
      throw InvalidJobLabelException("No job with this label found");
    }
    return _map[label]!;
  }
}
