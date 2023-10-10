import 'package:async_queue/src/exceptions.dart';
import 'package:async_queue/src/interfaces.dart';

import 'async_node.dart';
import 'queue_event.dart';
import 'typedef.dart';

/// AsyncQueue
///
/// a queue of async jobs that ensure those jobs will be execute in order,
/// first come first serve
class AsyncQueue extends AsyncQueueInterface {
  AsyncNode? _first;
  AsyncNode? _last;
  int _size = 0;
  bool _autoRun = false;
  bool _isRunning = false;
  QueueListener? _listener;
  bool _isClosed = false;
  bool _isForcedStop = false;
  final Map<Object, int> _map = {};
  dynamic _previousResult;

  CurrentJobUpdater? _currentJobUpdater;

  /// allow to add multiple jobs with same label
  ///
  /// label is required id you want to check job exists correctly
  final bool allowDuplicate;

  /// throw [DuplicatedLabelException] if duplicated job added
  ///
  /// [allowDuplicate] must be false
  final bool throwIfDuplicate;

  /// initialize normal queue
  ///
  /// which require user to explicitly call [start()]
  /// in order to execute all the jobs in the queue
  AsyncQueue({
    this.allowDuplicate = true,
    this.throwIfDuplicate = false,
  }) : assert(throwIfDuplicate ? !allowDuplicate : true);

  /// initialize auto queue
  ///
  /// which will execute the job when it added into the queue
  /// if there is an executing job, the new will have to wait for its turn
  factory AsyncQueue.autoStart({
    bool? allowDuplicate,
    bool? throwIfDuplicate,
  }) =>
      AsyncQueue(
        allowDuplicate: allowDuplicate ?? true,
        throwIfDuplicate: throwIfDuplicate ?? false,
      ).._autoRun = true;

  /// Queue listener, emit event that indicate state of the queue
  void addQueueListener(QueueListener listener) => _listener = listener;

  void currentJobUpdate(CurrentJobUpdater updater) =>
      _currentJobUpdater = updater;

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
    _currentJobUpdater?.call(null);

    _isForcedStop = true;
    _isRunning = false;
    _first = null;
    _last = null;
    _size = 0;
    _map.clear();
    _previousResult = null;
    _isForcedStop = false;

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
      return;
    }

    if (_first!.retryCount >= _first!.maxRetry) {
      _emitEvent(QueueEventType.retryLimitReached, _first!.label);
      _first!.state = JobState.failed;

      return;
    }

    _first!.retryCount++;
    _first!.state = JobState.pendingRetry;
  }

  /// Add new job into the queue
  ///
  /// [AsyncJob] (Function(dynamic) job) will provide previous job's result to use in the next job if you wish to
  /// otherwise just ignore it using `_`.
  ///
  /// [retryTime] set the time that this job should retry if failed, default to 1,
  /// set [retryTime] to `-1` will make it retry infinitely, until job is done "be careful what you wish for!"
  /// setting [retryTime] does not make the job auto retry
  /// you must explicitly call retry when adding job.
  /// [label] must be unique, this can be use to get the [AsyncNode] that contains the related job
  /// will throw [DuplicatedLabelException] if you the label is already in the queue
  /// [description] description for the job
  @override
  void addJob(
    AsyncJob job, {
    Object? label,
    String? description,
    int retryTime = 1,
  }) {
    if (isClosed) {
      return _emitEvent(QueueEventType.violateAddWhenClosed);
    }

    final newNode = AsyncNode(
      job: job,
      maxRetry: retryTime,
      label: label ?? DateTime.now().toIso8601String(),
      description: description,
    );

    if (_map.containsKey(newNode.label)) {
      if (allowDuplicate) {
        _updateQueueMap(newNode.label);
        _enqueue(newNode);
      } else {
        if (throwIfDuplicate) {
          throw DuplicatedLabelException(
            "A job with this label already exists",
          );
        }
      }
    } else {
      _enqueue(newNode);

      _updateQueueMap(newNode.label);
    }

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
      if (_isForcedStop) break;
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

    _currentJobUpdater?.call(jobLabel);

    var currentNode = _first!;

    _emitEvent(QueueEventType.beforeJob, _first!.label);

    _previousResult = await _first!.run(_previousResult);

    //incase [stop] is called
    if (_first == null) return;

    if (_first!.state == JobState.running) {
      _first!.state = JobState.done;
    }

    if (_first!.state == JobState.done || _first!.state == JobState.failed) {
      if (_size == 1) {
        _first = null;
        _last = null;
      } else {
        _first = currentNode.next;
        currentNode.next = null;
      }
      //remove job from info map
      if (_map.containsKey(jobLabel)) {
        _map.remove(jobLabel);
      }
      _size--;
      _emitEvent(QueueEventType.afterJob, jobLabel);
    } else {
      _emitEvent(QueueEventType.retryJob, jobLabel);
    }
    _currentJobUpdater?.call(null);
  }

  void _emitEvent(QueueEventType type, [Object? label]) {
    _listener?.call(QueueEvent(
      currentQueueSize: _size,
      type: type,
      jobLabel: label,
    ));
  }

  void _updateQueueMap(Object jobLabel) {
    _map.update(jobLabel, (value) => value++, ifAbsent: () => 1);
  }

  /// get the list of job info of the queue
  ///
  /// this list still remain after the queue finished
  /// call [clear] would clear this history, also stop the queue if it's still running
  // @override
  // List<JobInfo> list() {
  //   return _map.values.toList();
  // }

  /// get job info of a specific job by its label
  // @override
  // JobInfo getJobInfo(String label) {
  //   if (!_map.containsKey(label)) {
  //     throw InvalidJobLabelException("No job with this label found");
  //   }
  //   return _map[label]!;
  // }
}
