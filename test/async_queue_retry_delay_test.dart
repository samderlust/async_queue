import 'package:async_queue/async_queue.dart';
import 'package:test/test.dart';

void main() {
  group('Retry with delay', () {
    test('retryDelay adds wait between retries', () async {
      final q = AsyncQueue();
      final timestamps = <int>[];

      q.addJob(
        (_) async {
          timestamps.add(DateTime.now().millisecondsSinceEpoch);
          throw Exception('fail');
        },
        retryTime: 2,
        retryDelay: const Duration(milliseconds: 200),
      );

      await q.start();

      // 1 initial + 2 retries = 3 attempts
      expect(timestamps.length, 3);

      // Check delay between attempts (~200ms each)
      final gap1 = timestamps[1] - timestamps[0];
      final gap2 = timestamps[2] - timestamps[1];
      expect(gap1, greaterThan(150));
      expect(gap2, greaterThan(150));
    });

    test('no delay when retryDelay is not set', () async {
      final q = AsyncQueue();
      final timestamps = <int>[];

      q.addJob(
        (_) async {
          timestamps.add(DateTime.now().millisecondsSinceEpoch);
          throw Exception('fail');
        },
        retryTime: 2,
      );

      await q.start();

      expect(timestamps.length, 3);

      // Without delay, gaps should be very small
      final gap1 = timestamps[1] - timestamps[0];
      expect(gap1, lessThan(100));
    });

    test('retryDelay works with manual retry', () async {
      final q = AsyncQueue();
      final timestamps = <int>[];
      int count = 0;

      q.addJob(
        (_) async {
          timestamps.add(DateTime.now().millisecondsSinceEpoch);
          count++;
          if (count < 3) {
            q.retry();
          }
        },
        retryTime: 3,
        retryDelay: const Duration(milliseconds: 150),
      );

      await q.start();

      expect(timestamps.length, 3);
      final gap = timestamps[1] - timestamps[0];
      expect(gap, greaterThan(100));
    });
  });
}
