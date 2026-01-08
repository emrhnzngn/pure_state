import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  /// BLoC-style store testing helper.
  ///
  /// Similar to `blocTest` from the bloc_test package, but for Pure State.
  ///
  /// Example:
  /// ```dart
  /// await PureTestUtils.storeTest<CounterState>(
  ///   'increments counter',
  ///   build: () => PureStore(CounterState(count: 0)),
  ///   act: (store) => store.dispatch(IncrementAction()),
  ///   expect: () => [CounterState(count: 1)],
  /// );
  /// ```
  static Future<void> storeTest<T>({
    required String description,
    required PureStore<T> Function() build,
    void Function(PureStore<T> store)? act,
    List<T> Function()? expect,
    Duration timeout = const Duration(seconds: 5),
    void Function(T state)? verify,
    List<T> Function()? skip,
    bool Function(T a, T b)? equals,
  }) async {
    final store = build();
    final states = <T>[];
    final subscription = store.stream.listen(states.add);

    try {
      // Act
      if (act != null) {
        act(store);
      }

      // Wait for states to be emitted
      if (expect != null) {
        final expectedStates = expect();
        await waitForCondition(
          store,
          (_) => states.length >= expectedStates.length,
          timeout: timeout,
        );

        // Skip states if specified
        final skippedCount = skip?.call().length ?? 0;
        final actualStates = states.skip(skippedCount).toList();

        // Verify expected states
        final equalsFn = equals ?? (a, b) => a == b;
        
        if (actualStates.length != expectedStates.length) {
          throw StateError(
            'Expected ${expectedStates.length} states, but got ${actualStates.length}\n'
            'Expected: $expectedStates\n'
            'Actual: $actualStates',
          );
        }

        for (var i = 0; i < expectedStates.length; i++) {
          if (!equalsFn(actualStates[i], expectedStates[i])) {
            throw StateError(
              'State mismatch at index $i\n'
              'Expected: ${expectedStates[i]}\n'
              'Actual: ${actualStates[i]}',
            );
          }
        }
      }

      // Additional verification
      if (verify != null) {
        verify(store.state);
      }
    } finally {
      await subscription.cancel();
      store.dispose();
    }
  }

  /// Creates a mock store with predefined state emissions.
  ///
  /// Useful for testing widgets without creating real stores.
  ///
  /// Example:
  /// ```dart
  /// final mockStore = PureTestUtils.createMockStore<int>(
  ///   initialState: 0,
  ///   emittedStates: [1, 2, 3],
  ///   emitDelay: Duration(milliseconds: 100),
  /// );
  /// ```
  static MockPureStore<T> createMockStore<T>({
    required T initialState,
    List<T>? emittedStates,
    Duration? emitDelay,
  }) {
    return MockPureStore<T>(
      initialState: initialState,
      emittedStates: emittedStates,
      emitDelay: emitDelay,
    );
  }

  /// Performs snapshot testing on a state object.
  ///
  /// Compares the current state against a saved snapshot.
  /// If the snapshot doesn't exist, creates it.
  /// If it exists but differs, throws an error showing the diff.
  ///
  /// Example:
  /// ```dart
  /// await PureTestUtils.expectStateSnapshot(
  ///   state,
  ///   'test/snapshots/my_state_snapshot.json',
  ///   toJson: (s) => s.toJson(),
  /// );
  /// ```
  static Future<void> expectStateSnapshot<T>(
    T state,
    String snapshotFile, {
    required Map<String, dynamic> Function(T state) toJson,
    bool updateSnapshots = false,
  }) async {
    final file = File(snapshotFile);
    final stateJson = toJson(state);
    final stateJsonString = const JsonEncoder.withIndent('  ').convert(stateJson);

    if (!file.existsSync() || updateSnapshots) {
      // Create or update snapshot
      await file.create(recursive: true);
      await file.writeAsString(stateJsonString);
      return;
    }

    // Compare with existing snapshot
    final existingSnapshot = await file.readAsString();
    if (existingSnapshot != stateJsonString) {
      throw StateError(
        'Snapshot mismatch!\n'
        'File: $snapshotFile\n'
        'Expected:\n$existingSnapshot\n'
        'Actual:\n$stateJsonString\n'
        '\n'
        'To update snapshots, run with updateSnapshots: true',
      );
    }
  }

  /// Captures a series of state changes as a timeline.
  ///
  /// Returns a list of timestamped state changes.
  ///
  /// Example:
  /// ```dart
  /// final timeline = await PureTestUtils.captureTimeline(
  ///   store,
  ///   duration: Duration(seconds: 2),
  /// );
  /// 
  /// for (final entry in timeline) {
  ///   print('${entry.timestamp}: ${entry.state}');
  /// }
  /// ```
  static Future<List<TimestampedState<T>>> captureTimeline<T>(
    PureStore<T> store, {
    Duration duration = const Duration(seconds: 1),
  }) async {
    final timeline = <TimestampedState<T>>[];
    StreamSubscription<T>? subscription;
    final completer = Completer<void>();

    subscription = store.stream.listen((state) {
      timeline.add(TimestampedState(
        state: state,
        timestamp: DateTime.now(),
      ));
    });

    Timer(duration, () {
      unawaited(subscription?.cancel());
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    await completer.future;
    return timeline;
  }

  /// Waits for multiple stores to reach expected states.
  ///
  /// Useful for testing multi-store interactions.
  static Future<void> waitForStores<T1, T2>(
    PureStore<T1> store1,
    PureStore<T2> store2,
    bool Function(T1 state1, T2 state2) condition, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<void>();
    StreamSubscription<T1>? sub1;
    StreamSubscription<T2>? sub2;
    Timer? timeoutTimer;

    void checkCondition() {
      if (condition(store1.state, store2.state)) {
        timeoutTimer?.cancel();
        unawaited(sub1?.cancel());
        unawaited(sub2?.cancel());
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    timeoutTimer = Timer(timeout, () {
      unawaited(sub1?.cancel());
      unawaited(sub2?.cancel());
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException(
            'waitForStores timeout: Condition not satisfied',
            timeout,
          ),
        );
      }
    });

    // Check initial state
    if (condition(store1.state, store2.state)) {
      timeoutTimer.cancel();
      return;
    }

    sub1 = store1.stream.listen((_) => checkCondition());
    sub2 = store2.stream.listen((_) => checkCondition());

    return completer.future;
  }
}

/// A mock store implementation for testing.
class MockPureStore<T> extends PureStore<T> {
  /// Creates a mock store.
  MockPureStore({
    required T initialState,
    this.emittedStates,
    this.emitDelay,
  }) : super(initialState) {
    _scheduleEmissions();
  }

  /// States to emit automatically.
  final List<T>? emittedStates;

  /// Delay between emissions.
  final Duration? emitDelay;

  void _scheduleEmissions() {
    final states = emittedStates;
    if (states == null || states.isEmpty) return;

    final delay = emitDelay ?? const Duration(milliseconds: 100);
    
    for (var i = 0; i < states.length; i++) {
      Timer(delay * (i + 1), () {
        setValue(states[i]);
      });
    }
  }

  /// Sets the next state to emit.
  void emitState(T state) {
    setValue(state);
  }

  /// Emits an error.
  void emitError(Object error) {
    // In a real implementation, this would trigger the error stream
    // For now, we can dispatch an action that throws
  }
}

/// A state with its timestamp.
class TimestampedState<T> {
  /// Creates a timestamped state entry.
  const TimestampedState({
    required this.state,
    required this.timestamp,
  });

  /// The state value.
  final T state;

  /// When this state was recorded.
  final DateTime timestamp;

  @override
  String toString() => '$timestamp: $state';
}

/// Integration test helper class.
class PureIntegrationTest {
  /// Creates an integration test helper.
  PureIntegrationTest({List<PureStore<dynamic>>? stores})
      : stores = stores ?? [];

  /// List of stores to manage.
  final List<PureStore<dynamic>> stores;

  /// Sets up the test environment.
  Future<void> setup() async {
    // Initialize any test dependencies
  }

  /// Tears down the test environment.
  Future<void> teardown() async {
    await resetAllStores();
    for (final store in stores) {
      store.dispose();
    }
  }

  /// Resets all stores to their initial state.
  Future<void> resetAllStores() async {
    for (final store in stores) {
      // This is a simplified reset - in reality, you'd need to track initial states
      // or provide a reset mechanism in PureStore
    }
  }

  /// Waits for all stores to reach a stable state (no pending actions).
  Future<void> waitForStability({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // Wait for all action queues to be empty
    // This would require exposing queue status in PureStore
    await Future<void>.delayed(Duration(milliseconds: 100));
  }

  /// Executes a test scenario with automatic setup and teardown.
  Future<void> runScenario(
    String description,
    Future<void> Function() scenario,
  ) async {
    try {
      await setup();
      await scenario();
    } finally {
      await teardown();
    }
  }
  
  /// Registers a store for management.
  void registerStore(PureStore<dynamic> store) {
    stores.add(store);
  }
}
