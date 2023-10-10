import 'package:async_queue/src/async_queue_base.dart';
import 'package:async_queue/src/exceptions.dart';
import 'package:async_queue/src/queue_event.dart';
import 'package:test/test.dart';

void main() {
  test('jobs should be execute in order first come first serve', () async {
    final q = AsyncQueue();
    List<int> res = [];

    q.addJob((_) =>
        Future.delayed(const Duration(milliseconds: 100), () => res.add(1)));

    q.addJob((_) =>
        Future.delayed(const Duration(milliseconds: 400), () => res.add(2)));

    q.addJob((_) =>
        Future.delayed(const Duration(milliseconds: 300), () => res.add(3)));

    q.addJob((_) =>
        Future.delayed(const Duration(milliseconds: 200), () => res.add(4)));

    await q.start();

    expect(res, [1, 2, 3, 4]);
  });

  test('queue should be empty after execution', () async {
    final q = AsyncQueue();

    q.addJob((_) async {});
    q.addJob((_) async {});
    q.addJob((_) async {});
    q.addJob((_) async {});

    expect(q.size, 4);

    await q.start();

    expect(q.size, 0);
  });

  test('job should not be added if queue is closed', () {
    final q = AsyncQueue();

    q.addJob((_) async {});
    q.addJob((_) async {});
    q.addJob((_) async {});
    q.addJob((_) async {});

    q.close();

    q.addJob((_) async {});
    q.addJob((_) async {});

    expect(q.size, 4);
  });

  test('adding job to closed queue should throw Error', () {
    final q = AsyncQueue();

    q.addJobThrow((_) async {});

    q.close();

    expect(
      () => q.addJobThrow((_) async {}),
      throwsA(isA<ClosedQueueException>()),
    );

    expect(q.size, 1);
  });

  test('queue event must be emitted correctly', () async {
    final q = AsyncQueue();
    final List<QueueEvent> events = [];

    q.addQueueListener(events.add);

    q.addJob((_) async {});
    expect(events.last.type, QueueEventType.newJobAdded);

    q.close();
    expect(events.last.type, QueueEventType.queueClosed);

    await q.start();

    expect(events.length, 6);
    expect(events.map((e) => e.type), [
      QueueEventType.newJobAdded,
      QueueEventType.queueClosed,
      QueueEventType.queueStart,
      QueueEventType.beforeJob,
      QueueEventType.afterJob,
      QueueEventType.queueEnd,
    ]);
  });

  test('queue should stop executing ', () async {
    final q = AsyncQueue();

    q.addJob((_) => Future.delayed(const Duration(milliseconds: 100)));
    q.addJob((_) => Future.delayed(const Duration(milliseconds: 400)));
    q.addJob((_) => Future.delayed(const Duration(milliseconds: 300)));
    q.addJob((_) => Future.delayed(const Duration(milliseconds: 200)));

    expect(q.size, 4);

    q.start();

    Future.delayed(const Duration(milliseconds: 100), () => q.stop());

    expect(q.size, isNot(0));
  });

  test('job failed should stop', () async {
    final q = AsyncQueue();

    q.addJob(
      (_) => Future.delayed(const Duration(milliseconds: 200), () {
        q.stop();
      }),
    );

    q.addJob((_) => Future.delayed(const Duration(milliseconds: 300)));

    await q.start();

    expect(q.size, 0);
  });
}
