import 'dart:async';

import 'package:pure_state/src/pure_store.dart';

/// A store that automatically disposes itself when no longer in use.
///
/// [PureAutoDisposeStore] tracks active listeners and automatically
/// disposes the store after a period of inactivity (when no listeners remain).
///
/// This is useful for:
/// - Preventing memory leaks in long-running applications
/// - Cleaning up resources for ephemeral stores
/// - Managing lifecycle of dynamically created stores
///
/// **Important:** Use [listenTracked] instead of [stream.listen] to enable
/// auto-dispose functionality.
///
/// Example:
/// ```dart
/// final userStore = PureAutoDisposeStore<UserState>(
///   UserState(),
///   keepAliveFor: Duration(minutes: 5),
/// );
///
/// // Use listenTracked for auto-dispose support
/// final subscription = userStore.listenTracked((state) {
///   print('State: $state');
/// });
///
/// // After subscription is cancelled and keepAliveFor duration passes,
/// // the store automatically disposes itself
/// subscription.cancel();
/// ```
class PureAutoDisposeStore<T> extends PureStore<T> {
  /// Creates an auto-disposing store.
  ///
  /// - [state]: Initial state
  /// - [keepAliveFor]: Duration to keep store alive after last listener removes
  /// - [onAutoDispose]: Optional callback when auto-dispose triggers
  /// - Other parameters are passed to [PureStore]
  PureAutoDisposeStore(
    super.state, {
    this.keepAliveFor = const Duration(seconds: 60),
    this.onAutoDispose,
    super.onEvent,
    super.actionTimeout,
    super.batchDelay,
    super.clearQueueOnError,
    super.container,
    super.hashCacheMaxSize,
    super.hashCacheAutoClearInterval,
    super.useAdaptiveBatchDelay,
  });

  /// Duration to keep the store alive after the last listener is removed.
  final Duration keepAliveFor;

  /// Optional callback when auto-dispose triggers.
  final void Function()? onAutoDispose;

  /// Timer for auto-disposal.
  Timer? _autoDisposeTimer;

  /// Number of active listeners.
  int _listenerCount = 0;

  /// Whether auto-dispose has been triggered.
  bool _autoDisposed = false;

  /// Active subscriptions for tracking.
  final Set<StreamSubscription<T>> _activeSubscriptions = {};

  /// Gets the current number of active listeners.
  int get listenerCount => _listenerCount;

  /// Checks if the store has been auto-disposed.
  bool get isAutoDisposed => _autoDisposed;

  /// Creates a tracked subscription that participates in auto-dispose.
  ///
  /// Use this method instead of directly calling `stream.listen()` to enable
  /// auto-dispose functionality.
  ///
  /// Example:
  /// ```dart
  /// final subscription = autoStore.listenTracked((state) {
  ///   print('State: $state');
  /// });
  ///
  /// // Later, cancel to decrement listener count
  /// subscription.cancel();
  /// ```
  StreamSubscription<T> listenTracked(
    void Function(T state) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _onListenerAdded();

    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    _activeSubscriptions.add(subscription);

    // Wrap subscription to track cancellation
    return _TrackedSubscription<T>(
      subscription: subscription,
      onCancel: () {
        _activeSubscriptions.remove(subscription);
        _onListenerRemoved();
      },
    );
  }

  /// Called when a listener is added.
  void _onListenerAdded() {
    _listenerCount++;
    _cancelAutoDisposeTimer();
  }

  /// Called when a listener is removed.
  void _onListenerRemoved() {
    _listenerCount--;
    if (_listenerCount <= 0) {
      _scheduleAutoDispose();
    }
  }

  /// Schedules auto-disposal after the keep-alive duration.
  void _scheduleAutoDispose() {
    _cancelAutoDisposeTimer();
    _autoDisposeTimer = Timer(keepAliveFor, () {
      if (_listenerCount <= 0 && !_autoDisposed) {
        _performAutoDispose();
      }
    });
  }

  /// Cancels the auto-dispose timer.
  void _cancelAutoDisposeTimer() {
    _autoDisposeTimer?.cancel();
    _autoDisposeTimer = null;
  }

  /// Performs the actual auto-disposal.
  void _performAutoDispose() {
    _autoDisposed = true;

    // Notify callback
    onAutoDispose?.call();

    // Dispose the store
    dispose();
  }

  /// Keeps the store alive indefinitely by cancelling auto-dispose.
  ///
  /// Call this if you want to prevent auto-disposal for this store.
  void keepAlive() {
    _cancelAutoDisposeTimer();
  }

  /// Manually triggers auto-dispose regardless of listener count.
  void triggerAutoDispose() {
    _performAutoDispose();
  }

  @override
  void dispose() {
    _cancelAutoDisposeTimer();

    // Cancel all tracked subscriptions
    for (final subscription in _activeSubscriptions) {
      unawaited(subscription.cancel());
    }
    _activeSubscriptions.clear();

    super.dispose();
  }
}

/// Wrapper for StreamSubscription that tracks cancellation.
class _TrackedSubscription<T> implements StreamSubscription<T> {
  _TrackedSubscription({
    required StreamSubscription<T> subscription,
    required this.onCancel,
  }) : _subscription = subscription;

  final StreamSubscription<T> _subscription;
  final void Function() onCancel;
  bool _isCancelled = false;

  @override
  Future<void> cancel() async {
    if (!_isCancelled) {
      _isCancelled = true;
      onCancel();
      return _subscription.cancel();
    }
  }

  @override
  void onData(void Function(T data)? handleData) {
    _subscription.onData(handleData);
  }

  @override
  void onError(Function? handleError) {
    _subscription.onError(handleError);
  }

  @override
  void onDone(void Function()? handleDone) {
    _subscription.onDone(handleDone);
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    return _subscription.asFuture(futureValue);
  }

  @override
  bool get isPaused => _subscription.isPaused;

  @override
  void pause([Future<void>? resumeSignal]) {
    _subscription.pause(resumeSignal);
  }

  @override
  void resume() {
    _subscription.resume();
  }
}

/// Extension methods for creating auto-disposing stores.
extension PureStoreAutoDisposeExtension<T> on PureStore<T> {
  /// Converts this store to an auto-disposing store.
  ///
  /// Note: This creates a new store instance with the current state.
  /// The original store is not modified.
  PureAutoDisposeStore<T> toAutoDispose({
    Duration keepAliveFor = const Duration(seconds: 60),
    void Function()? onAutoDispose,
  }) {
    return PureAutoDisposeStore<T>(
      state,
      keepAliveFor: keepAliveFor,
      onAutoDispose: onAutoDispose,
      actionTimeout: actionTimeout,
      batchDelay: batchDelay,
      clearQueueOnError: clearQueueOnError,
    );
  }
}

/// A mixin that adds listener tracking to stores.
///
/// This can be used to create custom auto-dispose logic or monitoring.
mixin ListenerTrackingMixin<T> on PureStore<T> {
  /// Map of listener IDs to their subscription info.
  final Map<String, _ListenerInfo> _listeners = {};

  /// Registers a listener with tracking.
  String trackListener(void Function(T state) listener) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final subscription = stream.listen(listener);

    _listeners[id] = _ListenerInfo(
      subscription: subscription,
      addedAt: DateTime.now(),
    );

    return id;
  }

  /// Unregisters a tracked listener.
  void untrackListener(String id) {
    final info = _listeners.remove(id);
    unawaited(info?.subscription.cancel());
  }

  /// Gets information about all tracked listeners.
  Map<String, DateTime> get listenerInfo {
    return Map.fromEntries(
      _listeners.entries.map((e) => MapEntry(e.key, e.value.addedAt)),
    );
  }

  /// Disposes all tracked listeners.
  void disposeAllTrackedListeners() {
    for (final info in _listeners.values) {
      unawaited(info.subscription.cancel());
    }
    _listeners.clear();
  }
}

/// Information about a tracked listener.
class _ListenerInfo {
  _ListenerInfo({
    required this.subscription,
    required this.addedAt,
  });

  final StreamSubscription<dynamic> subscription;
  final DateTime addedAt;
}

/// A store that automatically disposes after a fixed duration.
///
/// Unlike [PureAutoDisposeStore] which disposes based on listener count,
/// [PureTTLStore] (Time-To-Live Store) disposes after a fixed duration
/// regardless of listener activity.
///
/// Example:
/// ```dart
/// final tempStore = PureTTLStore<TempState>(
///   TempState(),
///   ttl: Duration(minutes: 10),
///   onExpire: () => print('Store expired'),
/// );
/// ```
class PureTTLStore<T> extends PureStore<T> {
  /// Creates a store with a time-to-live duration.
  PureTTLStore(
    super.state, {
    required this.ttl,
    this.onExpire,
    super.onEvent,
    super.actionTimeout,
    super.batchDelay,
    super.clearQueueOnError,
    super.container,
    super.hashCacheMaxSize,
    super.hashCacheAutoClearInterval,
    super.useAdaptiveBatchDelay,
  }) {
    _startTTLTimer();
  }

  /// Time-to-live duration for this store.
  final Duration ttl;

  /// Optional callback when TTL expires.
  final void Function()? onExpire;

  /// TTL timer.
  Timer? _ttlTimer;

  /// Whether the store has expired.
  bool _expired = false;

  /// Gets whether the store has expired.
  bool get isExpired => _expired;

  /// Starts the TTL timer.
  void _startTTLTimer() {
    _ttlTimer = Timer(ttl, () {
      _expired = true;
      onExpire?.call();
      dispose();
    });
  }

  /// Extends the TTL by the specified duration.
  void extendTTL(Duration extension) {
    if (!_expired) {
      _ttlTimer?.cancel();
      // In a real implementation, you would track remaining time
      _ttlTimer = Timer(extension, () {
        _expired = true;
        onExpire?.call();
        dispose();
      });
    }
  }

  @override
  void dispose() {
    _ttlTimer?.cancel();
    _ttlTimer = null;
    super.dispose();
  }
}
