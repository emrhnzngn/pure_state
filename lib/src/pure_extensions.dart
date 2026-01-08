import 'package:flutter/material.dart';
import 'package:pure_state/src/pure_provider.dart';
import 'package:pure_state/src/pure_selector.dart';
import 'package:pure_state/src/pure_store.dart';

/// Extension methods on [BuildContext] for accessing stores.
///
/// Provides convenient shortcuts for accessing stores and reading state.
extension PureContextExtension on BuildContext {
  /// Gets a store of type [S] from the nearest [PureProvider] ancestor.
  ///
  /// Throws [FlutterError] if no provider is found.
  ///
  /// Example:
  /// ```dart
  /// final store = context.store<CounterState>();
  /// ```
  PureStore<S> store<S>() {
    return PureProvider.of<S>(this);
  }

  /// Reads the state from a store of type [S].
  ///
  /// Shortcut for `context.store<S>().state`.
  ///
  /// Example:
  /// ```dart
  /// final count = context.read<CounterState>().count;
  /// ```
  S read<S>() {
    return PureProvider.of<S>(this).state;
  }
}

/// Extension methods on [BuildContext] for creating selector widgets.
///
/// Provides a convenient way to create [PureSelector] widgets.
extension PureSelectExtension on BuildContext {
  /// Creates a [PureSelector] widget with convenient syntax.
  ///
  /// - [selector]: Function that extracts the selected value from state
  /// - [builder]: Builder function that receives the selected value
  /// - [store]: Optional explicit store (if null, uses [PureProvider.of])
  /// - [debounce]: Optional debounce duration for updates
  /// - [selectorId]: Optional ID to identify selector changes
  ///
  /// Example:
  /// ```dart
  /// context.selector<CounterState, int>(
  ///   selector: (state) => state.count,
  ///   builder: (context, count) => Text('Count: $count'),
  /// )
  /// ```
  Widget selector<T, R>({
    required R Function(T state) selector,
    required Widget Function(BuildContext context, R selectedState) builder,
    PureStore<T>? store,
    Duration? debounce,
    Object? selectorId,
  }) {
    return PureSelector<T, R>(
      store: store ?? this.store<T>(),
      selector: selector,
      builder: builder,
      debounce: debounce,
      selectorId: selectorId,
    );
  }
}
