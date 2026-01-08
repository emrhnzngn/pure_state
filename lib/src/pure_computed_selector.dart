import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pure_state/src/pure_equality.dart';
import 'package:pure_state/src/pure_store.dart';

/// A selector that computes values from multiple stores.
///
/// This widget listens to multiple stores and rebuilds only when the
/// computed value changes. It's useful for deriving state from multiple sources.
///
/// Example:
/// ```dart
/// PureComputedSelector2<UserState, SettingsState, String>(
///   store1: userStore,
///   store2: settingsStore,
///   selector: (user, settings) => '${user.name} - ${settings.theme}',
///   builder: (context, computed) => Text(computed),
/// )
/// ```
class PureComputedSelector2<T1, T2, R> extends StatefulWidget {
  /// Creates a computed selector from two stores.
  const PureComputedSelector2({
    required this.store1,
    required this.store2,
    required this.selector,
    required this.builder,
    super.key,
    this.cacheSize,
    this.debounce,
  });

  /// First store.
  final PureStore<T1> store1;

  /// Second store.
  final PureStore<T2> store2;

  /// Function that computes a value from both states.
  final R Function(T1 state1, T2 state2) selector;

  /// Builder function that receives the computed value.
  final Widget Function(BuildContext context, R computed) builder;

  /// Cache size for memoization.
  final int? cacheSize;

  /// Optional debounce duration.
  final Duration? debounce;

  @override
  State<PureComputedSelector2<T1, T2, R>> createState() =>
      _PureComputedSelector2State<T1, T2, R>();
}

class _PureComputedSelector2State<T1, T2, R>
    extends State<PureComputedSelector2<T1, T2, R>> {
  late R _currentValue;
  StreamSubscription<T1>? _subscription1;
  StreamSubscription<T2>? _subscription2;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selector(widget.store1.state, widget.store2.state);
    _setupSubscriptions();
  }

  @override
  void didUpdateWidget(PureComputedSelector2<T1, T2, R> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.store1 != widget.store1 ||
        oldWidget.store2 != widget.store2) {
      _resubscribe();
    }
  }

  void _setupSubscriptions() {
    _subscription1 = widget.store1.stream.listen(_onStateChange);
    _subscription2 = widget.store2.stream.listen(_onStateChange);
  }

  void _resubscribe() {
    unawaited(_subscription1?.cancel());
    unawaited(_subscription2?.cancel());
    _debounceTimer?.cancel();
    _setupSubscriptions();
    _currentValue = widget.selector(widget.store1.state, widget.store2.state);
  }

  void _onStateChange(dynamic _) {
    if (!mounted) return;

    final newValue = widget.selector(widget.store1.state, widget.store2.state);

    if (!PureEquality.shallowEq(newValue, _currentValue)) {
      if (widget.debounce != null) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(widget.debounce!, () {
          if (mounted) _updateValue(newValue);
        });
      } else {
        _updateValue(newValue);
      }
    }
  }

  void _updateValue(R newValue) {
    setState(() {
      _currentValue = newValue;
    });
  }

  @override
  void dispose() {
    unawaited(_subscription1?.cancel());
    unawaited(_subscription2?.cancel());
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentValue);
  }
}

/// A selector that computes values from three stores.
class PureComputedSelector3<T1, T2, T3, R> extends StatefulWidget {
  /// Creates a computed selector from three stores.
  const PureComputedSelector3({
    required this.store1,
    required this.store2,
    required this.store3,
    required this.selector,
    required this.builder,
    super.key,
    this.debounce,
  });

  /// First store.
  final PureStore<T1> store1;

  /// Second store.
  final PureStore<T2> store2;

  /// Third store.
  final PureStore<T3> store3;

  /// Function that computes a value from all states.
  final R Function(T1 state1, T2 state2, T3 state3) selector;

  /// Builder function that receives the computed value.
  final Widget Function(BuildContext context, R computed) builder;

  /// Optional debounce duration.
  final Duration? debounce;

  @override
  State<PureComputedSelector3<T1, T2, T3, R>> createState() =>
      _PureComputedSelector3State<T1, T2, T3, R>();
}

class _PureComputedSelector3State<T1, T2, T3, R>
    extends State<PureComputedSelector3<T1, T2, T3, R>> {
  late R _currentValue;
  StreamSubscription<T1>? _subscription1;
  StreamSubscription<T2>? _subscription2;
  StreamSubscription<T3>? _subscription3;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selector(
      widget.store1.state,
      widget.store2.state,
      widget.store3.state,
    );
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    _subscription1 = widget.store1.stream.listen(_onStateChange);
    _subscription2 = widget.store2.stream.listen(_onStateChange);
    _subscription3 = widget.store3.stream.listen(_onStateChange);
  }

  void _onStateChange(dynamic _) {
    if (!mounted) return;

    final newValue = widget.selector(
      widget.store1.state,
      widget.store2.state,
      widget.store3.state,
    );

    if (!PureEquality.shallowEq(newValue, _currentValue)) {
      if (widget.debounce != null) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(widget.debounce!, () {
          if (mounted) _updateValue(newValue);
        });
      } else {
        _updateValue(newValue);
      }
    }
  }

  void _updateValue(R newValue) {
    setState(() {
      _currentValue = newValue;
    });
  }

  @override
  void dispose() {
    unawaited(_subscription1?.cancel());
    unawaited(_subscription2?.cancel());
    unawaited(_subscription3?.cancel());
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentValue);
  }
}

/// A flexible computed selector that works with a dynamic list of stores.
///
/// Example:
/// ```dart
/// PureComputedSelectorN<String>(
///   stores: [userStore, settingsStore, cartStore],
///   selector: (states) {
///     final user = states[0] as UserState;
///     final settings = states[1] as SettingsState;
///     final cart = states[2] as CartState;
///     return 'User: ${user.name}, Theme: ${settings.theme}, Items: ${cart.items.length}';
///   },
///   builder: (context, computed) => Text(computed),
/// )
/// ```
class PureComputedSelectorN<R> extends StatefulWidget {
  /// Creates a computed selector from multiple stores.
  const PureComputedSelectorN({
    required this.stores,
    required this.selector,
    required this.builder,
    super.key,
    this.debounce,
  });

  /// List of stores to observe.
  final List<PureStore<dynamic>> stores;

  /// Function that computes a value from all states.
  final R Function(List<dynamic> states) selector;

  /// Builder function that receives the computed value.
  final Widget Function(BuildContext context, R computed) builder;

  /// Optional debounce duration.
  final Duration? debounce;

  @override
  State<PureComputedSelectorN<R>> createState() =>
      _PureComputedSelectorNState<R>();
}

class _PureComputedSelectorNState<R> extends State<PureComputedSelectorN<R>> {
  late R _currentValue;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentValue = _computeValue();
    _setupSubscriptions();
  }

  R _computeValue() {
    final states = widget.stores.map((store) => store.state).toList();
    return widget.selector(states);
  }

  void _setupSubscriptions() {
    for (final store in widget.stores) {
      _subscriptions.add(store.stream.listen(_onStateChange));
    }
  }

  void _onStateChange(dynamic _) {
    if (!mounted) return;

    final newValue = _computeValue();

    if (!PureEquality.shallowEq(newValue, _currentValue)) {
      if (widget.debounce != null) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(widget.debounce!, () {
          if (mounted) _updateValue(newValue);
        });
      } else {
        _updateValue(newValue);
      }
    }
  }

  void _updateValue(R newValue) {
    setState(() {
      _currentValue = newValue;
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentValue);
  }
}

/// Non-widget computed value that updates based on multiple stores.
///
/// Useful for business logic that depends on multiple stores.
///
/// Example:
/// ```dart
/// final computed = ComputedValue2(
///   store1: userStore,
///   store2: settingsStore,
///   compute: (user, settings) => '${user.name} - ${settings.theme}',
/// );
///
/// computed.listen((value) => print('Computed: $value'));
/// ```
class ComputedValue2<T1, T2, R> {
  /// Creates a computed value from two stores.
  ComputedValue2({
    required this.store1,
    required this.store2,
    required this.compute,
  }) {
    _setupSubscriptions();
  }

  /// First store.
  final PureStore<T1> store1;

  /// Second store.
  final PureStore<T2> store2;

  /// Computation function.
  final R Function(T1 state1, T2 state2) compute;

  /// Stream controller for computed values.
  final StreamController<R> _controller = StreamController<R>.broadcast();

  /// Subscriptions to stores.
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Current computed value.
  late R _value;

  /// Gets the current computed value.
  R get value => _value;

  /// Stream of computed value changes.
  Stream<R> get stream => _controller.stream;

  void _setupSubscriptions() {
    _value = compute(store1.state, store2.state);

    _subscriptions
      ..add(
        store1.stream.listen((_) => _recompute()),
      )
      ..add(
        store2.stream.listen((_) => _recompute()),
      );
  }

  void _recompute() {
    final newValue = compute(store1.state, store2.state);

    if (!PureEquality.shallowEq(newValue, _value)) {
      _value = newValue;
      _controller.add(_value);
    }
  }

  /// Listens to computed value changes.
  StreamSubscription<R> listen(void Function(R value) onData) {
    return stream.listen(onData);
  }

  /// Disposes the computed value and releases resources.
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_controller.close());
  }
}
