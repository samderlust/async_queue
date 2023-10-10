import 'package:async_queue/async_queue.dart';

void main() async {
  // await normalQ();
  // await autoQ();
  await autoQGetData();
}

Future<void> normalQ() async {
  final asyncQ = AsyncQueue();

  asyncQ.addQueueListener((event) => print(event));

  asyncQ.addJob((_) => Future.delayed(
      const Duration(milliseconds: 100), () => print("normalQ: 1")));
  asyncQ.addJob((_) => Future.delayed(
      const Duration(milliseconds: 400), () => print("normalQ: 2")));

  asyncQ.addJob((_) => Future.delayed(
      const Duration(milliseconds: 400), () => print("normalQ: 4")));

  await asyncQ.start();
}

Future<void> autoQ() async {
  final autoAsyncQ = AsyncQueue.autoStart();

  autoAsyncQ.addJob((_) =>
      Future.delayed(const Duration(seconds: 1), () => print("AutoQ: 1")));
  await Future.delayed(const Duration(seconds: 6));
  autoAsyncQ.addJob((_) =>
      Future.delayed(const Duration(seconds: 0), () => print("AutoQ: 1.2")));
  autoAsyncQ.addJob((_) =>
      Future.delayed(const Duration(seconds: 0), () => print("AutoQ: 1.3")));
  autoAsyncQ.addJob((_) =>
      Future.delayed(const Duration(seconds: 4), () => print("AutoQ: 2")));
  autoAsyncQ.addJob((_) =>
      Future.delayed(const Duration(seconds: 3), () => print("AutoQ: 2.2")));
  autoAsyncQ.addJob((_) =>
      Future.delayed(const Duration(seconds: 2), () => print("AutoQ: 3")));
  autoAsyncQ.addJob((_) =>
      Future.delayed(const Duration(seconds: 1), () => print("AutoQ: 4")));
}

// Get data from previous task
Future<void> autoQGetData() async {
  final autoAsyncQ = AsyncQueue.autoStart();

  autoAsyncQ.addJob((_) => Future.delayed(const Duration(seconds: 1), () => 1));
  await Future.delayed(const Duration(seconds: 6));
  autoAsyncQ.addJob((t) => Future.delayed(const Duration(seconds: 0), () {
        t++;
        print(t);
        return t;
      }));
  autoAsyncQ.addJob((t) => Future.delayed(const Duration(seconds: 0), () {
        t++;
        print(t);
        return t;
      }));
  autoAsyncQ.addJob((t) => Future.delayed(const Duration(seconds: 4), () {
        t++;
        print(t);
        return t;
      }));
  autoAsyncQ.addJob((t) => Future.delayed(const Duration(seconds: 3), () {
        t++;
        print(t);
        return t;
      }));
  autoAsyncQ.addJob((t) => Future.delayed(const Duration(seconds: 2), () {
        t++;
        print(t);
        return t;
      }));
  autoAsyncQ.addJob((t) => Future.delayed(const Duration(seconds: 1), () {
        t++;
        print(t);
        return t;
      }));
}
