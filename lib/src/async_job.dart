import 'typedef.dart';

///AsyncNode
///
///single node in the queue that contain an async job
class AsyncNode {
  AsyncNode? next;
  final AsyncJob job;

  AsyncNode({required this.job});
}
