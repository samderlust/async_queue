# Async Queue — Improvement Plan

## High Value

### 1. `addJob` returns a Future
Currently there's no way to await a specific job's result. Returning a `Future<T>` from `addJob` enables:
```dart
final result = await q.addJob((_) async => fetchData());
```
Much more ergonomic than wiring up listeners to track individual job completion.

This works alongside `previousResult` without conflict — they serve different purposes:
- `previousResult` — internal sequential chaining between jobs
- Returned `Future` — external handle for the caller to await

Example with both features in a Flutter screen with multiple buttons:
```dart
final q = AsyncQueue.autoStart();

// Button 1 — doesn't care about previous result
final userFuture = q.addJob((_) async {
  return await api.getUser();  // returns "Sam"
});

// Button 2 — uses previous result from Button 1's job
final postsFuture = q.addJob((previousResult) async {
  // previousResult == "Sam" (from job above)
  return await api.getPostsFor(previousResult);
});

// Each button can await its own future independently
final user = await userFuture;     // "Sam"
final posts = await postsFuture;   // [Post, Post, ...]
```

Internally, each job gets a `Completer<T>`. `_dequeue` completes it with the
return value (or error) after the job finishes.

### 2. `onError` callback
A dedicated error handler separate from the general event listener:
```dart
final q = AsyncQueue(onError: (error, jobLabel) {
  log('Job $jobLabel failed: $error');
});
```
Lets users decide per-queue whether to log, skip, stop, etc. without parsing events.

## Medium Value

### 3. Priority queue
Add an optional `priority` parameter to `addJob` so higher-priority jobs jump ahead of lower-priority ones instead of always FIFO.
```dart
q.addJob((_) => importantTask(), priority: 10);
q.addJob((_) => lessImportantTask(), priority: 1);
```

### 4. Pause / Resume
`stop()` currently destroys the queue. A `pause()`/`resume()` pair would let users temporarily halt processing without losing queued jobs.
```dart
q.pause();
// queue holds, no new jobs start
q.resume();
// picks up where it left off
```

### 5. Retry with backoff
Add a `retryDelay` or `backoffStrategy` option so retries don't fire immediately. Useful for network requests where hammering a failing endpoint is counterproductive.
```dart
q.addJob((_) => callApi(), retryTime: 3, retryDelay: Duration(seconds: 2));
// or exponential backoff
q.addJob((_) => callApi(), retryTime: 3, backoff: BackoffStrategy.exponential);
```

## Nice to Have

### 6. `isRunning` getter
Expose `_isRunning` so users can check queue state without relying on events.
```dart
if (q.isRunning) { ... }
```

### 7. Job timeout
Auto-fail a job if it takes longer than a specified duration.
```dart
q.addJob((_) => slowTask(), timeout: Duration(seconds: 30));
```
