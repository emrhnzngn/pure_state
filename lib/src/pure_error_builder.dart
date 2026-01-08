import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pure_state/src/pure_provider.dart';
import 'package:pure_state/src/pure_store.dart';

/// Widget that displays error UI when store errors occur.
///
/// Listens to the store's error stream and displays an error widget
/// when an error is emitted. The child widget is always displayed below the error.
///
/// Example:
/// ```dart
/// PureErrorBuilder<CounterState>(
///   builder: (context, error, stackTrace) => ErrorWidget(error),
///   child: MyApp(),
/// )
/// ```
class PureErrorBuilder<T> extends StatefulWidget {
  /// Creates a new [PureErrorBuilder].
  ///
  /// - [builder]: Function that builds error UI
  /// - [child]: Widget to display below the error
  /// - [store]: Optional explicit store (if null, uses [PureProvider.of])
  /// - [onError]: Optional callback when error occurs
  const PureErrorBuilder({
    required this.builder,
    required this.child,
    this.store,
    this.onError,
    super.key,
  });

  /// Function that builds error UI from error and stack trace.
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )
  builder;

  /// Widget to display below the error.
  final Widget child;

  /// Optional explicit store to use.
  ///
  /// If null, the store will be obtained from [PureProvider.of].
  final PureStore<T>? store;

  /// Optional callback when an error occurs.
  final void Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )?
  onError;

  @override
  State<PureErrorBuilder<T>> createState() => _PureErrorBuilderState<T>();
}

class _PureErrorBuilderState<T> extends State<PureErrorBuilder<T>> {
  PureStore<T>? _store;
  StreamSubscription<Object>? _subscription;
  Object? _currentError;
  StackTrace? _currentStackTrace;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
    if (_store != null) {
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_store == null) {
      try {
        _store = PureProvider.of<T>(context);
        _subscribe();
      } on Exception catch (e) {
        debugPrint(
          'PureErrorBuilder: PureProvider<$T> not found. '
          'Provide a store parameter or ensure PureProvider<$T> '
          'exists in the widget tree. $e',
        );
      }
    }
  }

  @override
  void didUpdateWidget(PureErrorBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      unawaited(_subscription?.cancel());
      _store = widget.store;
      _currentError = null;
      _currentStackTrace = null;
      _subscribe();
    }
  }

  void _subscribe() {
    unawaited(_subscription?.cancel());
    if (_store == null) return;

    _subscription = _store!.errorStream.listen(
      (error) {
        if (!mounted) return;

        StackTrace? stackTrace;
        try {
          stackTrace = StackTrace.current;
        } on Exception catch (_) {}

        setState(() {
          _currentError = error;
          _currentStackTrace = stackTrace;
        });

        if (widget.onError != null) {
          widget.onError!.call(
            context,
            error,
            stackTrace ?? StackTrace.empty,
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() {
          _currentError = error;
          _currentStackTrace = stackTrace;
        });

        if (widget.onError != null) {
          widget.onError!.call(context, error, stackTrace);
        }
      },
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _store = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentError != null && _currentStackTrace != null) {
      return Column(
        children: [
          widget.builder(context, _currentError!, _currentStackTrace!),
          Expanded(child: widget.child),
        ],
      );
    }

    return widget.child;
  }
}
