import 'dart:async';

import 'package:pure_state/pure_state.dart';

/// Type definition for a pure logic function that transforms state.
///
/// Takes the current state and returns a new state (synchronously or asynchronously).
typedef PureLogic<T> = FutureOr<T> Function(T state);

/// Type definition for a timeout handler function.
///
/// Called when an action execution times out.
/// Takes the current state and timeout duration, returns a fallback state.
typedef PureTimeoutHandler<T> =
    FutureOr<T> Function(T currentState, Duration timeout);

/// Abstract base class for all actions in the pure state management system.
///
/// Actions represent operations that can be dispatched to modify the state.
/// Each action can have:
/// - A priority level (higher priority actions are processed first)
/// - A timeout duration
/// - A timeout handler
/// - Custom execution logic
///
/// Example:
/// ```dart
/// class IncrementAction extends PureAction<CounterState> {
///   @override
///   FutureOr<CounterState> execute(CounterState currentState) {
///     return currentState.copyWith(count: currentState.count + 1);
///   }
/// }
/// ```
abstract class PureAction<T> {
  /// Creates a new action with an optional handler function.
  ///
  /// If a handler is provided, it will be used as the execution logic.
  /// Otherwise, you must override [execute] or register a handler using
  /// [PureStore.on].
  const PureAction([this._handler]);

  /// Optional handler function for action execution.
  final PureLogic<T>? _handler;

  /// Priority level of this action.
  ///
  /// Higher priority actions are processed first in the action queue.
  /// Default is 0.
  int get priority => 0;

  /// Optional timeout duration for this action.
  ///
  /// If set, the action execution will timeout after this duration.
  /// If null, uses the store's default [PureStore.actionTimeout].
  Duration? get timeout => null;

  /// Optional name for this action.
  ///
  /// Used for debugging and logging purposes.
  /// Defaults to the runtime type of the action.
  String get name => runtimeType.toString();

  @override
  String toString() => name;

  /// Optional timeout handler for this action.
  ///
  /// Called when the action execution times out.
  /// If null, a [TimeoutException] will be thrown.
  PureTimeoutHandler<T>? get onTimeout => null;

  /// Optional debounce duration for this action.
  ///
  /// If set, the action will only execute after this duration has passed
  /// without any new actions of the same type (or same [debounceKey]) being dispatched.
  Duration? get debounceDuration => null;

  /// Optional throttle duration for this action.
  ///
  /// If set, the action will execute at most once every [throttleDuration].
  Duration? get throttleDuration => null;

  /// Optional key for debounce/throttle grouping.
  ///
  /// If null, the runtime type of the action is used as the key.
  Object? get debounceKey => null;

  /// Executes the action logic on the current state.
  ///
  /// Returns the new state after applying the action.
  ///
  /// Throws [UnimplementedError] if no handler is provided and [execute] is not overridden.
  FutureOr<T> execute(T currentState) {
    if (_handler != null) {
      return _handler(currentState);
    }
    throw UnimplementedError(
      'Action logic is not defined. '
      'Either override execute() method, '
      'register a handler using store.on<$runtimeType>(), '
      'or provide a handler in the constructor.',
    );
  }

  /// Optional hook for side effects after the action has been successfully executed
  /// and the state has been updated.
  ///
  /// - [newState]: The state of the store after this action.
  /// - [dispatch]: A function to dispatch new actions to the store.
  void onResult(T newState, void Function(PureAction<T> action) dispatch) {}
}

/// A simple action that uses a provided updater function.
///
/// This is a convenience class for creating actions from simple state update functions.
///
/// Example:
/// ```dart
/// store.execute(SimpleUpdateAction((state) => state.copyWith(count: 5)));
/// ```
class SimpleUpdateAction<T> extends PureAction<T> {
  /// Creates a simple update action with the given updater function.
  const SimpleUpdateAction(this._updater) : super(_updater);

  /// The updater function that transforms the state.
  final PureLogic<T> _updater;

  @override
  FutureOr<T> execute(T currentState) {
    return _updater(currentState);
  }
}

/// An action with a custom name and logic.
///
/// Useful for reducing boilerplate when precise action classes are not needed,
/// but debugging information (name) is still required.
class NamedAction<T> extends PureAction<T> {
  /// Creates a renamed action.
  ///
  /// - [name]: The name to display in debug logs
  /// - [handler]: The logic to execute
  /// - [timeout]: Optional timeout
  NamedAction(
    this.name,
    PureLogic<T> handler, {
    this.timeout,
  }) : super(handler);

  @override
  final String name;

  @override
  final Duration? timeout;

  @override
  FutureOr<T> execute(T currentState) {
    // Use parent's execute method which uses the _handler passed to super()
    return super.execute(currentState);
  }
}
