import 'dart:async';
import 'package:pure_state/src/pure_provider.dart';
import 'package:pure_state/src/pure_store.dart';
import 'package:flutter/material.dart';

/// Widget that listens to store state changes and executes side effects.
///
/// Unlike [PureBuilder], this widget does not rebuild itself.
/// It only executes the listener function when state changes.
/// Useful for side effects like navigation, analytics, etc.
///
/// Example:
/// ```dart
/// PureListener<CounterState>(
///   listener: (context, state) {
///     if (state.count > 10) {
///       Navigator.push(context, SuccessRoute());
///     }
///   },
///   child: MyWidget(),
/// )
/// ```
class PureListener<T> extends StatefulWidget {
  /// Creates a new [PureListener].
  ///
  /// - [listener]: Function called when state changes
  /// - [child]: Widget to display
  /// - [store]: Optional explicit store (if null, uses [PureProvider.of])
  /// - [listenWhen]: Optional function to control when to listen
  /// - [onError]: Optional error handler
  /// - [debounce]: Optional debounce duration for listener calls
  const PureListener({
    required this.listener,
    required this.child,
    this.store,
    this.listenWhen,
    this.onError,
    this.debounce,
    super.key,
  });

  /// Optional explicit store to use.
  ///
  /// If null, the store will be obtained from [PureProvider.of].
  final PureStore<T>? store;

  /// Widget to display.
  final Widget child;

  /// Function called when state changes.
  final void Function(BuildContext context, T state) listener;

  /// Optional error handler.
  final void Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )?
  onError;

  /// Optional function to control when to listen.
  ///
  /// Returns true if the listener should be called for the state change.
  final bool Function(T previous, T current)? listenWhen;

  /// Optional debounce duration for listener calls.
  final Duration? debounce;

  @override
  State<PureListener<T>> createState() => _PureListenerState<T>();
}

class _PureListenerState<T> extends State<PureListener<T>> {
  PureStore<T>? _store;
  StreamSubscription<T>? _subscription;
  late T _previousState;
  Timer? _debounceTimer;
  T? _pendingState;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
    if (_store != null) {
      _previousState = _store!.state;
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_store == null) {
      _store = PureProvider.of<T>(context);
      _previousState = _store!.state;
      _subscribe();
    }
  }

  @override
  void didUpdateWidget(PureListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.debounce != widget.debounce) {
      _debounceTimer?.cancel();
      _debounceTimer = null;

      if (_pendingState != null) {
        _executeListener(_pendingState as T);
        _pendingState = null;
      }
    }
  }

  void _executeListener(T state) {
    if (!mounted) return;

    try {
      widget.listener(context, state);
    } on Exception catch (e, stackTrace) {
      if (widget.onError != null) {
        widget.onError!(context, e, stackTrace);
      } else {
        debugPrint('PureListener Error: $e');
        debugPrint('Stack: $stackTrace');
      }
    }
  }

  void _subscribe() {
    unawaited(_subscription?.cancel());
    _subscription = _store!.stream.listen((currentState) {
      final shouldListen =
          widget.listenWhen?.call(_previousState, currentState) ?? true;

      if (shouldListen) {
        if (!mounted) return;

        _previousState = currentState;

        if (widget.debounce != null) {
          _pendingState = currentState;
          _debounceTimer?.cancel();
          _debounceTimer = Timer(widget.debounce!, () {
            if (mounted && _pendingState != null) {
              _executeListener(_pendingState as T);
              _pendingState = null;
            }
          });
        } else {
          _executeListener(currentState);
        }
      } else {
        _previousState = currentState;
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    unawaited(_subscription?.cancel());
    _pendingState = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
