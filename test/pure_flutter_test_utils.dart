import 'package:flutter/material.dart';
// This file is intended for use in test projects only.
// flutter_test is available in dev_dependencies for this package,
// and will be available in test projects that use this package.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/src/pure_action.dart';
import 'package:pure_state/src/pure_provider.dart';
import 'package:pure_state/src/pure_store.dart';

/// Extension methods for testing Pure State with Flutter widgets.
extension PureFlutterTestExtension on WidgetTester {
  /// Pumps a widget with a Pure State store.
  ///
  /// This is a convenience method for testing widgets that depend on a store.
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpPureState<CounterState>(
  ///   store: counterStore,
  ///   child: CounterWidget(),
  /// );
  /// ```
  Future<void> pumpPureState<T>({
    required PureStore<T> store,
    required Widget child,
    Duration? duration,
  }) async {
    await pumpWidget(
      MaterialApp(
        home: PureProvider<T>(
          store: store,
          child: child,
        ),
      ),
    );

    if (duration != null) {
      await pump(duration);
    }
  }

  /// Pumps multiple stores for testing multi-store widgets.
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpMultiplePureStores(
  ///   providers: [
  ///     (child) => PureProvider(store: userStore, child: child),
  ///     (child) => PureProvider(store: settingsStore, child: child),
  ///   ],
  ///   child: MyComplexWidget(),
  /// );
  /// ```
  Future<void> pumpMultiplePureStores({
    required List<Widget Function(Widget child)> providers,
    required Widget child,
    Duration? duration,
  }) async {
    var wrappedChild = child;

    // Wrap child with providers in reverse order
    for (var i = providers.length - 1; i >= 0; i--) {
      wrappedChild = providers[i](wrappedChild);
    }

    await pumpWidget(
      MaterialApp(
        home: wrappedChild,
      ),
    );

    if (duration != null) {
      await pump(duration);
    }
  }

  /// Waits for a condition to be true with pumping.
  ///
  /// Useful for waiting for async state changes to propagate to widgets.
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpUntil(
  ///   () => find.text('Loaded').evaluate().isNotEmpty,
  ///   timeout: Duration(seconds: 5),
  /// );
  /// ```
  Future<void> pumpUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        throw Exception(
          'pumpUntil timed out waiting for condition after $timeout',
        );
      }

      await pump(interval);
    }
  }

  /// Dispatches an action and waits for the widget tree to update.
  ///
  /// Example:
  /// ```dart
  /// await tester.dispatchAndPump(
  ///   store: counterStore,
  ///   action: IncrementAction(),
  /// );
  /// ```
  Future<void> dispatchAndPump<T>({
    required PureStore<T> store,
    required PureAction<T> action,
    Duration? duration,
  }) async {
    store.dispatch(action);
    await pump(duration ?? const Duration(milliseconds: 100));
  }
}

/// Utilities for golden testing with Pure State.
class PureGoldenTest {
  /// Performs a golden test on a widget with a store.
  ///
  /// Example:
  /// ```dart
  /// testWidgets('counter widget golden test', (tester) async {
  ///   await PureGoldenTest.testWithStore<CounterState>(
  ///     tester: tester,
  ///     store: PureStore(CounterState(count: 42)),
  ///     widget: CounterWidget(),
  ///     goldenFile: 'counter_widget_42.png',
  ///   );
  /// });
  /// ```
  static Future<void> testWithStore<T>({
    required WidgetTester tester,
    required PureStore<T> store,
    required Widget widget,
    required String goldenFile,
    Size? surfaceSize,
    bool skip = false,
  }) async {
    await tester.pumpPureState(
      store: store,
      child: widget,
    );

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile(goldenFile),
      skip: skip,
    );

    store.dispose();
  }

  /// Performs golden tests for multiple states.
  ///
  /// Useful for testing different state variations.
  ///
  /// Example:
  /// ```dart
  /// await PureGoldenTest.testMultipleStates<CounterState>(
  ///   tester: tester,
  ///   states: [
  ///     CounterState(count: 0),
  ///     CounterState(count: 42),
  ///     CounterState(count: 100),
  ///   ],
  ///   widget: (state) => CounterWidget(),
  ///   goldenFile: (index, state) => 'counter_$index.png',
  /// );
  /// ```
  static Future<void> testMultipleStates<T>({
    required WidgetTester tester,
    required List<T> states,
    required Widget Function(T state) widget,
    required String Function(int index, T state) goldenFile,
    bool skip = false,
  }) async {
    for (var i = 0; i < states.length; i++) {
      final state = states[i];
      final store = PureStore<T>(state);

      await testWithStore(
        tester: tester,
        store: store,
        widget: widget(state),
        goldenFile: goldenFile(i, state),
        skip: skip,
      );
    }
  }

  /// Performs a golden test after dispatching actions.
  ///
  /// Example:
  /// ```dart
  /// await PureGoldenTest.testWithActions<CounterState>(
  ///   tester: tester,
  ///   initialState: CounterState(count: 0),
  ///   actions: [IncrementAction(), IncrementAction()],
  ///   widget: CounterWidget(),
  ///   goldenFile: 'counter_after_increments.png',
  /// );
  /// ```
  static Future<void> testWithActions<T>({
    required WidgetTester tester,
    required T initialState,
    required List<PureAction<T>> actions,
    required Widget widget,
    required String goldenFile,
    Duration? delayBetweenActions,
    bool skip = false,
  }) async {
    final store = PureStore<T>(initialState);

    await tester.pumpPureState(
      store: store,
      child: widget,
    );

    for (final action in actions) {
      store.dispatch(action);

      if (delayBetweenActions != null) {
        await tester.pump(delayBetweenActions);
      }
    }

    // Final pump to ensure all updates are processed
    await tester.pumpAndSettle();

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile(goldenFile),
      skip: skip,
    );

    store.dispose();
  }
}

/// Utilities for widget integration testing with Pure State.
class PureWidgetTest {
  /// Sets up a widget test scenario with stores.
  ///
  /// Example:
  /// ```dart
  /// final scenario = await PureWidgetTest.setup<CounterState>(
  ///   tester: tester,
  ///   store: counterStore,
  ///   widget: CounterApp(),
  /// );
  ///
  /// // Perform tests
  /// await scenario.dispatch(IncrementAction());
  /// expect(find.text('1'), findsOneWidget);
  ///
  /// // Clean up
  /// await scenario.teardown();
  /// ```
  static Future<WidgetTestScenario<T>> setup<T>({
    required WidgetTester tester,
    required PureStore<T> store,
    required Widget widget,
  }) async {
    await tester.pumpPureState(
      store: store,
      child: widget,
    );

    return WidgetTestScenario<T>(
      tester: tester,
      store: store,
      widget: widget,
    );
  }

  /// Sets up a multi-store widget test scenario.
  static Future<MultiStoreWidgetTestScenario> setupMultiStore({
    required WidgetTester tester,
    required Map<Type, PureStore<dynamic>> stores,
    required Widget widget,
  }) async {
    final providers = stores.entries
        .map(
          (entry) =>
              // Type annotation is required here because Dart cannot infer
              // the type of 'child' parameter in the nested closure.
              // ignore: avoid_types_on_closure_parameters
              (Widget child) => PureProvider(store: entry.value, child: child),
        )
        .toList();

    await tester.pumpMultiplePureStores(
      providers: providers,
      child: widget,
    );

    return MultiStoreWidgetTestScenario(
      tester: tester,
      stores: stores,
      widget: widget,
    );
  }
}

/// A test scenario helper for widget tests.
class WidgetTestScenario<T> {
  /// Creates a widget test scenario.
  WidgetTestScenario({
    required this.tester,
    required this.store,
    required this.widget,
  });

  /// The widget tester.
  final WidgetTester tester;

  /// The store being tested.
  final PureStore<T> store;

  /// The widget under test.
  final Widget widget;

  /// Dispatches an action and waits for updates.
  Future<void> dispatch(
    PureAction<T> action, {
    Duration? pumpDuration,
  }) async {
    await tester.dispatchAndPump(
      store: store,
      action: action,
      duration: pumpDuration,
    );
  }

  /// Waits for a finder condition to be met.
  Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpUntil(
      () => finder.evaluate().isNotEmpty,
      timeout: timeout,
    );
  }

  /// Pumps the widget tree.
  Future<void> pump([Duration? duration]) async {
    await tester.pump(duration);
  }

  /// Pumps until no more frames are scheduled.
  Future<void> pumpAndSettle() async {
    await tester.pumpAndSettle();
  }

  /// Cleans up the scenario.
  Future<void> teardown() async {
    store.dispose();
  }
}

/// A test scenario helper for multi-store widget tests.
class MultiStoreWidgetTestScenario {
  /// Creates a multi-store widget test scenario.
  MultiStoreWidgetTestScenario({
    required this.tester,
    required this.stores,
    required this.widget,
  });

  /// The widget tester.
  final WidgetTester tester;

  /// Map of stores by type.
  final Map<Type, PureStore<dynamic>> stores;

  /// The widget under test.
  final Widget widget;

  /// Gets a store by type.
  PureStore<T> getStore<T>() {
    final store = stores[T];
    if (store == null) {
      throw StateError('Store of type $T not found');
    }
    return store as PureStore<T>;
  }

  /// Dispatches an action to a specific store.
  Future<void> dispatch<T>(
    PureAction<T> action, {
    Duration? pumpDuration,
  }) async {
    final store = getStore<T>();
    await tester.dispatchAndPump(
      store: store,
      action: action,
      duration: pumpDuration,
    );
  }

  /// Cleans up all stores.
  Future<void> teardown() async {
    for (final store in stores.values) {
      store.dispose();
    }
  }
}
