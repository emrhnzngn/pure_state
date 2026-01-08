import 'package:flutter/foundation.dart';
import 'package:pure_state/pure_state.dart';

/// A lightweight state holder that extends [ValueNotifier].
///
/// [PureValue] is designed for simple state management needs where the full
/// power of [PureStore] (Action Queue, Middlewares, etc.) is not required.
///
/// It can be used just like a [ValueNotifier], but provides a consistent API
/// within the Pure State ecosystem and can be used with [PureProvider] if adapted.
///
/// Example:
/// ```dart
/// final counter = PureValue<int>(0);
///
/// // Update value
/// counter.value++;
///
/// // Listen to changes
/// ValueListenableBuilder<int>(
///   valueListenable: counter,
///   builder: (context, value, _) => Text('$value'),
/// )
/// ```
class PureValue<T> extends ValueNotifier<T> {
  /// Creates a [PureValue] with an initial value.
  PureValue(super._value);

  /// Updates the value using a transformation function.
  ///
  /// This is a convenience method for `value = update(value)`.
  ///
  /// Example:
  /// ```dart
  /// counter.update((val) => val + 1);
  /// ```
  void update(T Function(T value) updater) {
    value = updater(value);
  }
}
