import 'dart:async';
import 'dart:collection';

import 'package:pure_state/src/pure_equality.dart';
import 'package:pure_state/src/pure_store.dart';
import 'package:flutter/material.dart';

/// Internal LRU (Least Recently Used) cache implementation.
///
/// Used for memoizing selector functions to improve performance.
class _LRUCache<K, V> {
  /// Creates a new LRU cache with the specified maximum size.
  _LRUCache({this.maxSize = 100})
    : assert(maxSize > 0, 'maxSize must be greater than 0');

  /// Maximum number of items in the cache.
  final int maxSize;

  /// Internal storage using LinkedHashMap for O(1) access and order tracking.
  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  void clear() {
    _cache.clear();
  }

  /// Current number of items in the cache.
  int get length => _cache.length;
}

/// Default cache size for selector memoization.
const int defaultSelectorCacheSize = 50;

/// Memoizes a function to cache results and improve performance.
///
/// Uses LRU cache and shallow equality checks to avoid unnecessary recalculations.
///
/// - [calculator]: The function to memoize
/// - [cacheSize]: Maximum cache size (default: [defaultSelectorCacheSize])
R Function(T) memoize<T, R>(R Function(T) calculator, {int? cacheSize}) {
  final lruCache = _LRUCache<int, R>(
    maxSize: cacheSize ?? defaultSelectorCacheSize,
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
  /// - [useRepaintBoundary]: Whether to wrap in RepaintBoundary for performance
  const PureSelector({
    required this.store,
    required this.selector,
    required this.builder,
    super.key,
    this.debounce,
    this.selectorId,
    this.cacheSize,
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
  final int? cacheSize;

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
