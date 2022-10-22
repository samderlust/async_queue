import 'package:async_queue/src/queue_event.dart';

import 'async_job.dart';
import 'typedef.dart';

class AsyncQueue {
  AsyncNode? _first;
  AsyncNode? _last;
  int _size = 0;
  bool _autoRun = false;
  bool _isRunning = false;
  QueueListener? _listener;

  AsyncQueue();

  factory AsyncQueue.autoStart() => AsyncQueue().._autoRun = true;

  void addQueueListener(QueueListener listener) => _listener = listener;

  int get size => _size;

  void addJob(AsyncJob job) {
    final newNode = AsyncNode(job: job);
    _enqueue(newNode);

    if (_autoRun) start();
  }

  Future start() async {
    if (size == 0 || _isRunning) return;

    _isRunning = true;

    while (size > 0) {
      await dequeue();
    }

    _isRunning = false;
  }

  void _enqueue(AsyncNode node) {
    if (_first == null) {
      _first = node;
      _last = node;
    } else {
      _last!.next = node;
      _last = node;
    }
    _size++;
  }

  Future dequeue() async {
    if (_first == null) return;

    var currentNode = _first;

    if (_listener != null) _listener!(QueueEvent(currentQueueSize: _size));

    await _first!.job();

    if (_size == 1) {
      _first = null;
      _last = null;
    } else {
      _first = currentNode?.next;
      currentNode?.next = null;
    }
    _size--;
  }
}
