import 'queue_event.dart';

typedef AsyncJob = Future Function();
typedef QueueListener = Function(QueueEvent event);
