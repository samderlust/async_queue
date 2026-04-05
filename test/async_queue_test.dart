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
  test('job should return correct job label in events', () async {
    final q = AsyncQueue();
    final List<QueueEvent> events = [];
    q.addQueueListener(events.add);

    q.addJob(
      label: 'job1',
      (_) => Future.delayed(const Duration(milliseconds: 100)),
    );

    q.addJob(
      label: 'job2',
      (_) => Future.delayed(const Duration(milliseconds: 100)),
    );

    q.addJob(
      label: 'job3',
      (_) => Future.delayed(const Duration(milliseconds: 100)),
    );

    await q.start();

    expect(q.size, 0);

    final beforeEvents =
        events.where((e) => e.type == QueueEventType.beforeJob).toList();
    expect(beforeEvents.map((e) => e.jobLabel), ['job1', 'job2', 'job3']);

    final afterEvents =
        events.where((e) => e.type == QueueEventType.afterJob).toList();
    expect(afterEvents.map((e) => e.jobLabel), ['job1', 'job2', 'job3']);
  });

  group('AsyncQueue.autoStart', () {
    test('jobs execute in order as they are added', () async {
      final q = AsyncQueue.autoStart();
      final List<int> res = [];

      q.addJob((_) =>
          Future.delayed(const Duration(milliseconds: 100), () => res.add(1)));
      q.addJob((_) =>
          Future.delayed(const Duration(milliseconds: 50), () => res.add(2)));
      q.addJob((_) =>
          Future.delayed(const Duration(milliseconds: 50), () => res.add(3)));

      // wait for all jobs to finish
      await Future.delayed(const Duration(milliseconds: 400));

      expect(res, [1, 2, 3]);
      expect(q.size, 0);
    });

    test('job added after all previous jobs complete still executes', () async {
      final q = AsyncQueue.autoStart();
      final List<int> res = [];

      q.addJob((_) =>
          Future.delayed(const Duration(milliseconds: 50), () => res.add(1)));

      await Future.delayed(const Duration(milliseconds: 150));
      expect(res, [1]);

      q.addJob((_) =>
          Future.delayed(const Duration(milliseconds: 50), () => res.add(2)));

      await Future.delayed(const Duration(milliseconds: 150));
      expect(res, [1, 2]);
      expect(q.size, 0);
    });

    test('emits correct events', () async {
      final q = AsyncQueue.autoStart();
      final List<QueueEvent> events = [];
      q.addQueueListener(events.add);

      q.addJob(
        label: 'auto1',
        (_) => Future.delayed(const Duration(milliseconds: 50)),
      );

      await Future.delayed(const Duration(milliseconds: 150));

      final types = events.map((e) => e.type).toList();
      expect(types, contains(QueueEventType.newJobAdded));
      expect(types, contains(QueueEventType.queueStart));
      expect(types, contains(QueueEventType.beforeJob));
      expect(types, contains(QueueEventType.afterJob));
      expect(types, contains(QueueEventType.queueEnd));
    });

    test('stop cancels remaining jobs', () async {
      final q = AsyncQueue.autoStart();
      final List<int> res = [];

      q.addJob((_) => Future.delayed(
          const Duration(milliseconds: 100), () {
        res.add(1);
        q.stop();
      }));
      q.addJob((_) => Future.delayed(
          const Duration(milliseconds: 100), () => res.add(2)));
      q.addJob((_) => Future.delayed(
          const Duration(milliseconds: 100), () => res.add(3)));

      await Future.delayed(const Duration(milliseconds: 400));
      expect(res, [1]);
      expect(q.size, 0);
    });
  });
}
