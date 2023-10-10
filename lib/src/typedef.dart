import 'queue_event.dart';

typedef PreviousResult = dynamic;

/// a single job that need to be added to the Queue
///
/// provide previous job's result as parameter.
/// Ignore it using `_` when declare if you don't need it.
typedef AsyncJob = Function(PreviousResult previousResult);
typedef QueueListener = Function(QueueEvent event);
typedef CurrentJobUpdater = Function(Object? jobLabel);
