import 'typedef.dart';

abstract class AsyncQueueInterface {
  void close();
  void stop([Function? callBack]);
  void clear([Function? callBack]);
  void retry();
  Future<dynamic> addJob(AsyncJob job, {Object? label, String? description, int retryTime, int priority, Duration? retryDelay});
  Future<dynamic> addJobThrow(AsyncJob job, {Object? label, String? description, int retryTime, int priority, Duration? retryDelay});
  Future<void> start();
}
