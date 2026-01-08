import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:pure_state/src/pure_action.dart';
import 'package:pure_state/src/pure_store.dart';

/// A middleware that logs action execution and state changes.
///
/// Use [PureLogger] to debug your application by seeing what actions are
/// dispatched and how they affect the state.
class PureLogger<T> {
  /// Creates a logging middleware.
  ///
  /// - [name]: Optional name for the logger (useful for multiple stores)
  /// - [logActions]: Whether to log actions
  /// - [logState]: Whether to log state changes
  /// - [logErrors]: Whether to log errors
  /// - [printFunction]: Function to use for printing (defaults to [debugPrint])
  PureLogger({
    this.name,
    this.logActions = true,
    this.logState = true,
    this.logErrors = true,
    void Function(String message)? printFunction,
  }) : printFunction = printFunction ?? debugPrint;

  /// Logger name.
  final String? name;

  /// Whether to log actions.
  final bool logActions;

  /// Whether to log state changes.
  final bool logState;

  /// Whether to log errors.
  final bool logErrors;

  /// Function used for printing logs.
  final void Function(String message) printFunction;

  /// Middleware function to be added to the store.
  void call(PureStore<T> store, PureAction<T> action, NextDispatcher<T> next) {
    final prefix = name != null ? '[$name] ' : '';

    if (logActions) {
      printFunction('${prefix}Action Dispatched: ${action.runtimeType}');
    }

    final oldState = logState ? store.state : null;

    try {
      next(action);

      if (logState && oldState != null) {
        final newState = store.state;
        // Note: For async actions, state might not change immediately.
        // This logs the immediate state after dispatch.
        if (oldState != newState) {
          printFunction('${prefix}State Changed: ${oldState.runtimeType}');
          printFunction('$prefix  Old: $oldState');
          printFunction('$prefix  New: $newState');
        } else {
          printFunction('${prefix}State Unchanged');
        }
      }
    } catch (e) {
      if (logErrors) {
        printFunction('${prefix}Action Error: $e');
      }
      rethrow;
    }
  }
}

/// A mixin that adds Undo/Redo capabilities to a [PureStore].
///
/// This is not a standard middleware but a wrapper around state management.
/// However, we can implement it as a class that manages history.
class PureUndoRedo<T> {
  /// Creates an undo/redo manager.
  ///
  /// - [maxHistory]: Maximum number of states to keep in history (default: 10)
  PureUndoRedo({this.maxHistory = 10});

  /// Maximum history size.
  final int maxHistory;

  final Queue<T> _past = Queue<T>();
  final Queue<T> _future = Queue<T>();
  T? _currentState;

  /// Records the current state into history.
  /// Call this BEFORE dispatching an action that you want to be undoable.
  void record(T state) {
    if (_currentState != null && state != _currentState) {
      // State has changed since last record, unlikely but possible if not coordinated
    }

    _past.addLast(state);
    if (_past.length > maxHistory) {
      _past.removeFirst();
    }
    _future.clear();
    _currentState = state; // Track what we recorded
  }

  /// Checks if undo is possible.
  bool get canUndo => _past.length > 1;

  /// Checks if redo is possible.
  bool get canRedo => _future.isNotEmpty;

  /// Performs undo and returns the previous state.
  /// Returns null if undo is not possible.
  T? undo(T currentState) {
    if (!canUndo) return null;

    final current = _past.removeLast();
    _future.addLast(current);

    final previous = _past.last;
    _currentState = previous;
    return previous;
  }

  /// Performs redo and returns the next state.
  /// Returns null if redo is not possible.
  T? redo(T currentState) {
    if (!canRedo) return null;

    final nextState = _future.removeLast();
    _past.addLast(nextState);
    _currentState = nextState;
    return nextState;
  }

  /// Clears history.
  void clear() {
    _past.clear();
    _future.clear();
    _currentState = null;
  }
}

/// Middleware to prevent rapid firing of actions.
class PureThrottle<T> {
  /// Creates a throttle middleware.
  PureThrottle(this.duration);

  /// - [duration]: Minimum time between executions of the same action type
  final Duration duration;
  final Map<Type, DateTime> _lastExecutionTime = {};

  /// Middleware function that throttles actions based on their type.
  void call(PureStore<T> store, PureAction<T> action, NextDispatcher<T> next) {
    final now = DateTime.now();
    final actionType = action.runtimeType;
    final lastTime = _lastExecutionTime[actionType];

    if (lastTime != null && now.difference(lastTime) < duration) {
      // Throttled - ignore action
      debugPrint('Throttled action: $actionType');
      return;
    }

    _lastExecutionTime[actionType] = now;
    next(action);
  }
}

/// Middleware to debounce actions.
class PureDebounce<T> {
  /// Creates a debounce middleware.
  PureDebounce(this.duration);

  /// - [duration]: Delay before executing the action after the last dispatch
  final Duration duration;
  final Map<Type, Timer> _timers = {};

  /// Middleware function that debounces actions based on their type.
  void call(PureStore<T> store, PureAction<T> action, NextDispatcher<T> next) {
    final actionType = action.runtimeType;

    if (_timers.containsKey(actionType)) {
      _timers[actionType]?.cancel();
    }

    _timers[actionType] = Timer(duration, () {
      _timers.remove(actionType);
      next(action);
    });
  }

  /// Dispose timers (should be called when store is disposed if possible, or managed manually)
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
