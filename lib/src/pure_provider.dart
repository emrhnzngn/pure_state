import 'dart:async';

import 'package:pure_state/src/pure_store.dart';
import 'package:flutter/material.dart';

/// InheritedWidget that provides a [PureStore] to the widget tree.
///
/// Use this widget to make a store available to all descendant widgets.
/// Access the store using [PureProvider.of] or [PureBuilder].
///
/// Example:
/// ```dart
/// PureProvider<CounterState>(
///   store: counterStore,
///   child: MyApp(),
/// )
/// ```
class PureProvider<T> extends InheritedWidget {
  /// Creates a new [PureProvider].
  ///
  /// - [store]: The store to provide
  /// - [child]: The widget tree that will have access to the store
  const PureProvider({required this.store, required super.child, super.key});

  /// The store being provided.
  final PureStore<T> store;

  /// Gets the [PureStore] of type [T] from the nearest [PureProvider] ancestor.
  ///
  /// Throws [FlutterError] if no provider is found in the widget tree.
  ///
  /// Example:
  /// ```dart
  /// final store = PureProvider.of<CounterState>(context);
  /// ```
  static PureStore<T> of<T>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<PureProvider<T>>();
    if (provider == null) {
      throw FlutterError(
        'PureProvider<$T> not found in widget tree!\n'
        'Make sure you have wrapped your widget with PureProvider<$T>.\n'
        'Example:\n'
        '  PureProvider<$T>(\n'
        '    store: myStore,\n'
        '    child: MyApp(),\n'
        '  )\n'
        '\n'
        'If you are trying to access the store from a widget, ensure that\n'
        'widget is a descendant of the PureProvider<$T> widget.',
      );
    }
    return provider.store;
  }

  @override
  bool updateShouldNotify(PureProvider<T> oldWidget) =>
      oldWidget.store != store;
}

/// Widget that rebuilds when the store state changes.
///
/// Automatically subscribes to state changes and rebuilds when the state updates.
/// Can optionally filter rebuilds using [buildWhen].
///
/// Example:
/// ```dart
/// PureBuilder<CounterState>(
///   builder: (context, state) => Text('Count: ${state.count}'),
/// )
/// ```
class PureBuilder<T> extends StatefulWidget {
  /// Creates a new [PureBuilder].
  ///
  /// - [builder]: Function that builds widgets from the current state
  /// - [store]: Optional explicit store (if null, uses [PureProvider.of])
  /// - [buildWhen]: Optional function to control when to rebuild
  /// - [useRepaintBoundary]: Whether to wrap in RepaintBoundary for performance
  const PureBuilder({
    required this.builder,
    super.key,
    this.store,
    this.buildWhen,
    this.useRepaintBoundary = false,
  });

  /// Function that builds widgets from the current state.
  final Widget Function(BuildContext context, T state) builder;

  /// Optional explicit store to use.
  ///
  /// If null, the store will be obtained from [PureProvider.of].
  final PureStore<T>? store;

  /// Optional function to control when to rebuild.
  ///
  /// Returns true if the widget should rebuild for the state change.
  final bool Function(T previous, T current)? buildWhen;

  /// Whether to wrap the built widget in a RepaintBoundary.
  final bool useRepaintBoundary;

  @override
  State<PureBuilder<T>> createState() => _PureBuilderState<T>();
}

class _PureBuilderState<T> extends State<PureBuilder<T>> {
  late T _currentState;
  PureStore<T>? _effectiveStore;
  StreamSubscription<T>? _subscription;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    if (widget.store != null) {
      _effectiveStore = widget.store;
      _currentState = _effectiveStore!.state;
      _subscribe();
      _isInitialized = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _initialize();
    } else {
      try {
        final newStore = widget.store ?? PureProvider.of<T>(context);
        if (_effectiveStore != newStore) {
          _effectiveStore = newStore;
          _currentState = newStore.state;
          _subscribe();
        }
      } on Exception catch (e) {
        debugPrint(
          'PureBuilder<$T>: Store not found or not accessible. $e',
        );
      }
    }
  }

  void _initialize() {
    try {
      final newStore = widget.store ?? PureProvider.of<T>(context);
      if (_isInitialized && _effectiveStore == newStore) return;

      _effectiveStore = newStore;
      _currentState = newStore.state;
      _subscribe();
      _isInitialized = true;
    } on Exception catch (e) {
      debugPrint(
        'PureBuilder<$T>: Store initialization failed. '
        'Provide a store parameter or ensure PureProvider<$T> '
        'exists in the widget tree. $e',
      );
      _isInitialized = false;
    }
  }

  @override
  void didUpdateWidget(PureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.store != oldWidget.store) {
      unawaited(_subscription?.cancel());
      _isInitialized = false;

      _initialize();
    }
  }

  void _subscribe() {
    unawaited(_subscription?.cancel());
    final store = _effectiveStore;
    if (store == null) return;

    _subscription = store.stream.listen((newState) {
      if (!mounted) return;

      if (widget.buildWhen != null) {
        if (!widget.buildWhen!(_currentState, newState)) {
          return;
        }
      }

      if (identical(newState, _currentState)) {
        return;
      }

      if (newState != _currentState) {
        setState(() {
          _currentState = newState;
        });
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _effectiveStore = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized && _effectiveStore == null) {
      if (widget.store != null) {
        final child = widget.builder(context, widget.store!.state);
        if (widget.useRepaintBoundary) {
          return RepaintBoundary(child: child);
        }
        return child;
      }
      return const SizedBox.shrink();
    }

    final child = widget.builder(context, _currentState);
    if (widget.useRepaintBoundary) {
      return RepaintBoundary(child: child);
    }
    return child;
  }
}
