import 'dart:async';

/// Performance metrics for a single action execution.
class ActionExecutionMetrics {
  /// Creates action execution metrics.
  ActionExecutionMetrics({
    required this.actionType,
    required this.duration,
    required this.timestamp,
    this.error,
  });

  /// Type of the action that was executed.
  final String actionType;

  /// Execution duration in milliseconds.
  final int duration;

  /// Timestamp when the action was executed.
  final DateTime timestamp;

  /// Error if the action failed.
  final Object? error;

  /// Whether the action execution was successful.
  bool get isSuccess => error == null;

  @override
  String toString() =>
      'ActionExecutionMetrics('
      'actionType: $actionType, '
      'duration: ${duration}ms, '
      'success: $isSuccess'
      ')';
}

/// Batch processing metrics.
class BatchProcessingMetrics {
  /// Creates batch processing metrics.
  BatchProcessingMetrics({
    required this.actionsProcessed,
    required this.totalDuration,
    required this.timestamp,
    required this.isSimpleMode,
    this.averageActionDuration,
    this.maxActionDuration,
    this.minActionDuration,
  });

  /// Number of actions processed in this batch.
  final int actionsProcessed;

  /// Total duration of batch processing in milliseconds.
  final int totalDuration;

  /// Timestamp when the batch was processed.
  final DateTime timestamp;

  /// Whether the store is in simple mode (no batching).
  final bool isSimpleMode;

  /// Average duration per action in milliseconds.
  final int? averageActionDuration;

  /// Maximum action duration in this batch in milliseconds.
  final int? maxActionDuration;

  /// Minimum action duration in this batch in milliseconds.
  final int? minActionDuration;

  @override
  String toString() =>
      'BatchProcessingMetrics('
      'actionsProcessed: $actionsProcessed, '
      'totalDuration: ${totalDuration}ms, '
      'avgDuration: ${averageActionDuration ?? 'N/A'}ms, '
      'mode: ${isSimpleMode ? 'simple' : 'batched'}'
      ')';
}

/// Performance profiler for tracking PureStore metrics.
///
/// Collects metrics about action execution times, batch processing,
/// and overall store performance.
///
/// Example:
/// ```dart
/// final profiler = PurePerformanceProfiler();
/// store.enableProfiling(profiler);
///
/// // After some actions...
/// final metrics = profiler.getMetrics();
/// print('Total actions: ${metrics.totalActions}');
/// print('Average duration: ${metrics.averageActionDuration}ms');
/// ```
class PurePerformanceProfiler {
  /// Creates a new performance profiler.
  ///
  /// - [maxHistorySize]: Maximum number of action executions to keep in history
  /// - [maxBatchHistorySize]: Maximum number of batch processing records to keep
  /// - [enableDetailedMetrics]: Whether to collect detailed per-action metrics
  PurePerformanceProfiler({
    this.maxHistorySize = 1000,
    this.maxBatchHistorySize = 100,
    this.enableDetailedMetrics = true,
  });

  /// Maximum number of action executions to keep in history.
  final int maxHistorySize;

  /// Maximum number of batch processing records to keep.
  final int maxBatchHistorySize;

  /// Whether to collect detailed per-action metrics.
  final bool enableDetailedMetrics;

  /// List of action execution metrics.
  final List<ActionExecutionMetrics> _actionMetrics = [];

  /// List of batch processing metrics.
  final List<BatchProcessingMetrics> _batchMetrics = [];

  /// Total number of actions executed.
  int _totalActions = 0;

  /// Total number of successful actions.
  int _successfulActions = 0;

  /// Total number of failed actions.
  int _failedActions = 0;

  /// Total execution time in milliseconds.
  int _totalExecutionTime = 0;

  /// Stream controller for action metrics.
  final StreamController<ActionExecutionMetrics> _actionMetricsController =
      StreamController<ActionExecutionMetrics>.broadcast();

  /// Stream controller for batch metrics.
  final StreamController<BatchProcessingMetrics> _batchMetricsController =
      StreamController<BatchProcessingMetrics>.broadcast();

  /// Stream of action execution metrics.
  Stream<ActionExecutionMetrics> get actionMetricsStream =>
      _actionMetricsController.stream;

  /// Stream of batch processing metrics.
  Stream<BatchProcessingMetrics> get batchMetricsStream =>
      _batchMetricsController.stream;

  /// Records an action execution.
  void recordActionExecution(
    String actionType,
    Duration duration, {
    Object? error,
  }) {
    if (!enableDetailedMetrics) return;

    final metrics = ActionExecutionMetrics(
      actionType: actionType,
      duration: duration.inMilliseconds,
      timestamp: DateTime.now(),
      error: error,
    );

    _actionMetrics.add(metrics);
    if (_actionMetrics.length > maxHistorySize) {
      _actionMetrics.removeAt(0);
    }

    _totalActions++;
    if (error != null) {
      _failedActions++;
    } else {
      _successfulActions++;
    }
    _totalExecutionTime += duration.inMilliseconds;

    if (!_actionMetricsController.isClosed) {
      _actionMetricsController.add(metrics);
    }
  }

  /// Records batch processing metrics.
  void recordBatchProcessing(BatchProcessingMetrics metrics) {
    _batchMetrics.add(metrics);
    if (_batchMetrics.length > maxBatchHistorySize) {
      _batchMetrics.removeAt(0);
    }

    if (!_batchMetricsController.isClosed) {
      _batchMetricsController.add(metrics);
    }
  }

  /// Gets comprehensive performance metrics.
  PerformanceMetrics getMetrics() {
    return PerformanceMetrics(
      totalActions: _totalActions,
      successfulActions: _successfulActions,
      failedActions: _failedActions,
      totalExecutionTime: _totalExecutionTime,
      averageActionDuration: _totalActions > 0
          ? _totalExecutionTime / _totalActions
          : 0.0,
      successRate: _totalActions > 0 ? _successfulActions / _totalActions : 0.0,
      actionMetricsHistory: enableDetailedMetrics
          ? List.unmodifiable(_actionMetrics)
          : [],
      batchMetricsHistory: List.unmodifiable(_batchMetrics),
    );
  }

  /// Gets action execution metrics filtered by action type.
  List<ActionExecutionMetrics> getActionMetricsByType(String actionType) {
    if (!enableDetailedMetrics) return [];
    return _actionMetrics
        .where((m) => m.actionType == actionType)
        .toList(growable: false);
  }

  /// Gets recent action metrics (last N actions).
  List<ActionExecutionMetrics> getRecentActionMetrics(int count) {
    if (!enableDetailedMetrics) return [];
    final start = _actionMetrics.length > count
        ? _actionMetrics.length - count
        : 0;
    return _actionMetrics.sublist(start).toList(growable: false);
  }

  /// Gets recent batch metrics (last N batches).
  List<BatchProcessingMetrics> getRecentBatchMetrics(int count) {
    final start = _batchMetrics.length > count
        ? _batchMetrics.length - count
        : 0;
    return _batchMetrics.sublist(start).toList(growable: false);
  }

  /// Gets metrics for actions in a time range.
  List<ActionExecutionMetrics> getActionMetricsInRange(
    DateTime start,
    DateTime end,
  ) {
    if (!enableDetailedMetrics) return [];
    return _actionMetrics
        .where((m) => m.timestamp.isAfter(start) && m.timestamp.isBefore(end))
        .toList(growable: false);
  }

  /// Resets all collected metrics.
  void reset() {
    _actionMetrics.clear();
    _batchMetrics.clear();
    _totalActions = 0;
    _successfulActions = 0;
    _failedActions = 0;
    _totalExecutionTime = 0;
  }

  /// Disposes the profiler and releases resources.
  void dispose() {
    _actionMetrics.clear();
    _batchMetrics.clear();
    unawaited(_actionMetricsController.close());
    unawaited(_batchMetricsController.close());
  }
}

/// Comprehensive performance metrics.
class PerformanceMetrics {
  /// Creates performance metrics.
  PerformanceMetrics({
    required this.totalActions,
    required this.successfulActions,
    required this.failedActions,
    required this.totalExecutionTime,
    required this.averageActionDuration,
    required this.successRate,
    required this.actionMetricsHistory,
    required this.batchMetricsHistory,
  });

  /// Total number of actions executed.
  final int totalActions;

  /// Number of successful actions.
  final int successfulActions;

  /// Number of failed actions.
  final int failedActions;

  /// Total execution time in milliseconds.
  final int totalExecutionTime;

  /// Average action duration in milliseconds.
  final double averageActionDuration;

  /// Success rate (0.0 to 1.0).
  final double successRate;

  /// History of action execution metrics.
  final List<ActionExecutionMetrics> actionMetricsHistory;

  /// History of batch processing metrics.
  final List<BatchProcessingMetrics> batchMetricsHistory;

  /// Gets the slowest action from history.
  ActionExecutionMetrics? get slowestAction {
    if (actionMetricsHistory.isEmpty) return null;
    return actionMetricsHistory.reduce(
      (a, b) => a.duration > b.duration ? a : b,
    );
  }

  /// Gets the fastest action from history.
  ActionExecutionMetrics? get fastestAction {
    if (actionMetricsHistory.isEmpty) return null;
    return actionMetricsHistory.reduce(
      (a, b) => a.duration < b.duration ? a : b,
    );
  }

  /// Gets actions per second (calculated from recent history).
  double get actionsPerSecond {
    if (actionMetricsHistory.isEmpty) return 0;
    final recent = actionMetricsHistory.length > 10
        ? actionMetricsHistory.sublist(actionMetricsHistory.length - 10)
        : actionMetricsHistory;

    if (recent.length < 2) return 0;

    final duration = recent.last.timestamp.difference(recent.first.timestamp);
    if (duration.inSeconds == 0) return recent.length.toDouble();

    return recent.length / duration.inSeconds;
  }

  @override
  String toString() =>
      'PerformanceMetrics('
      'totalActions: $totalActions, '
      'successRate: ${(successRate * 100).toStringAsFixed(1)}%, '
      'avgDuration: ${averageActionDuration.toStringAsFixed(2)}ms, '
      'actionsPerSecond: ${actionsPerSecond.toStringAsFixed(2)}'
      ')';
}
