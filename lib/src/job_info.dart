import 'async_node.dart';

/// Show info of the a job
///
/// this info can be obtain by calling [AsyncQueue.list] or [AsyncQueue.getJobInfo]
class JobInfo {
  final String label;
  final String? description;
  final JobState state;
  final int retryCount;
  final int maxRetry;
  JobInfo({
    required this.label,
    this.description,
    required this.state,
    required this.retryCount,
    required this.maxRetry,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is JobInfo &&
        other.label == label &&
        other.description == description &&
        other.state == state &&
        other.retryCount == retryCount &&
        other.maxRetry == maxRetry;
  }

  @override
  int get hashCode {
    return label.hashCode ^
        description.hashCode ^
        state.hashCode ^
        retryCount.hashCode ^
        maxRetry.hashCode;
  }

  JobInfo copyWith({
    String? label,
    String? description,
    JobState? state,
    int? retryCount,
    int? maxRetry,
  }) {
    return JobInfo(
      label: label ?? this.label,
      description: description ?? this.description,
      state: state ?? this.state,
      retryCount: retryCount ?? this.retryCount,
      maxRetry: maxRetry ?? this.maxRetry,
    );
  }

  @override
  String toString() {
    return 'JobInfo(label: $label, description: $description, state: $state, retryCount: $retryCount, maxRetry: $maxRetry)\n';
  }
}
