import 'package:async_queue/async_queue.dart';
import 'package:test/test.dart';

void main() {
  group('addJob returns Future', () {
    test('future completes with job result', () async {
      final q = AsyncQueue();

      final future = q.addJob((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 42;
      });

      await q.start();

      expect(await future, 42);
    });

    test('each job future returns its own result', () async {
      final q = AsyncQueue();

      final f1 = q.addJob((_) async => 'first');
      final f2 = q.addJob((_) async => 'second');
      final f3 = q.addJob((_) async => 'third');

      await q.start();

      expect(await f1, 'first');
      expect(await f2, 'second');
      expect(await f3, 'third');
    });

    test('future works with autoStart', () async {
      final q = AsyncQueue.autoStart();

      final f1 = q.addJob((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 'hello';
      });

      final f2 = q.addJob((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 'world';
      });

      expect(await f1, 'hello');
      expect(await f2, 'world');
    });

    test('previousResult still works alongside returned future', () async {
      final q = AsyncQueue();

      final f1 = q.addJob((_) async => 10);
      final f2 = q.addJob((prev) async => prev + 5);
      final f3 = q.addJob((prev) async => prev * 2);

      await q.start();

      expect(await f1, 10);
      expect(await f2, 15);
      expect(await f3, 30);
    });

    test('returns null future when queue is closed', () async {
      final q = AsyncQueue();
      q.close();

      final result = await q.addJob((_) async => 'should not run');
      expect(result, isNull);
    });

    test('addJobThrow returns future with result', () async {
      final q = AsyncQueue();

      final future = q.addJobThrow((_) async => 'from addJobThrow');

      await q.start();

      expect(await future, 'from addJobThrow');
    });
  });
}
