import 'package:async_queue/async_queue.dart';
import 'package:test/test.dart';

void main() {
  group('Priority queue', () {
    test('higher priority jobs execute before lower priority', () async {
      final q = AsyncQueue();
      final List<String> res = [];

      q.addJob((_) async => res.add('low'), label: 'low', priority: 1);
      q.addJob((_) async => res.add('high'), label: 'high', priority: 10);
      q.addJob((_) async => res.add('mid'), label: 'mid', priority: 5);

      await q.start();

      expect(res, ['high', 'mid', 'low']);
    });

    test('same priority preserves FIFO order', () async {
      final q = AsyncQueue();
      final List<int> res = [];

      q.addJob((_) async => res.add(1), priority: 5);
      q.addJob((_) async => res.add(2), priority: 5);
      q.addJob((_) async => res.add(3), priority: 5);

      await q.start();

      expect(res, [1, 2, 3]);
    });

    test('default priority is 0', () async {
      final q = AsyncQueue();
      final List<String> res = [];

      q.addJob((_) async => res.add('default1'));
      q.addJob((_) async => res.add('high'), priority: 10);
      q.addJob((_) async => res.add('default2'));

      await q.start();

      expect(res, ['high', 'default1', 'default2']);
    });

    test('priority works with autoStart', () async {
      final q = AsyncQueue.autoStart();
      final List<String> res = [];

      // First job starts immediately
      q.addJob(
        (_) => Future.delayed(
            const Duration(milliseconds: 200), () => res.add('first')),
      );
      // While first is running, add more with different priorities
      await Future.delayed(const Duration(milliseconds: 50));
      q.addJob((_) async => res.add('low'), priority: 1);
      q.addJob((_) async => res.add('high'), priority: 10);
      q.addJob((_) async => res.add('mid'), priority: 5);

      await Future.delayed(const Duration(milliseconds: 500));

      // first executes first (already running), then by priority
      expect(res, ['first', 'high', 'mid', 'low']);
    });
  });
}
