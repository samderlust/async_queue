[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/samderlust)

# Async Queue - ensure list of async task execute in order

This dart package ensure your pack of async task execute in order, one after the other.

## Features

- (Normal Queue) Add multiple jobs into queue before firing
- (Auto Queue) Firing job as soon as any job is added to the queue
- (Both) Option to add queue listener that emits events that happen in the queue

## Installing and import the library:

Like any other package, add the library to your pubspec.yaml dependencies:

```
dependencies:
    async_queue: <latest_version>
```

Then import it wherever you want to use it:

```
import 'package:async_queue/async_queue.dart';
```

## Usage

### 1. Normal Queue

```
 final asyncQ = AsyncQueue();
  asyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 1), () => print("normalQ: 1")));
  asyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 4), () => print("normalQ: 2")));
  asyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 2), () => print("normalQ: 3")));
  asyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 1), () => print("normalQ: 4")));

  await asyncQ.start();

    // normalQ: 1
    // normalQ: 2
    // normalQ: 3
    // normalQ: 4
```

### 2. Auto Star Queue

```
final autoAsyncQ = AsyncQueue.autoStart();

  autoAsyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 1), () => print("AutoQ: 1")));
  await Future.delayed(const Duration(seconds: 6));
  autoAsyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 0), () => print("AutoQ: 1.2")));
  autoAsyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 0), () => print("AutoQ: 1.3")));
  autoAsyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 4), () => print("AutoQ: 2")));
  autoAsyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 3), () => print("AutoQ: 2.2")));
  autoAsyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 2), () => print("AutoQ: 3")));
  autoAsyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 1), () => print("AutoQ: 4")));

    // AutoQ: 1
    // AutoQ: 1.2
    // AutoQ: 1.3
    // AutoQ: 2
    // AutoQ: 2.2
    // AutoQ: 3
    // AutoQ: 4
```

### Add Queue Listener

```
  final asyncQ = AsyncQueue();

  asyncQ.addQueueBeforeListener((event) => print("before $event"));
  asyncQ.addQueueAfterListener((event) => print("after $event"));
```

### Flutter use cases:

This package would be useful if you have multiple widget in a screen or event in multiple screen that need to do some async request that are related to each other.

For examples:

- To make one request from a widget wait for another request from another widget to finish.
- To avoid multiple requests from front end are hitting backend in a short time, that would confuse backend.

Code example:

```
 @override
  Widget build(BuildContext context) {
    final aQ = AsyncQueue.autoStart();
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {aQ.addJob(() => Future.delayed(const Duration(seconds: 2), () => print("job1 ")));},
            child: const Text('job1'),
          ),
          TextButton(
            onPressed: () async {aQ.addJob(() => Future.delayed(const Duration(seconds: 4), () => print("jobs2")));},
            child: const Text('job2'),
          ),
          TextButton(
            onPressed: () async {aQ.addJob(() => Future.delayed(const Duration(seconds: 1), () => print("job3")));},
            child: const Text('job3'),
          ),
        ],
      ),
    );
  }
```

## Appreciate Your Feedbacks and Contributes

If you find anything need to be improve or want to request a feature. Please go ahead and create an issue in the [Github](https://github.com/samderlust/async_queue) repo
