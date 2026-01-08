import 'package:pure_state/src/pure_store.dart';

/// Container for managing multiple stores of different types.
///
/// Allows registering and accessing stores by their type.
/// Useful for multi-store applications where stores need to reference each other.
///
/// Example:
/// ```dart
/// final container = StoreContainer();
/// container.register<CounterState>(counterStore);
/// container.register<UserState>(userStore);
/// final counterStore = container.get<CounterState>();
/// ```
class StoreContainer {
  /// Internal map storing stores by their type.
  final Map<Type, dynamic> _stores = {};

  /// Registers a store of type [T].
  ///
  /// If a store of the same type already exists, it will be replaced.
  void register<T>(PureStore<T> store) {
    _stores[T] = store;
  }

  /// Gets a store of type [T].
  ///
  /// Throws [StateError] if no store of type [T] is registered.
  PureStore<T> get<T>() {
    final store = _stores[T];
    if (store == null) {
      throw StateError(
        'Store of type $T not found in StoreContainer.\n'
        'You must register it first using register<T>().\n'
        '\n'
        'Example:\n'
        '  final container = StoreContainer();\n'
        '  container.register<$T>(myStore);\n'
        '  final store = container.get<$T>();\n'
        '\n'
        'Available registered types: ${_stores.keys.join(", ")}',
      );
    }
    return store as PureStore<T>;
  }

  /// Tries to get a store of type [T].
  ///
  /// Returns null if no store of type [T] is registered.
  PureStore<T>? tryGet<T>() {
    return _stores[T] as PureStore<T>?;
  }

  /// Checks if a store of type [T] is registered.
  bool contains<T>() {
    return _stores.containsKey(T);
  }

  /// Clears all registered stores.
  void clear() {
    _stores.clear();
  }

  /// Removes a store of type [T].
  ///
  /// Returns true if the store was found and removed.
  bool remove<T>() {
    return _stores.remove(T) != null;
  }
}
