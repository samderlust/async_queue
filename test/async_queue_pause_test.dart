import 'package:async_queue/async_queue.dart';
import 'package:test/test.dart';

void main() {
  group('Pause / Resume', () {
    test('pause stops processing, resume continues', () async {
      final q = AsyncQueue.autoStart();
      final List<int> res = [];

      q.addJob((_) => Future.delayed(
          const Duration(milliseconds: 200), () => res.add(1)));
      q.addJob((_) => Future.delayed(
          const Duration(milliseconds: 200), () => res.add(2)));
      q.addJob((_) => Future.delayed(
          const Duration(milliseconds: 200), () => res.add(3)));

      // Pause while first job is still running
      await Future.delayed(const Duration(milliseconds: 100));
      q.pause();

      // Wait for first job to finish, pause takes effect before second starts
      await Future.delayed(const Duration(milliseconds: 300));
      expect(res, [1]);
      expect(q.size, 2);
      expect(q.isPaused, true);

      // Resume and let remaining jobs finish
      q.resume();
      await Future.delayed(const Duration(milliseconds: 600));

      expect(res, [1, 2, 3]);
      expect(q.size, 0);
      expect(q.isPaused, false);
    });

    test('pause preserves queued jobs (unlike stop)', () async {
      final q = AsyncQueue();
      final List<int> res = [];

      q.addJob((_) async => res.add(1));
      q.addJob((_) async => res.add(2));
      q.addJob((_) async => res.add(3));

      expect(q.size, 3);
      q.pause();
      expect(q.size, 3); // jobs preserved

      q.resume();
      await q.start();

      expect(res, [1, 2, 3]);
    });

    test('emits queuePaused and queueResumed events', () async {
      final q = AsyncQueue();
      final List<QueueEventType> events = [];
      q.addQueueListener((e) => events.add(e.type));

      q.addJob((_) async {});

      q.pause();
      q.resume();

      expect(events, contains(QueueEventType.queuePaused));
      expect(events, contains(QueueEventType.queueResumed));
    });

    test('resume is a no-op when not paused', () async {
      final q = AsyncQueue();
      final List<QueueEventType> events = [];
      q.addQueueListener((e) => events.add(e.type));

      q.resume();

      expect(events, isNot(contains(QueueEventType.queueResumed)));
    });
  });
}
