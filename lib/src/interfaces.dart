import 'job_info.dart';
import 'typedef.dart';

abstract class AsyncQueueInterface {
  void close();
  void stop([Function? callBack]);
  void clear([Function? callBack]);
  void retry();
  void addJob(AsyncJob job, {String? label, int retryTime});
  Future<void> start();
  List<JobInfo> list();
  JobInfo getJobInfo(String label);
}
