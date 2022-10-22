import 'package:async_queue/async_queue.dart';

void main() async {
  final autoAsyncQ = AsyncQueue.autoStart();

  autoAsyncQ.addQueueListener((event) => print("The TIme ${event.time}"));

  autoAsyncQ
      .addJob(() => Future.delayed(const Duration(seconds: 1), () => print(1)));
  await Future.delayed(const Duration(seconds: 6));
  autoAsyncQ.addJob(
      () => Future.delayed(const Duration(seconds: 0), () => print(1.2)));
  autoAsyncQ.addJob(
      () => Future.delayed(const Duration(seconds: 0), () => print(1.3)));
  autoAsyncQ
      .addJob(() => Future.delayed(const Duration(seconds: 4), () => print(2)));
  autoAsyncQ.addJob(
      () => Future.delayed(const Duration(seconds: 3), () => print(2.2)));
  autoAsyncQ
      .addJob(() => Future.delayed(const Duration(seconds: 2), () => print(3)));
  autoAsyncQ
      .addJob(() => Future.delayed(const Duration(seconds: 1), () => print(4)));
}

void normalQ() {
  final asyncQ = AsyncQueue();
  asyncQ
      .addJob(() => Future.delayed(const Duration(seconds: 1), () => print(1)));
  asyncQ
      .addJob(() => Future.delayed(const Duration(seconds: 4), () => print(2)));
  asyncQ
      .addJob(() => Future.delayed(const Duration(seconds: 2), () => print(3)));
  asyncQ
      .addJob(() => Future.delayed(const Duration(seconds: 1), () => print(4)));

  asyncQ.start();
}
