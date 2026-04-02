import 'package:async_queue/async_queue.dart';
import 'package:test/test.dart';

const mil100 = Duration(milliseconds: 100);
void main() {
  test(
    "queue size should be 0 after execution and clear",
    () async {
      final q = AsyncQueue();
      q.addJob((_) => Future.delayed(mil100, () {}));
      q.addJob((_) => Future.delayed(mil100, () {}));
      q.addJob((_) => Future.delayed(mil100, () {}));
      q.addJob((_) => Future.delayed(mil100, () {}));

      await q.start();
      expect(q.size, 0);

      q.clear();
    },
  );
  test(
    "retry job should emit retryJob event",
    () async {
      final q = AsyncQueue();
      final List<QueueEvent> events = [];
      q.addQueueListener(events.add);

      q.addJob((_) => Future.delayed(mil100, () {}));
      q.addJob((_) => Future.delayed(mil100, q.retry), label: "retryJob");
      q.addJob((_) => Future.delayed(mil100, () {}));

      await q.start();

      final retryEvents =
          events.where((e) => e.type == QueueEventType.retryJob);
      expect(retryEvents, isNotEmpty);
      expect(retryEvents.first.jobLabel, "retryJob");
    },
  );
}
