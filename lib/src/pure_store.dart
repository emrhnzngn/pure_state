import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pure_state/src/pure_action.dart';
import 'package:pure_state/src/pure_equality.dart';
import 'package:pure_state/src/pure_performance_profiler.dart';
import 'package:pure_state/src/pure_priority_queue.dart';
import 'package:pure_state/src/pure_store_container.dart';

/// Type definition for the next dispatcher in middleware chain.
typedef NextDispatcher<T> = void Function(PureAction<T> action);

/// Type definition for a middleware function.
typedef PureMiddleware<T> =
    void Function(
      PureStore<T> store,
      PureAction<T> action,
      NextDispatcher<T> next,
    );

/// Type definition for the next dispatcher with result in middleware chain.
typedef NextDispatcherWithResult<T> =
    FutureOr<T> Function(PureAction<T> action);

/// Type definition for a middleware function that can modify action results.
typedef PureMiddlewareWithResult<T> =
    FutureOr<T> Function(
      PureStore<T> store,
      PureAction<T> action,
      NextDispatcherWithResult<T> next,
    );

/// Type definition for a global middleware function.
typedef GlobalMiddleware =
    void Function(
      Object store,
      Object action,
      void Function(Object action) next,
    );

/// Type definition for a global middleware function with result.
typedef GlobalMiddlewareWithResult =
    FutureOr<Object> Function(
      Object store,
      Object action,
      FutureOr<Object> Function(Object action) next,
    );

/// Core store class for managing application state.
class PureStore<T> {
  /// Creates a new [PureStore] with the initial state.
  ///
  /// - [state]: Initial state
  /// - [batchDelay]: Delay between batched state updates. If null, updates are immediate (Simple Mode).
  ///   Default is null (Simple Mode).
  /// - [actionTimeout]: Default timeout for actions.
  /// - [clearQueueOnError]: Whether to clear the queue when an error occurs.
  PureStore(
    this._state, {
    this.onEvent,
    this.actionTimeout,
    this.batchDelay,
    this.clearQueueOnError = true,
    StoreContainer? container,
    int? hashCacheMaxSize,
    Duration? hashCacheAutoClearInterval,
    bool? useAdaptiveBatchDelay,
  }) : _actionQueue = PurePriorityQueue<PureAction<T>>(
         (a, b) => b.priority.compareTo(a.priority),
       ),
       _container = container,
       _hashCache = HashCache(
         maxCacheSize: hashCacheMaxSize,
         autoClearInterval: hashCacheAutoClearInterval,
       ),
       _useAdaptiveBatchDelay = useAdaptiveBatchDelay ?? false {
    if (_useAdaptiveBatchDelay) {
      _adaptiveDelayTracker = _AdaptiveDelayTracker();
    }
  }
  // Named constants for configuration values
  /// Default maximum number of actions to process per cycle.
  static const int defaultMaxActionsPerCycle = 10;

  /// Default maximum processing time in milliseconds per cycle.
  static const int defaultMaxProcessingTimeMs = 8;

  /// Default maximum number of states to keep in history.
  static const int defaultHistoryLimit = 50;

  /// Current state value.
  T _state;

  /// Optional store container for multi-store management.
  final StoreContainer? _container;

  /// Stream controller for state changes.
  final StreamController<T> _controller = StreamController<T>.broadcast();

  /// Stream controller for errors.
  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();

  /// Stream of errors that occur during action execution.
  Stream<Object> get errorStream => _errorController.stream;

  /// List of local middlewares for this store.
  final List<PureMiddleware<T>> _middlewares = [];

  /// List of local middlewares with result for this store.
  final List<PureMiddlewareWithResult<T>> _middlewaresWithResult = [];

  /// List of global middlewares that apply to all stores.
  static final List<GlobalMiddleware> _globalMiddlewares = [];

  /// List of global middlewares with result that apply to all stores.
  static final List<GlobalMiddlewareWithResult> _globalMiddlewaresWithResult =
      [];

  /// Global error handler for all stores.
  static void Function(
    Object error,
    StackTrace? stackTrace,
    Object? store,
    Object? action,
  )?
  globalErrorHandler;

  /// Removes the global error handler.
  static void removeGlobalErrorHandler() {
    globalErrorHandler = null;
  }

  /// Map of action type to handler function.
  final Map<Type, FutureOr<T> Function(T state, PureAction<T> action)>
  _actionHandlers = {};

  /// Optional callback for state change events.
  final void Function(
    PureAction<T>? action,
    T? oldState,
    T? newState,
    Object? error,
  )?
  onEvent;

  /// Priority queue for actions waiting to be processed.
  late final PurePriorityQueue<PureAction<T>> _actionQueue;

  /// Whether the store is currently processing actions.
  bool _isProcessing = false;

  /// Timer map for debounced actions.
  final Map<Object, Timer> _debounceTimers = {};

  /// Timestamp map for throttled actions.
  final Map<Object, DateTime> _throttleTimestamps = {};

  /// Counter for tracking action executions (used for periodic cleanup).
  int _actionExecutionCount = 0;

  /// Number of actions before performing cleanup of old timers/throttles.
  static const int _cleanupInterval = 1000;

  /// Maximum age for throttle timestamps before cleanup (5 minutes).
  static const Duration _maxThrottleAge = Duration(minutes: 5);

  /// History of state changes.
  final List<T> _history = [];

  /// Maximum number of states to keep in history.
  int _historyLimit = 0;

  /// Whether the store has been disposed.
  bool _isDisposed = false;

  /// Default timeout for action execution.
  final Duration? actionTimeout;

  /// Delay between batched state updates.
  ///
  /// If null, updates are emitted immediately after each action.
  final Duration? batchDelay;

  /// Whether to use adaptive batch delay.
  final bool _useAdaptiveBatchDelay;

  /// Whether to clear action queue when an error occurs.
  final bool clearQueueOnError;

  /// Maximum number of actions to process per cycle.
  int _maxActionsPerCycle = defaultMaxActionsPerCycle;

  /// Maximum processing time in milliseconds per cycle.
  int _maxProcessingTimeMs = defaultMaxProcessingTimeMs;

  /// Configures batch processing parameters.
  void configureBatchSize({
    int? maxActionsPerCycle,
    int? maxProcessingTimeMs,
  }) {
    if (maxActionsPerCycle != null && maxActionsPerCycle > 0) {
      _maxActionsPerCycle = maxActionsPerCycle;
    }
    if (maxProcessingTimeMs != null && maxProcessingTimeMs > 0) {
      _maxProcessingTimeMs = maxProcessingTimeMs;
    }
  }

  /// Returns the current batch size configuration.
  Map<String, int> getBatchSizeConfig() {
    return {
      'maxActionsPerCycle': _maxActionsPerCycle,
      'maxProcessingTimeMs': _maxProcessingTimeMs,
    };
  }

  /// Enables performance profiling for this store.
  ///
  /// - [profiler]: The profiler instance to use (creates a new one if null)
  /// - [maxHistorySize]: Maximum number of action executions to track (if creating new profiler)
  /// - [enableDetailedMetrics]: Whether to collect detailed metrics (if creating new profiler)
  void enableProfiling({
    PurePerformanceProfiler? profiler,
    int? maxHistorySize,
    bool? enableDetailedMetrics,
  }) {
    _profiler =
        profiler ??
        PurePerformanceProfiler(
          maxHistorySize: maxHistorySize ?? 1000,
          enableDetailedMetrics: enableDetailedMetrics ?? true,
        );
  }

  /// Disables performance profiling for this store.
  void disableProfiling() {
    _profiler = null;
  }

  /// Gets the performance profiler if enabled.
  PurePerformanceProfiler? get profiler => _profiler;

  /// Gets performance metrics if profiling is enabled.
  PerformanceMetrics? getPerformanceMetrics() {
    return _profiler?.getMetrics();
  }

  /// Hash cache for efficient equality checks.
  final HashCache _hashCache;

  /// Adaptive delay tracker for dynamic batch delay adjustment.
  _AdaptiveDelayTracker? _adaptiveDelayTracker;

  /// Timer for scheduled state updates.
  Timer? _batchTimer;

  /// Pending state waiting to be emitted.
  T? _pendingState;

  /// Optional performance profiler for tracking metrics.
  PurePerformanceProfiler? _profiler;

  /// Gets the current state value.
  T get state => _state;

  /// Gets the stream of state changes.
  Stream<T> get stream {
    return _controller.stream;
  }

  /// Helper method to check if the store is valid (not disposed and controller is open).
  ///
  /// This reduces code duplication for common validation checks.
  bool get _isValid => !_isDisposed && !_controller.isClosed;

  /// Watches another store of type [R] from the container.
  PureStore<R> watch<R>() {
    final container = _container;
    if (container == null) {
      throw StateError(
        'PureStore<$T> was not created with a StoreContainer.\n'
        'To use watch<R>(), you must provide a container parameter when creating the store.\n'
        '\n'
        'Example:\n'
        '  final container = StoreContainer();\n'
        '  final userStore = PureStore<UserState>(\n'
        '    UserState(),\n'
        '    container: container,\n'
        '  );\n'
        '  final settingsStore = PureStore<SettingsState>(\n'
        '    SettingsState(),\n'
        '    container: container,\n'
        '  );\n'
        '\n'
        'Then you can use:\n'
        '  final userStore = settingsStore.watch<UserState>();',
      );
    }
    return container.get<R>();
  }

  /// Reads the state from another store of type [R].
  R read<R>() {
    return watch<R>().state;
  }

  /// Tries to watch another store of type [R] from the container.
  PureStore<R>? tryWatch<R>() {
    final container = _container;
    if (container == null) {
      return null;
    }
    return container.tryGet<R>();
  }

  /// Adds a middleware to this store.
  void addMiddleware(PureMiddleware<T> middleware) {
    _middlewares.add(middleware);
  }

  /// Adds a middleware with result to this store.
  void addMiddlewareWithResult(PureMiddlewareWithResult<T> middleware) {
    _middlewaresWithResult.add(middleware);
  }

  /// Adds a global middleware that applies to all stores.
  static void addGlobalMiddleware(GlobalMiddleware middleware) {
    _globalMiddlewares.add(middleware);
  }

  /// Adds a global middleware with result that applies to all stores.
  static void addGlobalMiddlewareWithResult(
    GlobalMiddlewareWithResult middleware,
  ) {
    _globalMiddlewaresWithResult.add(middleware);
  }

  /// Removes a global middleware.
  static bool removeGlobalMiddleware(GlobalMiddleware middleware) {
    return _globalMiddlewares.remove(middleware);
  }

  /// Removes a global middleware with result.
  static bool removeGlobalMiddlewareWithResult(
    GlobalMiddlewareWithResult middleware,
  ) {
    return _globalMiddlewaresWithResult.remove(middleware);
  }

  /// Registers a handler for a specific action type.
  void on<A extends PureAction<T>>(
    FutureOr<T> Function(T state, A action) handler,
  ) {
    _actionHandlers[A] = (state, action) => handler(state, action as A);
  }

  /// Removes the handler for a specific action type.
  void removeHandler<A extends PureAction<T>>() {
    _actionHandlers.remove(A);
  }

  /// Executes a batch of actions.
  void executeBatch(List<PureAction<T>> actions) {
    if (actions.isEmpty) return;

    if (!_isValid) {
      debugPrint(
        'WARNING: PureStore<$T> is disposed or controller is closed, batch dispatch cancelled.',
      );
      return;
    }

    for (final action in actions) {
      _runMiddlewares(action, _dispatchInternal);
    }
  }

  /// Executes a single action.
  void execute<A extends PureAction<T>>(A action) {
    if (!_isValid) {
      debugPrint(
        'WARNING: PureStore<$T> is disposed or controller is closed, execute cancelled.',
      );
      return;
    }

    final key = action.debounceKey ?? action.runtimeType;

    // Periodic cleanup of old timers and throttles
    _actionExecutionCount++;
    if (_actionExecutionCount >= _cleanupInterval) {
      _cleanupOldTimers();
      _actionExecutionCount = 0;
    }

    // Handle Throttle
    final throttleDuration = action.throttleDuration;
    if (throttleDuration != null) {
      final lastExecution = _throttleTimestamps[key];
      final now = DateTime.now();
      if (lastExecution != null &&
          now.difference(lastExecution) < throttleDuration) {
        return;
      }
      _throttleTimestamps[key] = now;
    }

    // Handle Debounce
    final debounceDuration = action.debounceDuration;
    if (debounceDuration != null) {
      _debounceTimers[key]?.cancel();
      _debounceTimers[key] = Timer(debounceDuration, () {
        _debounceTimers.remove(key);
        if (_isValid) {
          _runMiddlewares(action, _dispatchInternal);
        }
      });
      return;
    }

    _runMiddlewares(action, _dispatchInternal);
  }

  /// Dispatches an action (alias for [execute]).
  void dispatch<A extends PureAction<T>>(A action) {
    execute(action);
  }

  /// Updates the state using a simple updater function.
  void update(FutureOr<T> Function(T state) updater) {
    execute(SimpleUpdateAction<T>(updater));
  }

  /// Updates the state using a functional updater with naming support.
  ///
  /// - [updater]: The function that transforms the state
  /// - [name]: Optional name for the action (for debugging)
  /// - [timeout]: Optional timeout for the action
  ///
  /// This is an alternative to creating action classes for simple updates,
  /// while still providing debug information via [name].
  void mutate(
    FutureOr<T> Function(T state) updater, {
    String? name,
    Duration? timeout,
  }) {
    if (name != null || timeout != null) {
      execute(NamedAction<T>(name ?? 'Mutate', updater, timeout: timeout));
    } else {
      execute(SimpleUpdateAction<T>(updater));
    }
  }

  /// Sets the state to a new value directly.
  ///
  /// This is a convenience method for simple state updates.
  /// It effectively calls [mutate] with a function that returns [newState].
  void setValue(T newState) {
    mutate((_) => newState, name: 'SetValue');
  }

  /// Enables state history for time-travel debugging.
  ///
  /// - [limit]: Maximum number of states to keep in history. Default is [defaultHistoryLimit].
  void enableHistory({int limit = defaultHistoryLimit}) {
    _historyLimit = limit;
    if (_history.isEmpty) {
      _history.add(_state);
    }
  }

  /// Reverts to the previous state in history.
  void undo() {
    if (_historyLimit <= 0 || _history.length < 2) return;
    _history.removeLast(); // Current state
    final previousState = _history.last;
    setValue(previousState);
  }

  /// Reverts to a specific state in history by index.
  void revertTo(int index) {
    if (_historyLimit <= 0 || index < 0 || index >= _history.length) return;
    final targetState = _history[index];
    // We don't clear history here, but we set the state.
    setValue(targetState);
  }

  /// Returns the current state history.
  List<T> get history => List.unmodifiable(_history);

  /// Creates a snapshot of the current state.
  ///
  /// The snapshot can be used to restore the state later using [restore].
  /// This is useful for saving state, debugging, or implementing undo/redo functionality.
  ///
  /// Returns a map containing the state and metadata.
  Map<String, dynamic> snapshot() {
    return {
      'state': _state,
      'timestamp': DateTime.now().toIso8601String(),
      'storeType': runtimeType,
    };
  }

  /// Restores the state from a snapshot.
  ///
  /// The snapshot should be created using [snapshot()].
  /// This will update the state and emit it to all listeners.
  ///
  /// - [snapshot]: The snapshot map created by [snapshot()]
  /// - [validate]: Optional function to validate the snapshot before restoring
  void restore(
    Map<String, dynamic> snapshot, {
    bool Function(Map<String, dynamic>)? validate,
  }) {
    if (!_isValid) {
      debugPrint(
        'WARNING: PureStore<$T> is disposed or controller is closed, restore cancelled.',
      );
      return;
    }

    if (validate != null && !validate(snapshot)) {
      throw ArgumentError('Snapshot validation failed');
    }

    final state = snapshot['state'] as T?;
    if (state == null) {
      throw ArgumentError('Snapshot does not contain a valid state');
    }

    setValue(state);
  }

  void _runMiddlewares(PureAction<T> action, NextDispatcher<T> finalNext) {
    void runLocalMiddlewares(
      PureAction<T> currentAction,
      NextDispatcher<T> localNext,
    ) {
      var index = 0;

      void next(PureAction<T> localAction) {
        if (index >= _middlewares.length) {
          localNext(localAction);
        } else {
          final middleware = _middlewares[index];
          index++;
          middleware(this, localAction, next);
        }
      }

      next(currentAction);
    }

    void runGlobalMiddlewares(Object currentAction) {
      var globalIndex = 0;

      void nextGlobal(Object globalAction) {
        if (globalIndex >= _globalMiddlewares.length) {
          runLocalMiddlewares(action, finalNext);
        } else {
          final globalMiddleware = _globalMiddlewares[globalIndex];
          globalIndex++;
          globalMiddleware(this, globalAction, nextGlobal);
        }
      }

      nextGlobal(currentAction);
    }

    if (_globalMiddlewares.isEmpty) {
      runLocalMiddlewares(action, finalNext);
    } else {
      runGlobalMiddlewares(action);
    }
  }

  FutureOr<T> _runMiddlewaresWithResult(
    PureAction<T> action,
    FutureOr<T> Function(PureAction<T>) executeAction,
  ) async {
    FutureOr<T> runLocalMiddlewaresWithResult(
      PureAction<T> currentAction,
      FutureOr<T> Function(PureAction<T>) localExecuteAction,
    ) async {
      var index = 0;

      FutureOr<T> next(PureAction<T> localAction) async {
        if (index >= _middlewaresWithResult.length) {
          return await localExecuteAction(localAction);
        } else {
          final middleware = _middlewaresWithResult[index];
          index++;
          return await middleware(this, localAction, next);
        }
      }

      return await next(currentAction);
    }

    FutureOr<T> runGlobalMiddlewaresWithResult(Object currentAction) async {
      var globalIndex = 0;

      FutureOr<Object> nextGlobal(Object globalAction) async {
        if (globalIndex >= _globalMiddlewaresWithResult.length) {
          final localResult = await runLocalMiddlewaresWithResult(
            action,
            executeAction,
          );
          return localResult as Object;
        } else {
          final globalMiddleware = _globalMiddlewaresWithResult[globalIndex];
          globalIndex++;
          return await globalMiddleware(this, globalAction, nextGlobal);
        }
      }

      final result = await nextGlobal(currentAction);
      return result as T;
    }

    if (_globalMiddlewaresWithResult.isEmpty) {
      return await runLocalMiddlewaresWithResult(action, executeAction);
    } else {
      return await runGlobalMiddlewaresWithResult(action);
    }
  }

  void _dispatchInternal(PureAction<T> action) {
    if (!_isValid) {
      debugPrint(
        'WARNING: PureStore<$T> is disposed or controller is closed, action dispatch cancelled.',
      );
      return;
    }

    _actionQueue.add(action);

    if (_isProcessing) {
      return;
    }

    unawaited(_processQueue());
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _actionQueue.isEmpty) {
      return;
    }

    _isProcessing = true;
    final isSimpleMode = batchDelay == null;

    final oldState = _state;
    var currentState = _state;
    final processedActions = <PureAction<T>>[];
    var processedCount = 0;

    // Only use stopwatch in batched mode to prevent overhead in simple mode
    // Also use stopwatch if profiling is enabled
    final stopwatch = (isSimpleMode && _profiler == null)
        ? null
        : (Stopwatch()..start());

    while (_actionQueue.isNotEmpty && _isValid) {
      // Check limits only in batched mode
      if (!isSimpleMode && stopwatch != null) {
        final elapsedMs = stopwatch.elapsedMilliseconds;
        if (elapsedMs >= _maxProcessingTimeMs) {
          stopwatch.reset();
          await Future<void>.delayed(Duration.zero);

          if (!_isValid) {
            _actionQueue.clear();
            _isProcessing = false;
            return;
          }
          stopwatch.start();
        }

        if (processedCount > 0 && processedCount % _maxActionsPerCycle == 0) {
          await Future<void>.delayed(Duration.zero);

          if (!_isValid) {
            _actionQueue.clear();
            _isProcessing = false;
            return;
          }
        }
      }

      final action = _actionQueue.removeFirst();
      processedActions.add(action);
      processedCount++;

      // Start profiling if enabled
      Stopwatch? actionStopwatch;
      var actionTypeName = '';

      if (_profiler != null) {
        actionStopwatch = Stopwatch()..start();
        actionTypeName = action.runtimeType.toString();
      }

      try {
        FutureOr<T> Function(PureAction<T>) executeAction;
        final actionType = action.runtimeType;

        final handler = _actionHandlers.isNotEmpty
            ? _actionHandlers[actionType]
            : null;

        if (handler != null) {
          executeAction = (a) => handler(currentState, a);
        } else {
          executeAction = (a) => a.execute(currentState);
        }

        final executeResult = _middlewaresWithResult.isEmpty
            ? executeAction(action)
            : await _runMiddlewaresWithResult(
                action,
                executeAction,
              );

        final timeoutDuration = action.timeout ?? actionTimeout;

        final newState = (executeResult is Future<T>)
            ? (timeoutDuration != null
                  ? await executeResult.timeout(
                      timeoutDuration,
                      onTimeout: () {
                        final timeoutHandler = action.onTimeout;
                        if (timeoutHandler != null) {
                          return timeoutHandler(currentState, timeoutDuration);
                        }
                        throw TimeoutException(
                          'Action timeout: ${timeoutDuration.inSeconds} seconds',
                          timeoutDuration,
                        );
                      },
                    )
                  : await executeResult)
            : executeResult;

        // Record successful action execution
        if (actionStopwatch != null && _profiler != null) {
          actionStopwatch.stop();
          _profiler!.recordActionExecution(
            actionTypeName,
            actionStopwatch.elapsed,
          );
        }

        if (!_isValid) {
          _actionQueue.clear();
          _isProcessing = false;
          return;
        }

        currentState = newState;

        // Record history
        if (_historyLimit > 0) {
          if (_history.length >= _historyLimit) {
            _history.removeAt(0);
          }
          _history.add(currentState);
        }

        // Trigger side effects
        action.onResult(currentState, dispatch);

        // In simple mode, emit updates immediately if state changed
        if (isSimpleMode && currentState != oldState) {
          _state = currentState;
          if (_isValid) {
            _controller.sink.add(currentState);
          }
        }
      } on Exception catch (e, stackTrace) {
        debugPrint('PureStore Error: $e');
        debugPrint('StackTrace: $stackTrace');

        // Record failed action execution
        if (actionStopwatch != null && _profiler != null) {
          actionStopwatch.stop();
          _profiler!.recordActionExecution(
            actionTypeName,
            actionStopwatch.elapsed,
            error: e,
          );
        }

        final globalHandler = globalErrorHandler;
        if (globalHandler != null) {
          try {
            globalHandler(e, stackTrace, this, action);
          } on Exception catch (handlerError) {
            debugPrint(
              'Global error handler error: $handlerError',
            );
          }
        }

        final eventCallback = onEvent;
        if (_isValid && eventCallback != null) {
          for (final processedAction in processedActions) {
            // In simple mode we might have already updated state?
            // Actually let's keep it consistent.
            eventCallback(processedAction, oldState, null, e);
          }
          // processedActions only contains successful or current ones?
          // The current one is added to processedActions list.
        }

        if (_isValid && !_errorController.isClosed) {
          // Add rich error context
          final errorContext = {
            'error': e,
            'stackTrace': stackTrace.toString(),
            'action': action.toString(),
            'actionType': action.runtimeType.toString(),
            'state': currentState.toString(),
            'timestamp': DateTime.now().toIso8601String(),
            'storeType': runtimeType.toString(),
          };
          _errorController.sink.add(errorContext);
        }

        if (clearQueueOnError) {
          _actionQueue.clear();
          _isProcessing = false;
          return;
        } else {
          // Continue processing
        }
      }
    }

    // Record batch processing metrics if profiling is enabled
    if (_profiler != null && stopwatch != null) {
      stopwatch.stop();
      final actionDurations = <int>[];
      if (_profiler!.enableDetailedMetrics && processedActions.isNotEmpty) {
        // Calculate min/max/average from recent metrics
        final recentMetrics = _profiler!.getRecentActionMetrics(
          processedActions.length,
        );
        if (recentMetrics.isNotEmpty) {
          actionDurations.addAll(
            recentMetrics.map((m) => m.duration),
          );
        }
      }

      _profiler!.recordBatchProcessing(
        BatchProcessingMetrics(
          actionsProcessed: processedCount,
          totalDuration: stopwatch.elapsedMilliseconds,
          timestamp: DateTime.now(),
          isSimpleMode: isSimpleMode,
          averageActionDuration: actionDurations.isNotEmpty
              ? (actionDurations.reduce((a, b) => a + b) /
                        actionDurations.length)
                    .round()
              : null,
          maxActionDuration: actionDurations.isNotEmpty
              ? actionDurations.reduce((a, b) => a > b ? a : b)
              : null,
          minActionDuration: actionDurations.isNotEmpty
              ? actionDurations.reduce((a, b) => a < b ? a : b)
              : null,
        ),
      );
    }

    // Final state update logic
    if (currentState != oldState && _isValid) {
      // In simple mode, we already emitted?
      // If isSimpleMode, we emitted incrementally.
      // But we need to ensure consistency.

      if (!isSimpleMode) {
        _state = currentState;

        if (_actionQueue.isEmpty) {
          _pendingState = null;
          _batchTimer?.cancel();
          _batchTimer = null;
          if (_isValid) {
            _controller.sink.add(_state);
          }
        } else {
          _pendingState = currentState;
          _scheduleStateUpdate();
        }
      }

      // onEvent logic
      final eventCallback = onEvent;
      if (eventCallback != null) {
        for (final action in processedActions) {
          // For simple mode, oldState changes per action.
          // This logic assumes batch processing.
          // In simple mode, onEvent should probably trigger immediately too?
          // For now, let's trigger it at end of loop.
          // Ideally in simple mode we process one by one completely.
          if (isSimpleMode) {
            // Should have been handled inside loop?
            // Let's refactor loop to handle onEvent per action in simple mode.
            eventCallback(action, oldState, currentState, null);
          } else {
            eventCallback(action, oldState, currentState, null);
          }
        }
      }
    }

    _isProcessing = false;
  }

  /// Cleans up old debounce timers and throttle timestamps to prevent memory leaks.
  void _cleanupOldTimers() {
    final now = DateTime.now();

    // Clean up old throttle timestamps
    _throttleTimestamps.removeWhere(
      (key, timestamp) => now.difference(timestamp) > _maxThrottleAge,
    );

    // Clean up completed debounce timers (they should auto-remove, but just in case)
    // Note: Active timers are kept, only very old completed ones would be removed
    // Since timers auto-remove on completion, this is mainly for safety
  }

  void _scheduleStateUpdate() {
    if (batchDelay == null) return; // Should not happen in simple mode
    _batchTimer?.cancel();

    final effectiveDelay = _useAdaptiveBatchDelay
        ? _adaptiveDelayTracker!.getCurrentDelay(batchDelay!)
        : batchDelay!;

    _batchTimer = Timer(effectiveDelay, () {
      if (!_isValid) {
        _batchTimer = null;
        return;
      }

      if (_pendingState != null) {
        _controller.sink.add(_pendingState as T);
        _pendingState = null;

        if (_useAdaptiveBatchDelay) {
          _adaptiveDelayTracker!.recordUpdate();
        }
      }

      _batchTimer = null;
    });
  }

  /// Disposes the store and releases all resources.
  void dispose() {
    if (_isDisposed) {
      debugPrint(
        'WARNING: PureStore<$T> is already disposed. '
        'Multiple dispose calls are ignored.',
      );
      return;
    }

    _isDisposed = true;

    _batchTimer?.cancel();
    _batchTimer = null;

    _pendingState = null;

    _actionQueue.clear();

    _middlewares.clear();
    _middlewaresWithResult.clear();

    _actionHandlers.clear();

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _throttleTimestamps.clear();

    _hashCache.dispose();

    _adaptiveDelayTracker = null;

    _profiler = null;

    if (!_controller.isClosed) {
      try {
        unawaited(_controller.close());
      } on Exception catch (e) {
        debugPrint('PureStore dispose: Error closing controller: $e');
      }
    }

    if (!_errorController.isClosed) {
      try {
        unawaited(_errorController.close());
      } on Exception catch (e) {
        debugPrint('PureStore dispose: Error closing errorController: $e');
      }
    }
  }
}

/// Internal class for tracking adaptive batch delay.
class _AdaptiveDelayTracker {
  /// Creates a new adaptive delay tracker.
  _AdaptiveDelayTracker()
    : minDelay = const Duration(milliseconds: _minDelayMs),
      maxDelay = const Duration(milliseconds: _maxDelayMs),
      initialDelay = const Duration(milliseconds: _initialDelayMs),
      _currentDelay = const Duration(milliseconds: _initialDelayMs);

  /// Minimum adaptive delay in milliseconds.
  static const int _minDelayMs = 8;

  /// Maximum adaptive delay in milliseconds.
  static const int _maxDelayMs = 32;

  /// Initial adaptive delay in milliseconds.
  static const int _initialDelayMs = 16;

  /// Minimum delay value.
  final Duration minDelay;

  /// Maximum delay value.
  final Duration maxDelay;

  /// Initial delay value.
  final Duration initialDelay;

  /// Current adaptive delay value.
  Duration _currentDelay;

  /// Count of consecutive rapid updates.
  int _consecutiveUpdates = 0;

  /// Timestamp of the last update.
  DateTime? _lastUpdateTime;

  /// Number of consecutive updates before increasing delay.
  static const int _updatesBeforeIncrease = 3;

  /// Number of idle frames before decreasing delay.
  static const int _idleFramesBeforeDecrease = 10;

  /// Threshold in milliseconds to consider updates as rapid (16ms ≈ 60fps).
  static const int _rapidUpdateThresholdMs = 16;

  /// Count of idle frames.
  int _idleFrames = 0;

  /// Gets the current adaptive delay based on update frequency.
  Duration getCurrentDelay(Duration baseDelay) {
    final now = DateTime.now();
    if (_lastUpdateTime != null) {
      final timeSinceLastUpdate = now
          .difference(_lastUpdateTime!)
          .inMilliseconds;

      if (timeSinceLastUpdate < _rapidUpdateThresholdMs) {
        _consecutiveUpdates++;
        _idleFrames = 0;

        if (_consecutiveUpdates >= _updatesBeforeIncrease) {
          _currentDelay = Duration(
            milliseconds: (_currentDelay.inMilliseconds * 1.5)
                .clamp(minDelay.inMilliseconds, maxDelay.inMilliseconds)
                .toInt(),
          );
          _consecutiveUpdates = 0;
        }
      } else {
        _consecutiveUpdates = 0;
        _idleFrames++;

        if (_idleFrames >= _idleFramesBeforeDecrease) {
          _currentDelay = Duration(
            milliseconds: (_currentDelay.inMilliseconds * 0.9)
                .clamp(minDelay.inMilliseconds, maxDelay.inMilliseconds)
                .toInt(),
          );
          _idleFrames = 0;
        }
      }
    }

    _lastUpdateTime = now;

    final adaptiveMs = _currentDelay.inMilliseconds;
    final baseMs = baseDelay.inMilliseconds;
    final averageMs = ((adaptiveMs + baseMs) / 2).round();

    return Duration(
      milliseconds: averageMs.clamp(
        minDelay.inMilliseconds,
        maxDelay.inMilliseconds,
      ),
    );
  }

  void recordUpdate() {}
}
