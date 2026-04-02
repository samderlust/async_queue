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
  bool _isPaused = false;
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

  /// Called when a job throws an exception.
  /// Receives the error and the job's label.
  final QueueErrorHandler? onError;

  /// initialize normal queue
  ///
  /// which require user to explicitly call [start()]
  /// in order to execute all the jobs in the queue
  AsyncQueue({
    this.allowDuplicate = true,
    this.throwIfDuplicate = false,
    this.onError,
  }) : assert(throwIfDuplicate ? !allowDuplicate : true);

  /// initialize auto queue
  ///
  /// which will execute the job when it added into the queue
  /// if there is an executing job, the new will have to wait for its turn
  factory AsyncQueue.autoStart({
    bool? allowDuplicate,
    bool? throwIfDuplicate,
    QueueErrorHandler? onError,
  }) =>
      AsyncQueue(
        allowDuplicate: allowDuplicate ?? true,
        throwIfDuplicate: throwIfDuplicate ?? false,
        onError: onError,
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

  /// true if the queue is paused
  bool get isPaused => _isPaused;

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

    _emitEvent(QueueEventType.queueStopped);
  }

  /// Pause the queue. The currently running job will finish,
  /// but no new jobs will start until [resume] is called.
  /// Queued jobs are preserved.
  void pause() {
    _isPaused = true;
    _emitEvent(QueueEventType.queuePaused);
  }

  /// Resume a paused queue. Continues processing remaining jobs.
  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _emitEvent(QueueEventType.queueResumed);
    if (_autoRun && size > 0) start();
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
    if (_first == null) return;

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
  /// [AsyncJob] (Function(PreviousResult dynamic) job) will provide previous job's result to use in the next job if you wish to use,
  /// otherwise just ignore it using `_`.
  ///
  /// [retryTime] set the time that this job should retry if failed, default to 1,
  /// set [retryTime] to `-1` will make it retry infinitely, until job is done "be careful what you wish for!"
  /// If a job throws an exception, it will automatically retry up to [retryTime] times.
  /// You can also manually call [retry] from within a job for custom retry logic.
  /// [label] must be unique, this can be use to get the [AsyncNode] that contains the related job
  /// will throw [DuplicatedLabelException] if you the label is already in the queue
  /// [description] description for the job
  @override
  Future<dynamic> addJob(
    AsyncJob job, {
    Object? label,
    String? description,
    int retryTime = 1,
    int priority = 0,
    Duration? retryDelay,
  }) {
    if (isClosed) {
      _emitEvent(QueueEventType.violateAddWhenClosed);
      return Future.value(null);
    }

    final newNode = AsyncNode(
      job: job,
      maxRetry: retryTime,
      label: label ?? DateTime.now().toIso8601String(),
      description: description,
      priority: priority,
      retryDelay: retryDelay,
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
        return Future.value(null);
      }
    } else {
      _enqueue(newNode);

      _updateQueueMap(newNode.label);
    }

    if (_autoRun) start();

    return newNode.future;
  }

  /// Add new job in to the queue
  ///
  /// if the queue is closed, throw [ClosedQueueException]
  @override
  Future<dynamic> addJobThrow(
    AsyncJob job, {
    Object? label,
    String? description,
    int retryTime = 1,
    int priority = 0,
    Duration? retryDelay,
  }) {
    if (isClosed) {
      throw ClosedQueueException("Closed Queue");
    }
    return addJob(
      job,
      retryTime: retryTime,
      label: label,
      description: description,
      priority: priority,
      retryDelay: retryDelay,
    );
  }

  /// to start the execution of jobs in queue
  @override
  Future<void> start() async {
    if (size == 0 || _isRunning) return;

    _isRunning = true;
    _emitEvent(QueueEventType.queueStart);

    while (size > 0) {
      if (_isForcedStop) break;
      if (_isPaused) {
        _isRunning = false;
        return;
      }
      await _dequeue();
    }

    _isForcedStop = false;
    _isRunning = false;
    _previousResult = null;
    _emitEvent(QueueEventType.queueEnd);
  }

  /// to add node into queue, respecting priority order
  ///
  /// Higher priority values are placed closer to the front.
  /// If the queue is running, the currently executing node (_first) is skipped.
  void _enqueue(AsyncNode node) {
    if (_first == null) {
      _first = node;
      _last = node;
    } else if (node.priority <= _last!.priority) {
      // Fast path: lowest or equal priority goes to end
      _last!.next = node;
      _last = node;
    } else {
      // Insert by priority, but never before the currently running node
      AsyncNode? prev = _isRunning ? _first : null;
      AsyncNode? current = _isRunning ? _first!.next : _first;

      if (!_isRunning && node.priority > _first!.priority) {
        // Insert before _first (queue not running)
        node.next = _first;
        _first = node;
      } else {
        while (current != null && current.priority >= node.priority) {
          prev = current;
          current = current.next;
        }
        node.next = current;
        prev!.next = node;
        if (current == null) {
          _last = node;
        }
      }
    }
    _size++;

    _emitEvent(QueueEventType.newJobAdded, node.label);
  }

  /// remove node, execute job
  Future _dequeue() async {
    if (_first == null) return;
    final jobLabel = _first!.label;

    _currentJobUpdater?.call(jobLabel);

    var currentNode = _first!;

    _emitEvent(QueueEventType.beforeJob, _first!.label);

    try {
      _previousResult = await _first!.run(_previousResult);
    } catch (e) {
      //incase [stop] is called inside job
      if (_first == null) return;

      _emitEvent(QueueEventType.jobError, _first!.label);
      onError?.call(e, _first!.label);
      retry();

      // remove node from queue if retry limit reached
      if (_first!.state == JobState.failed) {
        if (!currentNode.completer.isCompleted) {
          currentNode.completer.completeError(e);
        }
        if (_size == 1) {
          _first = null;
          _last = null;
        } else {
          _first = currentNode.next;
          currentNode.next = null;
        }
        if (_map.containsKey(jobLabel)) {
          _map.remove(jobLabel);
        }
        _size--;
        _emitEvent(QueueEventType.afterJob, currentNode.label);
      } else {
        _emitEvent(QueueEventType.retryJob, currentNode.label);
        if (currentNode.retryDelay != null) {
          await Future.delayed(currentNode.retryDelay!);
        }
      }

      _currentJobUpdater?.call(null);
      return;
    }

    //incase [stop] is called
    if (_first == null) return;

    if (_first!.state == JobState.running) {
      _first!.state = JobState.done;
    }

    if (_first!.state == JobState.done || _first!.state == JobState.failed) {
      if (!currentNode.completer.isCompleted) {
        currentNode.completer.complete(_previousResult);
      }
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
      _emitEvent(QueueEventType.afterJob, currentNode.label);
    } else {
      _emitEvent(QueueEventType.retryJob, currentNode.label);
      if (currentNode.retryDelay != null) {
        await Future.delayed(currentNode.retryDelay!);
      }
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
    _map.update(jobLabel, (value) => value + 1, ifAbsent: () => 1);
  }
}
