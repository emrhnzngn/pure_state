import 'dart:async';

import 'package:pure_state/src/pure_action.dart';
import 'package:pure_state/src/pure_store.dart';

/// Utility class for testing pure state management.
///
/// Provides helper methods for waiting for state changes, conditions, and actions.
class PureTestUtils {
  /// Waits for the store to reach the expected state.
  ///
  /// Returns a future that completes when the state matches [expectedState],
  /// or throws a [TimeoutException] if the timeout is reached.
  ///
  /// - [store]: The store to watch
  /// - [expectedState]: The expected state value
  /// - [timeout]: Maximum time to wait (default: 5 seconds)
  /// - [matcher]: Optional custom equality matcher function
  static Future<void> waitForState<T>(
    PureStore<T> store,
    T expectedState, {
    Duration timeout = const Duration(seconds: 5),
    bool Function(T, T)? matcher,
  }) async {
    final completer = Completer<void>();
    StreamSubscription<T>? subscription;
    Timer? timeoutTimer;

    final effectiveMatcher = matcher ?? (a, b) => a == b;

    timeoutTimer = Timer(timeout, () {
      unawaited(subscription?.cancel());
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException(
            'waitForState timeout: Expected state not reached within $timeout seconds.\n'
            'Current state: ${store.state}\n'
            'Expected state: $expectedState',
            timeout,
          ),
        );
      }
    });

    if (effectiveMatcher(store.state, expectedState)) {
      timeoutTimer.cancel();
      completer.complete();
      return completer.future;
    }

    subscription = store.stream.listen((state) {
      if (effectiveMatcher(state, expectedState)) {
        timeoutTimer?.cancel();

        unawaited(subscription?.cancel());
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  /// Waits for a condition to be satisfied on the store state.
  ///
  /// Returns a future that completes when [condition] returns true,
  /// or throws a [TimeoutException] if the timeout is reached.
  ///
  /// - [store]: The store to watch
  /// - [condition]: Function that returns true when condition is met
  /// - [timeout]: Maximum time to wait (default: 5 seconds)
  static Future<void> waitForCondition<T>(
    PureStore<T> store,
    bool Function(T state) condition, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<void>();
    StreamSubscription<T>? subscription;
    Timer? timeoutTimer;

    timeoutTimer = Timer(timeout, () {
      unawaited(subscription?.cancel());
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException(
            'waitForCondition timeout: Condition not satisfied within $timeout seconds.\n'
            'Current state: ${store.state}',
            timeout,
          ),
        );
      }
    });

    if (condition(store.state)) {
      timeoutTimer.cancel();
      completer.complete();
      return completer.future;
    }

    subscription = store.stream.listen((state) {
      if (condition(state)) {
        timeoutTimer?.cancel();

        unawaited(subscription?.cancel());
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  /// Captures all state changes within a specified duration.
  ///
  /// Returns a list of all states that were emitted during [duration].
  ///
  /// - [store]: The store to capture states from
  /// - [duration]: Duration to capture states (default: 1 second)
  static Future<List<T>> captureStates<T>(
    PureStore<T> store, {
    Duration duration = const Duration(seconds: 1),
  }) async {
    final states = <T>[];
    StreamSubscription<T>? subscription;

    final completer = Completer<void>();

    subscription = store.stream.listen(states.add);

    Timer(duration, () {
      unawaited(subscription?.cancel());
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    await completer.future;
    return states;
  }

  /// Executes an action and waits for the state to change.
  ///
  /// If [expectedState] is provided, waits for that specific state.
  /// Otherwise, waits for any state change from the initial state.
  ///
  /// Returns the final state after the action completes.
  ///
  /// - [store]: The store to execute action on
  /// - [action]: The action to execute
  /// - [expectedState]: Optional expected state to wait for
  /// - [timeout]: Maximum time to wait (default: 5 seconds)
  /// - [matcher]: Optional custom equality matcher function
  static Future<T> waitForAction<T>(
    PureStore<T> store,
    PureAction<T> action, {
    T? expectedState,
    Duration timeout = const Duration(seconds: 5),
    bool Function(T, T)? matcher,
  }) async {
    final oldState = store.state;
    store.execute(action);

    if (expectedState != null) {
      await waitForState(
        store,
        expectedState,
        timeout: timeout,
        matcher: matcher,
      );
    } else {
      await waitForCondition(
        store,
        (state) => state != oldState,
        timeout: timeout,
      );
    }

    return store.state;
  }
}
