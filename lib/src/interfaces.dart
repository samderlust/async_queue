import 'async_node.dart';
import 'typedef.dart';

abstract class AsyncQueueInterface {
  void close();
  void stop([Function? callBack]);
  void clear([Function? callBack]);
  void retry();
  void addJob(AsyncJob job, {String? label, int retryTime});
  void addJobThrow(AsyncJob job);
  void addNode(AsyncNode node);
  Future<void> start();
  List<AsyncNode> list();
  AsyncNode getJob(String label);
}
