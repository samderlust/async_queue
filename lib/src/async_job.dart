import 'typedef.dart';

class AsyncNode {
  AsyncNode? next;
  final AsyncJob job;

  AsyncNode({required this.job});
}
