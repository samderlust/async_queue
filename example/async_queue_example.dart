import 'package:async_queue/async_queue.dart';

void main() async {
  await normalQ();
  await autoQ();
}

Future<void> normalQ() async {
  final asyncQ = AsyncQueue();

  asyncQ.addQueueBeforeListener((event) => print("before $event"));
  asyncQ.addQueueAfterListener((event) => print("after $event"));

  asyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 1), () => print("normalQ: 1")));
  asyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 4), () => print("normalQ: 2")));
  asyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 2), () => print("normalQ: 3")));
  asyncQ.addJob(() =>
      Future.delayed(const Duration(seconds: 1), () => print("normalQ: 4")));

  await asyncQ.start();
}

Future<void> autoQ() async {
  final autoAsyncQ = AsyncQueue.autoStart();

  // autoAsyncQ.addQueueListener((event) => print(event));

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
}
