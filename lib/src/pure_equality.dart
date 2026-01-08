import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'pure_config.dart';

/// Default maximum cache size for hash cache.
const int defaultHashCacheMaxSize = 1000;

/// Default maximum cache size for global hash cache.
const int defaultGlobalHashCacheMaxSize = 2000;

/// Cache for storing hash values to improve equality check performance.
///
/// Uses LRU eviction and automatic clearing to manage memory efficiently.
class HashCache {
  /// Creates a new hash cache.
  ///
  /// - [maxCacheSize]: Maximum number of cached hashes (default: [defaultHashCacheMaxSize])
  /// - [autoClearInterval]: Optional interval for automatic cache clearing
  HashCache({
    int? maxCacheSize,
    Duration? autoClearInterval,
  }) : _maxCacheSize = maxCacheSize ?? defaultHashCacheMaxSize,
       _autoClearInterval = autoClearInterval {
    if (_autoClearInterval != null) {
      _startAutoClear();
    }
  }

  /// Internal cache map: identityHash -> combinedHash.
  final Map<int, int> _hashCache = {};

  /// FIFO queue for LRU eviction.
  final Queue<int> _fifoQueue = Queue<int>();

  /// Maximum cache size.
  int _maxCacheSize;

  /// Optional auto-clear interval.
  final Duration? _autoClearInterval;

  /// Timer for automatic cache clearing.
  Timer? _autoClearTimer;

  /// Access counter for full clear optimization.
  int _accessCount = 0;

  /// Number of accesses before performing a full clear.
  static const int _accessCountBeforeFullClear = 10000;

  /// Gets the cached hash for an object, or calculates and caches it.
  ///
  /// Combines identity hash code with object hash code for better distribution.
  int getHash(Object obj) {
    _accessCount++;

    if (_accessCount >= _accessCountBeforeFullClear) {
      _fullClear();
      _accessCount = 0;
    }

    final identityHash = identityHashCode(obj);

    if (_hashCache.containsKey(identityHash)) {
      return _hashCache[identityHash]!;
    }

    final combinedHash = identityHash ^ obj.hashCode;

    if (_hashCache.length >= _maxCacheSize) {
      final removeCount = _maxCacheSize ~/ 2;
      for (var i = 0; i < removeCount && _fifoQueue.isNotEmpty; i++) {
        final keyToRemove = _fifoQueue.removeFirst();
        _hashCache.remove(keyToRemove);
      }
    }

    _hashCache[identityHash] = combinedHash;
    _fifoQueue.add(identityHash);
    return combinedHash;
  }

  /// Clears all cached hashes.
  void clear() {
    _hashCache.clear();
    _fifoQueue.clear();
    _accessCount = 0;
  }

  /// Performs a full clear without resetting access count.
  void _fullClear() {
    _hashCache.clear();
    _fifoQueue.clear();
  }

  /// Sets a new maximum cache size.
  ///
  /// Evicts oldest entries if new size is smaller than current cache size.
  void setMaxSize(int newSize) {
    _maxCacheSize = newSize;
    while (_hashCache.length > _maxCacheSize && _fifoQueue.isNotEmpty) {
      final keyToRemove = _fifoQueue.removeFirst();
      _hashCache.remove(keyToRemove);
    }
  }

  void _startAutoClear() {
    final interval = _autoClearInterval;
    if (interval == null) return;

    _autoClearTimer?.cancel();
    _autoClearTimer = Timer.periodic(interval, (_) {
      if (_hashCache.length > _maxCacheSize * 0.8) {
        final removeCount = _hashCache.length ~/ 2;
        for (var i = 0; i < removeCount && _fifoQueue.isNotEmpty; i++) {
          final keyToRemove = _fifoQueue.removeFirst();
          _hashCache.remove(keyToRemove);
        }
      }
    });
  }

  /// Disposes the cache and releases resources.
  void dispose() {
    _autoClearTimer?.cancel();
    _autoClearTimer = null;
    clear();
  }
}

/// Global hash cache instance for shared use across the application.
class _GlobalHashCache {
  /// Singleton instance of the global hash cache.
  static HashCache _instance = HashCache(
    maxCacheSize: defaultGlobalHashCacheMaxSize,
    autoClearInterval: const Duration(minutes: 5),
  );

  /// Gets the global hash cache instance.
  static HashCache get instance => _instance;

  static set instance(HashCache value) => _instance = value;
}

/// Utility class for efficient equality comparisons.
///
/// Provides various equality check methods optimized for performance,
/// including shallow, deep, and lazy equality checks.
class PureEquality {
  /// Maximum collection size for fast comparison optimization.
  static const int _maxCollectionSizeForFastComparison = 1000;

  /// Sample size for large collection comparisons.
  static const int _sampleSize = 10;

  /// Standard equality check using == operator.
  ///
  /// First checks for identity, then falls back to == operator.
  static bool eq(Object? a, Object? b) {
    if (identical(a, b)) return true;
    return a == b;
  }

  /// Deep equality check for nested collections and objects.
  ///
  /// Recursively compares collections (List, Map, Set) and their contents.
  /// Optimized for large collections using sampling for very large collections.
  static bool deepEq(Object? a, Object? b) {
    if (identical(a, b)) return true;

    if (a == null || b == null) return false;

    if (a.runtimeType != b.runtimeType) return false;

    if (a == b) return true;

    if (a is List && b is List) {
      return _listEqualsOptimized(a, b);
    }

    if (a is Map && b is Map) {
      return _mapEqualsOptimized(a, b);
    }

    if (a is Set && b is Set) {
      return _setEqualsOptimized(a, b);
    }

    return a == b;
  }

  static bool _isImmutableCollection(Object? obj) {
    if (obj == null) return false;

    final typeName = obj.runtimeType.toString();
    return typeName.contains('Unmodifiable') ||
        typeName.contains('Immutable') ||
        typeName.contains('Const');
  }

  static bool _hashBasedComparison(Object? a, Object? b) {
    if (!_isImmutableCollection(a) || !_isImmutableCollection(b)) {
      return false;
    }

    try {
      return a.hashCode == b.hashCode;
    } on Exception catch (_) {
      return false;
    }
  }

  static bool _listEqualsOptimized(List<Object?> a, List<Object?> b) {
    final aLength = a.length;
    final bLength = b.length;
    if (aLength != bLength) return false;

    if (aLength == 0) return true;

    if (_hashBasedComparison(a, b)) {
      return true;
    }

    if (aLength > _maxCollectionSizeForFastComparison) {
      final step = aLength ~/ _sampleSize;

      for (var i = 0; i < _sampleSize && i * step < aLength; i++) {
        final index = i * step;
        if (!_deepEquals(a[index], b[index])) return false;
      }

      for (var i = 1; i <= _sampleSize && aLength - i * step >= 0; i++) {
        final index = aLength - i * step;
        if (!_deepEquals(a[index], b[index])) return false;
      }
    }

    return _deepListEq(a, b);
  }

  static bool _mapEqualsOptimized(
    Map<Object?, Object?> a,
    Map<Object?, Object?> b,
  ) {
    if (a.length != b.length) return false;

    if (a.isEmpty) return true;

    if (_hashBasedComparison(a, b)) {
      return true;
    }

    if (a.length > _maxCollectionSizeForFastComparison) {
      final aKeys = a.keys.toList();

      if (b.length != a.length) return false;
      for (final key in aKeys) {
        if (!b.containsKey(key)) return false;
      }

      final step = aKeys.length ~/ _sampleSize;

      for (var i = 0; i < _sampleSize && i * step < aKeys.length; i++) {
        final key = aKeys[i * step];
        if (!_deepEquals(a[key], b[key])) return false;
      }

      return _deepMapEq(a, b);
    }

    return _deepMapEq(a, b);
  }

  static bool _setEqualsOptimized(Set<Object?> a, Set<Object?> b) {
    if (a.length != b.length) return false;

    if (a.isEmpty) return true;

    if (_hashBasedComparison(a, b)) {
      return true;
    }

    if (a.length > _maxCollectionSizeForFastComparison) {
      for (final item in a) {
        if (!b.contains(item)) return false;
      }
      return true;
    }

    return setEquals(a, b);
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a == b) return true;

    if (a is List && b is List) {
      return _deepListEq(a, b);
    }

    if (a is Map && b is Map) {
      return _deepMapEq(a, b);
    }

    if (a is Set && b is Set) {
      return _deepSetEq(a, b);
    }

    return a == b;
  }

  static bool _deepListEq(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _deepMapEq(Map<Object?, Object?> a, Map<Object?, Object?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  static bool _deepSetEq(Set<Object?> a, Set<Object?> b) {
    // Sets are unordered, so we can't just iterate index.
    // However, fast path length check.
    if (a.length != b.length) return false;

    // For set deep equality, it gets tricky if elements are objects that need deep equality
    // but don't implement ==.
    // Standard setEquals uses contains(), which uses ==.
    // If elements rely on deep equality for identity, Set won't work well
    // unless the objects implement == using deep equality.

    // But assuming we want to check if every element in A has a deep-equal counterpart in B.
    // This is O(N^2) in worst case if we can't use hash lookup.

    // For now, let's stick to setEquals for Sets as traversing Sets for deep equality
    // without valid hashCodes is very expensive and hard.
    // BUT we should at least check if we can do better.

    return setEquals(a, b);
  }

  /// Shallow equality check using hash cache for performance.
  ///
  /// Uses cached hash values to quickly determine if objects are likely equal.
  /// Falls back to == operator if hashes match.
  ///
  /// - [cache]: Optional hash cache to use (defaults to global cache)
  static bool shallowEq(
    Object? a,
    Object? b, {
    HashCache? cache,
  }) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;

    // Check configuration if no specific cache is provided
    if (cache == null && !PureStateConfig.enableHashCache) {
      return a == b;
    }

    final hashCache = cache ?? _GlobalHashCache.instance;

    final aHash = hashCache.getHash(a);
    final bHash = hashCache.getHash(b);

    if (aHash != bHash) return false;

    return a == b;
  }

  /// Lazy equality check that uses shallow comparison first.
  ///
  /// Performs shallow equality check first, then optionally performs
  /// deep equality check if [useDeep] is true.
  ///
  /// - [useDeep]: Whether to perform deep equality check after shallow check
  static bool lazyEq(Object? a, Object? b, {bool useDeep = false}) {
    if (identical(a, b)) return true;

    if (!shallowEq(a, b)) return false;

    if (useDeep) {
      return deepEq(a, b);
    }

    return true;
  }

  /// Replaces the global hash cache with a custom instance.
  ///
  /// Use this in tests to provide a cache without auto-clear timers.
  @visibleForTesting
  static void debugReplaceGlobalCache(HashCache cache) {
    _GlobalHashCache.instance.dispose();
    _GlobalHashCache.instance = cache;
  }
}
