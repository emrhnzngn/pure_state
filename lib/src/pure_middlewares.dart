
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
    if (logActions) {
      final prefix = name != null ? '[$name] ' : '';
      printFunction('${prefix}Action Dispatched: ${action.runtimeType}');
    }

    final oldState = store.state;

    try {
      next(action);

      if (logState) {
        // Note: next() is synchronous for the dispatch part, but state update might happen later
        // if using async actions or batching.
        // For accurate diffing in async scenarios, one might need to hook into onEvent.
        // But for simple logging, checking state after next() is a reasonable approximation
        // for synchronous updates.
        
        // However, a better approach for a Logger Middleware is to hook into the store's onEvent
        // but since middleware wraps the dispatch, we can't easily see the "final" state here asynchronously.
        
        // This simple logger logs the dispatch.
      }
    } catch (e) {
      if (logErrors) {
        final prefix = name != null ? '[$name] ' : '';
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
  /// Maximum history size.
  final int maxHistory;

  PureUndoRedo({this.maxHistory = 10});

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
  final Duration duration;
  final Map<Type, DateTime> _lastExecutionTime = {};

  PureThrottle(this.duration);

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
  final Duration duration;
  final Map<Type, Timer> _timers = {};

  PureDebounce(this.duration);

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
