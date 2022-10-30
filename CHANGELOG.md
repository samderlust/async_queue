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
