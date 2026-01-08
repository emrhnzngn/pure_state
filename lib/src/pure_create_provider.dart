import 'package:pure_state/src/pure_provider.dart';
import 'package:pure_state/src/pure_store.dart';
import 'package:flutter/material.dart';

/// Widget that creates and provides a store, disposing it when removed.
///
/// Useful for creating stores that depend on context (e.g., route parameters)
/// and ensuring proper cleanup when the widget is removed from the tree.
///
/// Example:
/// ```dart
/// PureCreateProvider<CounterState>(
///   create: (context) => CounterStore(initialCount: 0),
///   child: MyApp(),
/// )
/// ```
class PureCreateProvider<T> extends StatefulWidget {
  /// Creates a new [PureCreateProvider].
  ///
  /// - [create]: Function that creates the store
  /// - [child]: The widget tree that will have access to the store
  const PureCreateProvider({
    required this.create,
    required this.child,
    super.key,
  });

  /// Function that creates the store.
  ///
  /// Called once during initialization and can use [BuildContext] if needed.
  final PureStore<T> Function(BuildContext context) create;

  /// The widget tree that will have access to the store.
  final Widget child;

  @override
  State<PureCreateProvider<T>> createState() => _PureCreateProviderState<T>();
}

class _PureCreateProviderState<T> extends State<PureCreateProvider<T>> {
  late PureStore<T> _store;

  @override
  void initState() {
    super.initState();
    _store = widget.create(context);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PureProvider<T>(store: _store, child: widget.child);
  }
}
