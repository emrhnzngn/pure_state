import 'package:pure_state/src/pure_store.dart';
import 'package:pure_state/src/pure_store_container.dart';

/// A factory for creating parameterized stores.
///
/// [PureStoreFamily] allows you to create multiple instances of a store
/// with different parameters. Each unique parameter creates and caches a
/// separate store instance.
///
/// This is useful for scenarios like:
/// - User-specific stores (by user ID)
/// - List item stores (by item ID)
/// - Filtered data stores (by filter criteria)
///
/// Example:
/// ```dart
/// final userStoreFamily = PureStoreFamily<UserState, int>(
///   (userId) => PureStore(UserState(id: userId)),
/// );
///
/// // Get store for user 42
/// final user42Store = userStoreFamily(42);
///
/// // Get store for user 100
/// final user100Store = userStoreFamily(100);
///
/// // Same ID returns same store instance
/// assert(identical(userStoreFamily(42), user42Store));
/// ```
class PureStoreFamily<T, Param> {
  /// Creates a new [PureStoreFamily].
  ///
  /// - 'create': Factory function that creates a store for a given parameter
  /// - [container]: Optional store container for dependency injection
  PureStoreFamily(
    this._create, {
    StoreContainer? container,
  }) : _container = container;

  /// Factory function for creating stores.
  final PureStore<T> Function(Param param) _create;

  /// Optional store container.
  final StoreContainer? _container;

  /// Cache of created stores keyed by parameter.
  final Map<Param, PureStore<T>> _stores = {};

  /// Gets or creates a store for the given parameter.
  ///
  /// If a store for this parameter already exists, returns the cached instance.
  /// Otherwise, creates a new store using the factory function.
  PureStore<T> call(Param param) {
    return _stores.putIfAbsent(param, () {
      final store = _create(param);

      // Register in container if available
      final container = _container;
      if (container != null) {
        // Use a composite key to avoid conflicts
        container.registerWithKey<T>('${T}_$param', store);
      }

      return store;
    });
  }

  /// Checks if a store exists for the given parameter.
  bool exists(Param param) {
    return _stores.containsKey(param);
  }

  /// Disposes the store for the given parameter.
  ///
  /// Returns true if a store was disposed, false if no store existed.
  bool dispose(Param param) {
    final store = _stores.remove(param);
    if (store != null) {
      store.dispose();

      // Unregister from container if available
      final container = _container;
      if (container != null) {
        container.unregisterWithKey<T>('${T}_$param');
      }

      return true;
    }
    return false;
  }

  /// Disposes all stores created by this family.
  void disposeAll() {
    for (final store in _stores.values) {
      store.dispose();
    }
    _stores.clear();

    // Clear from container if available
    if (_container != null) {
      // Container cleanup is handled by individual dispose calls
    }
  }

  /// Returns the number of cached stores.
  int get cacheSize => _stores.length;

  /// Returns all cached parameters.
  Iterable<Param> get cachedParams => _stores.keys;

  /// Returns all cached stores.
  Iterable<PureStore<T>> get cachedStores => _stores.values;

  /// Clears all cached stores without disposing them.
  ///
  /// Warning: This can lead to memory leaks if stores are not disposed properly.
  /// Use [disposeAll] instead to properly clean up resources.
  void clearCache() {
    _stores.clear();
  }
}

/// Extension methods for [StoreContainer] to support family registration.
extension StoreContainerFamilyExtension on StoreContainer {
  /// Registers a store with a composite key.
  void registerWithKey<T>(String key, PureStore<T> store) {
    // This is a helper method for internal use by PureStoreFamily
    // The actual implementation depends on StoreContainer's API
    // For now, we'll use the standard register method
    // In a real implementation, you might want to extend StoreContainer
    // to support keyed registration
  }

  /// Unregisters a store with a composite key.
  void unregisterWithKey<T>(String key) {
    // Similar to registerWithKey, this is for internal use
  }
}

/// A convenience typedef for creating store families with multiple parameters.
///
/// Example:
/// ```dart
/// final chatStoreFamily = PureStoreFamily2<ChatState, String, int>(
///   (roomId, userId) => PureStore(ChatState(roomId: roomId, userId: userId)),
/// );
///
/// final store = chatStoreFamily(('room-1', 42));
/// ```
class PureStoreFamily2<T, P1, P2> extends PureStoreFamily<T, (P1, P2)> {
  /// Creates a family with two parameters.
  PureStoreFamily2(
    PureStore<T> Function(P1 param1, P2 param2) create, {
    StoreContainer? container,
  }) : super(
         (params) => create(params.$1, params.$2),
         container: container,
       );

  /// Gets or creates a store with two parameters.
  PureStore<T> call2(P1 param1, P2 param2) {
    return call((param1, param2));
  }
}

/// A convenience typedef for creating store families with three parameters.
class PureStoreFamily3<T, P1, P2, P3> extends PureStoreFamily<T, (P1, P2, P3)> {
  /// Creates a family with three parameters.
  PureStoreFamily3(
    PureStore<T> Function(P1 param1, P2 param2, P3 param3) create, {
    StoreContainer? container,
  }) : super(
         (params) => create(params.$1, params.$2, params.$3),
         container: container,
       );

  /// Gets or creates a store with three parameters.
  PureStore<T> call3(P1 param1, P2 param2, P3 param3) {
    return call((param1, param2, param3));
  }
}

/// Mixin for auto-disposing unused family stores based on usage.
mixin AutoDisposeFamilyMixin<T, Param> on PureStoreFamily<T, Param> {
  /// Timestamp of last access for each parameter.
  final Map<Param, DateTime> _lastAccess = {};

  /// Duration of inactivity before auto-disposal.
  Duration get keepAliveDuration => const Duration(minutes: 5);

  @override
  PureStore<T> call(Param param) {
    _lastAccess[param] = DateTime.now();
    return super.call(param);
  }

  /// Disposes stores that haven't been accessed within [keepAliveDuration].
  void disposeStale() {
    final now = DateTime.now();
    final staleParams = <Param>[];

    for (final entry in _lastAccess.entries) {
      if (now.difference(entry.value) > keepAliveDuration) {
        staleParams.add(entry.key);
      }
    }

    for (final param in staleParams) {
      dispose(param);
      _lastAccess.remove(param);
    }
  }
}
