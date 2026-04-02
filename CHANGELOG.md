## 3.0.0

### New Features
- **`addJob` now returns a `Future`** — await the result of any individual job without relying on listeners. Works alongside `previousResult` without conflict.
- **Automatic retry on job exceptions** — jobs that throw are automatically retried up to `retryTime` times. Manual `retry()` still works for custom logic.
- **`onError` callback** — dedicated error handler on `AsyncQueue` and `AsyncQueue.autoStart` constructors, called with `(error, jobLabel)` on each failure.
- **Priority queue** — `addJob` accepts a `priority` parameter (default 0). Higher priority jobs are placed closer to the front. Same-priority jobs maintain FIFO order.
- **Pause / Resume** — `pause()` halts processing after the current job finishes without losing queued jobs. `resume()` continues. Adds `isPaused` getter and `queuePaused`/`queueResumed` events.
- **Retry with delay** — `addJob` accepts a `retryDelay` Duration to wait between retry attempts. Works with both auto-retry and manual `retry()`.
- **Job timeout** — `addJob` accepts a `timeout` Duration. Jobs exceeding the timeout throw `TimeoutException`, triggering auto-retry like any other exception.
- **`isRunning` getter** — exposes queue running state.
- add `QueueEventType.jobError`, `QueueEventType.queuePaused`, `QueueEventType.queueResumed` events

### Bug Fixes
- fix post-increment bug in duplicate label tracking (value was never actually incremented)
- fix null crash when `retry()` is called on an empty queue
- fix `_previousResult` leaking across separate `start()` runs
- fix `addJobThrow` label parameter type from `String?` to `Object?` to match `addJob`
- fix `_isForcedStop` flag now properly cleared after `start()` loop exits instead of immediately in `stop()`
- fix failed nodes after auto-retry limit never being removed from queue (caused infinite loop)

### Code Cleanup
- sync `AsyncQueueInterface` signatures with actual implementation
- remove dead commented-out code (`list()`, `getJobInfo()`) from source and interface
- remove unused imports and stray `print()` calls from tests

### Tests
- add test coverage for `addJob` returning `Future` (result, chaining, autoStart, previousResult, closed queue)
- add test coverage for `AsyncQueue.autoStart()` (execution order, late adds, events, stop)
- add tests for `onError` callback, priority ordering, pause/resume, retry delay, and job timeout
- add meaningful job label assertions in event tests
- clean up `async_queue_info_test.dart` with actual assertions

## 2.0.2

- fix wrong job label on `QueueEventType.newJobAdded`

## 2.0.1

- fix issue that queue listener return wrong job label

## 2.0.0

- add Flutter example
- add `allowDuplicate` default to true.
- add `throwIfDuplicate` default to false.
- change `AsyncJob = Function(PreviousResult previousResult)`. This allows you to access the previous job's result when adding new job.
- remove `list`, `getJobInfo`, and `addNode` from version `2.0.0-dev.1` as not needed.
- hide `AsyncNode`
- remove `JobInfo`
- change job label type from `String` to `Object`
- add current running job label `CurrentJobUpdater` to notify every time a job is running

## 2.0.0-dev.3

- change job label type from `String` to `Object`
- add current running job label `CurrentJobUpdater` to notify every time a job is running

## 2.0.0-dev.2

- add Flutter example
- add `allowDuplicate` default to true.
- add `throwIfDuplicate` default to false.
- change `AsyncJob = Function(PreviousResult previousResult)`. This allows you to access the previous job's result when adding new job.
- remove `list`, `getJobInfo`, and `addNode` from version `2.0.0-dev.1` as not needed.
- hide `AsyncNode`
- remove `JobInfo`

## 2.0.0-dev.1

- option to add the job that failed back in to the queue. (last position)
- expose [AsyncNode]
- [addNode] on [AsyncQueue]

## 1.3.0

- option to add `label` and `description` when adding job
- [label] need to be unique unless [DuplicatedLabelException] will throw.
- in [AsyncQueue.addJob] if provide `retryTime = -1` will make the job retry infinitely until it success. You still have to explicitly call `retry`. Be careful when using this option.
- emit event when job hits its max retry limit [QueueEventType.retryLimitReached]
- add [AsyncQueue.list] and [AsyncQueue.getJobInfo] to retrieve the jobs info event when queue finished
- add [AsyncQueue.clear] to clear the info list and also stop the queue if it's running

## 1.2.0

- add `stop()` to stop and remove all remaining jobs in the queue
- add `retry()` to retry the job, default to 1 time, but user can set as many time as they want
- remove `{bool forceStop = false}` in `close()` since we now have `stop` method
- fix typo
- add test cases

## 1.1.1

- add Flutter use cases into README

## 1.1.0

- [breaking change] remove `beforeListener` and `afterListener`. One listener will emit `event` with type.
- add `close({bool forceStop = false})` close the queue so that no more job can be added. [forceStop] if true, all remain jobs will be canceled
- `addJobThrow` Add new job in to the queue if the queue is closed, throw [ClosedQueueException]
- add test cases

## 1.0.0

- (Normal Queue) Add multiple jobs into queue before firing
- (Auto Queue) Firing job as soon as any job is added to the queue
- (Both) Option to add queue listener that happens before or after execute every job
