import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:pure_state/src/pure_equality.dart';
import 'package:pure_state/src/pure_store.dart';

/// Internal LRU (Least Recently Used) cache implementation.
///
/// Used for memoizing selector functions to improve performance.
/// Supports adaptive sizing based on hit/miss ratio.
class _LRUCache<K, V> {
  /// Creates a new LRU cache with the specified maximum size.
  ///
  /// - [maxSize]: Initial maximum cache size
  /// - [enableAdaptiveSizing]: Whether to enable adaptive cache sizing (default: false)
  /// - [minSize]: Minimum cache size when adaptive sizing is enabled
  /// - [maxAdaptiveSize]: Maximum cache size when adaptive sizing is enabled
  _LRUCache({
    this.maxSize = 100,
    this.enableAdaptiveSizing = false,
    int? minSize,
    int? maxAdaptiveSize,
  }) : assert(maxSize > 0, 'maxSize must be greater than 0'),
       _currentMaxSize = maxSize,
       _minSize = minSize ?? (maxSize ~/ 2),
       _maxAdaptiveSize = maxAdaptiveSize ?? (maxSize * 3) {
    assert(_minSize > 0, 'minSize must be greater than 0');
    assert(
      _maxAdaptiveSize >= _currentMaxSize,
      'maxAdaptiveSize must be >= maxSize',
    );
  }

  /// Initial maximum number of items in the cache.
  final int maxSize;

  /// Current maximum size (can change if adaptive sizing is enabled).
  int _currentMaxSize;

  /// Whether adaptive sizing is enabled.
  final bool enableAdaptiveSizing;

  /// Minimum cache size when adaptive sizing is enabled.
  final int _minSize;

  /// Maximum cache size when adaptive sizing is enabled.
  final int _maxAdaptiveSize;

  /// Internal storage using LinkedHashMap for O(1) access and order tracking.
  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  /// Number of cache hits.
  int _hits = 0;

  /// Number of cache misses.
  int _misses = 0;

  /// Number of accesses before recalculating adaptive size.
  static const int _accessCountBeforeAdaptation = 100;

  /// Hit ratio threshold for increasing cache size (0.7 = 70%).
  static const double _hitRatioThresholdForIncrease = 0.7;

  /// Miss ratio threshold for decreasing cache size (0.5 = 50%).
  static const double _missRatioThresholdForDecrease = 0.5;

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
      _hits++;
      _checkAdaptiveSize();
      return value;
    } else {
      _misses++;
      _checkAdaptiveSize();
      return null;
    }
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= _currentMaxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Current number of items in the cache.
  int get length => _cache.length;

  /// Current maximum cache size.
  int get currentMaxSize => _currentMaxSize;

  /// Cache hit ratio (0 to 1).
  double get hitRatio {
    final total = _hits + _misses;
    if (total == 0) return 0;
    return _hits / total;
  }

  /// Total number of accesses (hits + misses).
  int get totalAccesses => _hits + _misses;

  /// Checks if cache size should be adjusted based on hit/miss ratio.
  void _checkAdaptiveSize() {
    if (!enableAdaptiveSizing) return;

    final total = _hits + _misses;
    if (total < _accessCountBeforeAdaptation) return;

    final hitRatio = this.hitRatio;

    // Increase cache size if hit ratio is high (cache is effective)
    if (hitRatio >= _hitRatioThresholdForIncrease &&
        _currentMaxSize < _maxAdaptiveSize) {
      final newSize = (_currentMaxSize * 1.5)
          .clamp(
            _currentMaxSize + 1,
            _maxAdaptiveSize,
          )
          .toInt();
      _currentMaxSize = newSize;
      // Reset counters after adjustment
      _hits = 0;
      _misses = 0;
    }
    // Decrease cache size if miss ratio is high (cache not effective)
    else if (hitRatio <= (1 - _missRatioThresholdForDecrease) &&
        _currentMaxSize > _minSize) {
      final newSize = (_currentMaxSize * 0.75)
          .clamp(
            _minSize,
            _currentMaxSize - 1,
          )
          .toInt();
      _currentMaxSize = newSize;
      // Remove excess entries
      while (_cache.length > _currentMaxSize && _cache.isNotEmpty) {
        _cache.remove(_cache.keys.first);
      }
      // Reset counters after adjustment
      _hits = 0;
      _misses = 0;
    }
  }
}

/// Default cache size for selector memoization.
const int defaultSelectorCacheSize = 100;

/// Memoizes a function to cache results and improve performance.
///
/// Uses LRU cache and shallow equality checks to avoid unnecessary recalculations.
///
/// - [calculator]: The function to memoize
/// - [cacheSize]: Maximum cache size (default: [defaultSelectorCacheSize])
/// - [enableAdaptiveSizing]: Whether to enable adaptive cache sizing (default: true)
///   When enabled, cache size automatically adjusts based on hit/miss ratio.
R Function(T) memoize<T, R>(
  R Function(T) calculator, {
  int? cacheSize,
  bool enableAdaptiveSizing = true,
}) {
  final lruCache = _LRUCache<int, R>(
    maxSize: cacheSize ?? defaultSelectorCacheSize,
    enableAdaptiveSizing: enableAdaptiveSizing,
  );
  T? prevInput;
  R? prevResult;
  int? prevInputHash;
  var isFirstRun = true;

  return (T input) {
    if (isFirstRun) {
      final result = calculator(input);
      prevInput = input;
      prevResult = result;
      prevInputHash = identityHashCode(input);

      if (prevInputHash != null) {
        lruCache.put(prevInputHash!, result);
      }

      isFirstRun = false;
      return result;
    }

    if (identical(input, prevInput)) {
      return prevResult as R;
    }

    final inputHash = identityHashCode(input);

    final cachedResult = lruCache.get(inputHash);
    if (cachedResult != null) {
      prevInput = input;
      prevResult = cachedResult;
      prevInputHash = inputHash;
      return cachedResult;
    }

    if (prevInputHash != null && inputHash != prevInputHash) {
      final result = calculator(input);
      prevInput = input;
      prevResult = result;
      prevInputHash = inputHash;
      lruCache.put(inputHash, result);
      return result;
    }

    if (PureEquality.shallowEq(input, prevInput)) {
      return prevResult as R;
    }

    final result = calculator(input);
    prevInput = input;
    prevResult = result;
    prevInputHash = inputHash;
    lruCache.put(inputHash, result);
    return result;
  };
}

/// Widget that rebuilds only when selected state changes.
///
/// Uses a selector function to extract a portion of the state,
/// and only rebuilds when that portion changes. This improves
/// performance by avoiding unnecessary rebuilds.
///
/// Example:
/// ```dart
/// PureSelector<UserState, String>(
///   store: userStore,
///   selector: (state) => state.name,
///   builder: (context, name) => Text(name),
/// )
/// ```
class PureSelector<T, K> extends StatefulWidget {
  /// Creates a new [PureSelector].
  ///
  /// - [store]: The store to select from
  /// - [selector]: Function that extracts the selected value from state
  /// - [builder]: Builder function that receives the selected value
  /// - [debounce]: Optional debounce duration for updates
  /// - [selectorId]: Optional ID to identify selector changes
  /// - [cacheSize]: Maximum cache size for memoization (default: [defaultSelectorCacheSize])
  /// - [enableAdaptiveSizing]: Whether to enable adaptive cache sizing (default: true)
  /// - [useRepaintBoundary]: Whether to wrap in RepaintBoundary for performance
  const PureSelector({
    required this.store,
    required this.selector,
    required this.builder,
    super.key,
    this.debounce,
    this.selectorId,
    this.cacheSize,
    this.enableAdaptiveSizing = true,
    this.useRepaintBoundary = false,
  });

  /// The store to select from.
  final PureStore<T> store;

  /// Function that extracts the selected value from state.
  final K Function(T state) selector;

  /// Builder function that receives the selected value.
  final Widget Function(BuildContext context, K selectedState) builder;

  /// Optional debounce duration for updates.
  final Duration? debounce;

  /// Optional ID to identify selector changes.
  ///
  /// If provided, selector function changes are detected by ID comparison
  /// instead of function reference comparison.
  final Object? selectorId;

  /// Maximum cache size for memoization.
  ///
  /// Larger cache sizes improve performance for frequently changing states
  /// but use more memory. Default is [defaultSelectorCacheSize].
  ///
  /// If [enableAdaptiveSizing] is true (default), this is the initial size
  /// and will automatically adjust based on cache hit/miss ratio.
  final int? cacheSize;

  /// Whether to enable adaptive cache sizing.
  ///
  /// When enabled (default: true), the cache size automatically adjusts
  /// based on hit/miss ratio to optimize memory usage and performance.
  /// Cache size can grow up to 3x the initial size or shrink down to 50%
  /// of the initial size based on effectiveness.
  final bool enableAdaptiveSizing;

  /// Whether to wrap the built widget in a RepaintBoundary.
  final bool useRepaintBoundary;

  @override
  State<PureSelector<T, K>> createState() => _PureSelectorState<T, K>();
}

class _PureSelectorState<T, K> extends State<PureSelector<T, K>> {
  late K _currentSelectedState;
  StreamSubscription<T>? _subscription;
  T? _previousState;
  Timer? _debounceTimer;

  late K Function(T) _memoizedSelector;

  @override
  void initState() {
    super.initState();
    _initSelector();
    _setupSubscription();
  }

  void _initSelector() {
    _memoizedSelector = memoize<T, K>(
      widget.selector,
      cacheSize: widget.cacheSize,
      enableAdaptiveSizing: widget.enableAdaptiveSizing,
    );
  }

  @override
  void didUpdateWidget(PureSelector<T, K> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.store != widget.store) {
      _resubscribe();
      return;
    }

    final selectorChanged = widget.selectorId != null
        ? widget.selectorId != oldWidget.selectorId
        : oldWidget.selector != widget.selector;

    if (selectorChanged) {
      _initSelector();
      _currentSelectedState = _memoizedSelector(widget.store.state);
    }

    if (oldWidget.debounce != widget.debounce) {
      _debounceTimer?.cancel();
    }
  }

  void _resubscribe() {
    unawaited(_subscription?.cancel());
    _debounceTimer?.cancel();
    _previousState = null;
    _setupSubscription();
  }

  void _setupSubscription() {
    _currentSelectedState = _memoizedSelector(widget.store.state);
    _previousState = widget.store.state;

    _subscription = widget.store.stream.listen((newState) {
      if (!mounted) return;

      if (identical(newState, _previousState)) return;

      _previousState = newState;

      final newSelectedState = _memoizedSelector(newState);

      final isEqual =
          identical(newSelectedState, _currentSelectedState) ||
          PureEquality.shallowEq(newSelectedState, _currentSelectedState);

      if (!isEqual) {
        if (widget.debounce != null) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(widget.debounce!, () {
            if (mounted) _updateState(newSelectedState);
          });
        } else {
          _updateState(newSelectedState);
        }
      }
    });
  }

  void _updateState(K newSelectedState) {
    setState(() {
      _currentSelectedState = newSelectedState;
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _debounceTimer?.cancel();
    _subscription = null;
    _previousState = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(context, _currentSelectedState);
    if (widget.useRepaintBoundary) {
      return RepaintBoundary(child: child);
    }
    return child;
  }
}
