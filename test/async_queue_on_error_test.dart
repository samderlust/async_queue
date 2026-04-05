import 'package:async_queue/async_queue.dart';
import 'package:test/test.dart';

void main() {
  group('onError callback', () {
    test('is called when a job throws', () async {
      Object? capturedError;
      Object? capturedLabel;

      final q = AsyncQueue(
        onError: (error, label) {
          capturedError = error;
          capturedLabel = label;
        },
      );

      q.addJob(
        (_) async => throw Exception('boom'),
        label: 'failJob',
      );

      await q.start();

      expect(capturedError, isA<Exception>());
      expect(capturedLabel, 'failJob');
    });

    test('is called for each failed attempt', () async {
      final errors = <Object>[];

      final q = AsyncQueue(
        onError: (error, label) {
          errors.add(error);
        },
      );

      q.addJob(
        (_) async => throw Exception('fail'),
        label: 'retryJob',
        retryTime: 3,
      );

      await q.start();

      // 1 initial + 3 retries = 4 calls
      expect(errors.length, 4);
    });

    test('works with autoStart', () async {
      Object? capturedLabel;

      final q = AsyncQueue.autoStart(
        onError: (error, label) {
          capturedLabel = label;
        },
      );

      q.addJob(
        (_) async => throw Exception('auto fail'),
        label: 'autoFail',
      );

      await Future.delayed(const Duration(milliseconds: 300));

      expect(capturedLabel, 'autoFail');
    });

    test('is not called when job succeeds', () async {
      bool called = false;

      final q = AsyncQueue(
        onError: (error, label) {
          called = true;
        },
      );

      q.addJob((_) async => 'ok');

      await q.start();

      expect(called, false);
    });
  });
}
