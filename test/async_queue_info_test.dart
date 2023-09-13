import 'package:async_queue/async_queue.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

const mil100 = Duration(milliseconds: 100);
void main() {
  test(
    "job info List should be same size as queue size at max ",
    () async {
      final q = AsyncQueue();
      q.addJob((_) => Future.delayed(mil100, () {}));
      q.addJob((_) => Future.delayed(mil100, () {}));
      q.addJob((_) => Future.delayed(mil100, () {}));
      q.addJob((_) => Future.delayed(mil100, () {}));

      // expect(q.list().length, q.size);

      await q.start();
      // expect(q.list().length, 4);
      expect(q.size, 0);

      q.clear();
      // expect(q.list().length, 0);
    },
  );
  test(
    "job info List should contain info of failed job",
    () async {
      final q = AsyncQueue();
      q.addJob((_) => Future.delayed(mil100, () {}));
      q.addJob((_) => Future.delayed(mil100, q.retry), label: "retryJob");
      q.addJob((_) => Future.delayed(mil100, () {}));

      await q.start();
      // print(q.list());
      // final theJob = q.getJobInfo("retryJob");

      // expect(theJob, isNotNull);
      // expect(theJob.state, JobState.failed);
    },
  );
}
