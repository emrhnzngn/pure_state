import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pure_state/src/pure_action.dart';
import 'package:pure_state/src/pure_store.dart';

/// Abstract interface for storage operations.
///
/// Implement this interface to provide custom storage backends
/// (e.g., SharedPreferences, Hive, SQLite, etc.).
abstract class PureStorage {
  /// Saves a value with the given key.
  Future<void> save(String key, String value);

  /// Loads a value by key.
  ///
  /// Returns null if the key doesn't exist.
  Future<String?> load(String key);

  /// Deletes a value by key.
  Future<void> delete(String key);

  /// Clears all stored values.
  Future<void> clear();
}

/// In-memory storage implementation.
///
/// Useful for testing or temporary storage.
/// Data is lost when the application closes.
class PureMemoryStorage implements PureStorage {
  /// Creates a new in-memory storage instance.
  PureMemoryStorage();

  /// Internal storage map.
  final Map<String, String> _storage = {};

  @override
  Future<void> save(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> load(String key) async {
    return _storage[key];
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}

/// Global instance of in-memory storage.
final pureMemoryStorage = PureMemoryStorage();

/// Creates a middleware that persists state to storage.
///
/// Automatically saves state changes to the provided storage backend.
///
/// - [storage]: Storage backend to use
/// - [key]: Key to store the state under
/// - [fromJson]: Function to deserialize state from JSON
/// - [toJson]: Function to serialize state to JSON
/// - [saveOnEveryChange]: Whether to save on every state change (default: true)
/// - [debounceDuration]: Optional debounce duration for saving
PureMiddlewareWithResult<T> purePersistenceMiddleware<T>({
  required PureStorage storage,
  required String key,
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
  bool saveOnEveryChange = true,
  Duration? debounceDuration,
}) {
  Timer? debounceTimer;

  Future<void> saveState(T state) async {
    Future<void> saveAction() async {
      try {
        final json = toJson(state);
        final jsonString = jsonEncode(json);
        await storage.save(key, jsonString);
      } on Exception catch (e) {
        debugPrint('Persistence save error: $e');
      }
    }

    if (debounceDuration != null) {
      debounceTimer?.cancel();
      debounceTimer = Timer(debounceDuration, saveAction);
    } else {
      await saveAction();
    }
  }

  return (PureStore<T> store, PureAction<T> action, next) async {
    final newState = await next(action);

    if (saveOnEveryChange) {
      await saveState(newState);
    }

    return newState;
  };
}

/// Extension methods for adding persistence to stores.
extension PureStorePersistence<T> on PureStore<T> {
  /// Enables automatic persistence for this store.
  ///
  /// State changes will be automatically saved to the provided storage.
  ///
  /// - [storage]: Storage backend to use
  /// - [key]: Key to store the state under
  /// - [fromJson]: Function to deserialize state from JSON
  /// - [toJson]: Function to serialize state to JSON
  /// - [saveOnEveryChange]: Whether to save on every state change (default: true)
  /// - [debounceDuration]: Optional debounce duration for saving
  void enablePersistence({
    required PureStorage storage,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    bool saveOnEveryChange = true,
    Duration? debounceDuration,
  }) {
    addMiddlewareWithResult(
      purePersistenceMiddleware<T>(
        storage: storage,
        key: key,
        fromJson: fromJson,
        toJson: toJson,
        saveOnEveryChange: saveOnEveryChange,
        debounceDuration: debounceDuration,
      ),
    );
  }

  /// Restores state from storage.
  ///
  /// Loads the saved state and updates the store with it.
  ///
  /// - [storage]: Storage backend to load from
  /// - [key]: Key to load the state from
  /// - [fromJson]: Function to deserialize state from JSON
  Future<void> restoreFromStorage({
    required PureStorage storage,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final savedJson = await storage.load(key);
      if (savedJson != null) {
        final json = jsonDecode(savedJson) as Map<String, dynamic>;
        final restoredState = fromJson(json);

        update((_) => restoredState);
      }
    } on Exception catch (e) {
      debugPrint('Persistence restore error: $e');
    }
  }
}
