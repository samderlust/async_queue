import 'dart:async';

import 'package:async_queue/async_queue.dart';
import 'package:test/test.dart';

void main() {
  group('Job timeout', () {
    test('timed out job triggers auto-retry', () async {
      final q = AsyncQueue();
      int attempts = 0;

      q.addJob(
        (_) async {
          attempts++;
          if (attempts < 3) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          return 'done';
        },
        retryTime: 3,
        timeout: const Duration(milliseconds: 100),
      );

      await q.start();

      expect(attempts, 3);
    });

    test('job within timeout succeeds normally', () async {
      final q = AsyncQueue();

      q.addJob(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 42;
        },
        timeout: const Duration(milliseconds: 200),
      );

      final future = q.addJob((_) async => 'next');

      await q.start();

      expect(await future, 'next');
    });

    test('timeout emits jobError event', () async {
      final q = AsyncQueue();
      final events = <QueueEventType>[];
      q.addQueueListener((e) => events.add(e.type));

      q.addJob(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        timeout: const Duration(milliseconds: 50),
        retryTime: 0,
      );

      await q.start();

      expect(events, contains(QueueEventType.jobError));
    });

    test('TimeoutException is passed to onError', () async {
      Object? capturedError;

      final q = AsyncQueue(
        onError: (error, label) {
          capturedError = error;
        },
      );

      q.addJob(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        timeout: const Duration(milliseconds: 50),
        retryTime: 0,
      );

      await q.start();

      expect(capturedError, isA<TimeoutException>());
    });
  });
}
