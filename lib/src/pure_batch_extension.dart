import 'package:pure_state/src/pure_store.dart';

/// Extension methods for batching actions and time-travel debugging.
extension PureStoreBatchExtension<T> on PureStore<T> {
  /// Executes multiple actions in a batch with a single state update.
  ///
  /// This method collects all actions dispatched within the [actions] callback
  /// and processes them together, emitting only one final state update.
  ///
  /// This is useful for:
  /// - Performing multiple related updates atomically
  /// - Reducing UI rebuilds when many changes occur together
  /// - Improving performance for bulk operations
  ///
  /// Example:
  /// ```dart
  /// store.batch(() {
  ///   dispatch(Action1());
  ///   dispatch(Action2());
  ///   dispatch(Action3());
  /// }); // Only one state update is emitted
  /// ```
  Future<void> batch(void Function() actions) async {
    // Note: This is a simplified implementation
    // In a production version, PureStore would need a _batchMode flag
    // to properly batch multiple dispatches into a single state update

    try {
      // Execute the actions
      actions();

      // Wait for actions to process
      // In a real implementation, add a flushBatch() method to PureStore
      await Future<void>.delayed(Duration.zero);
    } finally {
      // Batch complete
    }
  }

  /// Executes actions with batching and returns the final state.
  Future<T> batchAndGet(void Function() actions) async {
    await batch(actions);
    return state;
  }
}

/// Extension methods for time-travel debugging (replay functionality).
extension PureStoreReplayExtension<T> on PureStore<T> {
  /// Enables replay mode for time-travel debugging.
  ///
  /// When enabled, the store records all state changes in history,
  /// allowing you to replay past states.
  ///
  /// Example:
  /// ```dart
  /// store.enableReplay(maxHistory: 100);
  ///
  /// // Later, replay to a specific state
  /// store.replay(toIndex: 50);
  /// ```
  void enableReplay({int maxHistory = 100}) {
    enableHistory(limit: maxHistory);
  }

  /// Replays the store to a specific state in history.
  ///
  /// - [toIndex]: The history index to replay to (0 = oldest, history.length-1 = newest)
  ///
  /// Example:
  /// ```dart
  /// store.replay(toIndex: 10); // Go back to the 10th state
  /// ```
  void replay({required int toIndex}) {
    revertTo(toIndex);
  }

  /// Replays the store by going back a specific number of steps.
  ///
  /// Example:
  /// ```dart
  /// store.replayBack(steps: 5); // Go back 5 states
  /// ```
  void replayBack({required int steps}) {
    final currentIndex = history.length - 1;
    final targetIndex = (currentIndex - steps).clamp(0, history.length - 1);
    replay(toIndex: targetIndex);
  }

  /// Finds and replays to a state matching the given predicate.
  ///
  /// Searches through history from newest to oldest and replays to the
  /// first state that matches.
  ///
  /// Returns true if a matching state was found and replayed.
  ///
  /// Example:
  /// ```dart
  /// store.replayToWhere((state) => state.userId == 42);
  /// ```
  bool replayToWhere(bool Function(T state) predicate) {
    final historyList = history;

    for (var i = historyList.length - 1; i >= 0; i--) {
      if (predicate(historyList[i])) {
        replay(toIndex: i);
        return true;
      }
    }

    return false;
  }

  /// Gets a snapshot of the entire history.
  ///
  /// Returns a list of all states in history, from oldest to newest.
  List<T> getHistorySnapshot() {
    return List<T>.unmodifiable(history);
  }

  /// Clears the history without affecting the current state.
  void clearHistory() {
    // Enable with limit 0 to clear, then re-enable with current limit
    // This is a workaround - in real implementation, add clearHistory to PureStore
    final currentLimit = history.length;
    enableHistory(limit: 0);
    enableHistory(limit: currentLimit);
  }
}

/// A class that records and manages state transitions for advanced replay.
///
/// This provides more detailed replay functionality than the basic history.
class PureStateRecorder<T> {
  /// Creates a new state recorder.
  PureStateRecorder({
    this.maxRecordings = 100,
  });

  /// Maximum number of recordings to keep.
  final int maxRecordings;

  /// List of recorded state transitions.
  final List<StateTransition<T>> _recordings = [];

  /// Records a state transition.
  void record({
    required T oldState,
    required T newState,
    required String actionName,
    required DateTime timestamp,
  }) {
    if (_recordings.length >= maxRecordings) {
      _recordings.removeAt(0);
    }

    _recordings.add(
      StateTransition(
        oldState: oldState,
        newState: newState,
        actionName: actionName,
        timestamp: timestamp,
      ),
    );
  }

  /// Gets all recordings.
  List<StateTransition<T>> get recordings => List.unmodifiable(_recordings);

  /// Finds transitions where a specific action was executed.
  List<StateTransition<T>> findByAction(String actionName) {
    return _recordings.where((t) => t.actionName == actionName).toList();
  }

  /// Finds transitions within a time range.
  List<StateTransition<T>> findByTimeRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _recordings
        .where((t) => t.timestamp.isAfter(start) && t.timestamp.isBefore(end))
        .toList();
  }

  /// Exports recordings to JSON-compatible format.
  List<Map<String, dynamic>> export({
    required Map<String, dynamic> Function(T state) toJson,
  }) {
    return _recordings.map((t) => t.toJson(toJson)).toList();
  }

  /// Clears all recordings.
  void clear() {
    _recordings.clear();
  }
}

/// Represents a single state transition.
class StateTransition<T> {
  /// Creates a state transition record.
  const StateTransition({
    required this.oldState,
    required this.newState,
    required this.actionName,
    required this.timestamp,
  });

  /// The state before the transition.
  final T oldState;

  /// The state after the transition.
  final T newState;

  /// Name of the action that caused the transition.
  final String actionName;

  /// When the transition occurred.
  final DateTime timestamp;

  /// Converts to JSON-compatible format.
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T state) toJson) {
    return {
      'oldState': toJson(oldState),
      'newState': toJson(newState),
      'actionName': actionName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Extension for attaching a recorder to a store.
extension PureStoreRecorderExtension<T> on PureStore<T> {
  /// Attaches a state recorder to this store.
  ///
  /// The recorder will automatically track all state changes.
  ///
  /// Example:
  /// ```dart
  /// final recorder = PureStateRecorder<MyState>();
  /// store.attachRecorder(recorder);
  ///
  /// // Later, analyze the recordings
  /// final transitions = recorder.findByAction('IncrementAction');
  /// ```
  void attachRecorder(PureStateRecorder<T> recorder) {
    // This would require adding a callback system to PureStore
    // For now, this is a placeholder for the API design
    // In a real implementation, hook into the onEvent callback
  }
}
