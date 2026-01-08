import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pure_state/src/pure_equality.dart';
import 'package:pure_state/src/pure_store.dart';

/// A widget that rebuilds when two different stores change.
///
/// Example:
/// ```dart
/// PureSelector2<CounterState, UserState, String>(
///   store1: counterStore,
///   store2: userStore,
///   selector: (state1, state2) => '${state2.name}: ${state1.count}',
///   builder: (context, value) => Text(value),
/// )
/// ```
class PureSelector2<T1, T2, K> extends StatefulWidget {
  const PureSelector2({
    required this.store1,
    required this.store2,
    required this.selector,
    required this.builder,
    super.key,
  });

  final PureStore<T1> store1;
  final PureStore<T2> store2;
  final K Function(T1 s1, T2 s2) selector;
  final Widget Function(BuildContext context, K value) builder;

  @override
  State<PureSelector2<T1, T2, K>> createState() => _PureSelector2State<T1, T2, K>();
}

class _PureSelector2State<T1, T2, K> extends State<PureSelector2<T1, T2, K>> {
  late K _currentValue;
  StreamSubscription<T1>? _sub1;
  StreamSubscription<T2>? _sub2;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selector(widget.store1.state, widget.store2.state);
    _subscribe();
  }

  void _subscribe() {
    _sub1 = widget.store1.stream.listen((_) => _recalculate());
    _sub2 = widget.store2.stream.listen((_) => _recalculate());
  }

  void _recalculate() {
    if (!mounted) return;
    final newValue = widget.selector(widget.store1.state, widget.store2.state);
    if (!PureEquality.deepEq(_currentValue, newValue)) {
      setState(() {
        _currentValue = newValue;
      });
    }
  }

  @override
  void didUpdateWidget(PureSelector2<T1, T2, K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store1 != widget.store1 || oldWidget.store2 != widget.store2) {
      _sub1?.cancel();
      _sub2?.cancel();
      _subscribe();
      _recalculate();
    }
  }

  @override
  void dispose() {
    _sub1?.cancel();
    _sub2?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentValue);
  }
}

/// A widget that rebuilds when three different stores change.
class PureSelector3<T1, T2, T3, K> extends StatefulWidget {
  const PureSelector3({
    required this.store1,
    required this.store2,
    required this.store3,
    required this.selector,
    required this.builder,
    super.key,
  });

  final PureStore<T1> store1;
  final PureStore<T2> store2;
  final PureStore<T3> store3;
  final K Function(T1 s1, T2 s2, T3 s3) selector;
  final Widget Function(BuildContext context, K value) builder;

  @override
  State<PureSelector3<T1, T2, T3, K>> createState() => _PureSelector3State<T1, T2, T3, K>();
}

class _PureSelector3State<T1, T2, T3, K> extends State<PureSelector3<T1, T2, T3, K>> {
  late K _currentValue;
  StreamSubscription<T1>? _sub1;
  StreamSubscription<T2>? _sub2;
  StreamSubscription<T3>? _sub3;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selector(widget.store1.state, widget.store2.state, widget.store3.state);
    _subscribe();
  }

  void _subscribe() {
    _sub1 = widget.store1.stream.listen((_) => _recalculate());
    _sub2 = widget.store2.stream.listen((_) => _recalculate());
    _sub3 = widget.store3.stream.listen((_) => _recalculate());
  }

  void _recalculate() {
    if (!mounted) return;
    final newValue = widget.selector(widget.store1.state, widget.store2.state, widget.store3.state);
    if (!PureEquality.deepEq(_currentValue, newValue)) {
      setState(() {
        _currentValue = newValue;
      });
    }
  }

  @override
  void didUpdateWidget(PureSelector3<T1, T2, T3, K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store1 != widget.store1 || oldWidget.store2 != widget.store2 || oldWidget.store3 != widget.store3) {
      _sub1?.cancel();
      _sub2?.cancel();
      _sub3?.cancel();
      _subscribe();
      _recalculate();
    }
  }

  @override
  void dispose() {
    _sub1?.cancel();
    _sub2?.cancel();
    _sub3?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentValue);
  }
}
