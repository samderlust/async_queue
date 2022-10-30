import 'package:async_queue/async_queue.dart';
import 'package:test/test.dart';

void main() {
  int count = 1;
  Future asyncJobMayFailed(Function job) async {
    if (count % 2 != 0) {
      count++;
      throw Exception('error');
    } else {
      count++;
      job();
    }
  }

  test('Job failed should retry ', () async {
    final q = AsyncQueue();
    int jobRunCount = 0;
    final List<int> res = [];

    q.addJob(
        () => Future.delayed(const Duration(milliseconds: 200), () async {
              try {
                jobRunCount++;
                print(jobRunCount);
                await asyncJobMayFailed(() => res.add(1));
              } catch (e) {
                q.retry();
              }
            }),
        retryTime: 1);

    q.addJob(
      () => Future.delayed(const Duration(milliseconds: 200), () {
        jobRunCount++;
        res.add(2);
      }),
    );

    await q.start();

    expect(jobRunCount, 3, reason: "job count");
    expect(res.length, 2);
    expect(res, [1, 2]);
  });

  test('Job should retry as many as commanded', () async {
    final q = AsyncQueue();
    int jobCount = 0;

    q.addJob(
        () => Future.delayed(const Duration(milliseconds: 200), () async {
              try {
                jobCount++;
                throw Exception('error');
              } catch (e) {
                q.retry();
              }
            }),
        retryTime: 3);

    await q.start();

    expect(jobCount, 4);
  });

  test('Default retry should be 1', () async {
    final q = AsyncQueue();
    int jobCount = 0;

    q.addJob(
      () => Future.delayed(const Duration(milliseconds: 200), () async {
        try {
          jobCount++;
          throw Exception('error');
        } catch (e) {
          q.retry();
        }
      }),
    );

    await q.start();
    expect(jobCount, 2);
  });
}
