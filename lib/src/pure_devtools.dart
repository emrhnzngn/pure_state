import 'dart:developer' as developer;
import 'package:pure_state/src/pure_action.dart';
import 'package:pure_state/src/pure_store.dart';

/// Middleware that logs actions and state changes to the Dart VM Service (DevTools).
///
/// This allows inspection of Pure State actions in the 'Logging' view of Flutter DevTools.
void pureDevToolsMiddleware<T>(
  PureStore<T> store,
  PureAction<T> action,
  NextDispatcher<T> next,
) {
  final actionName = action.toString();
  final timestamp = DateTime.now();

  developer.postEvent('pure_state.action.dispatched', {
    'action': actionName,
    'store': store.runtimeType.toString(),
    'timestamp': timestamp.toIso8601String(),
    'currentState': store.state.toString(),
  });

  try {
    next(action);

    developer.postEvent('pure_state.action.completed', {
      'action': actionName,
      'store': store.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'newState': store.state.toString(),
    });
  } catch (e) {
    developer.postEvent('pure_state.action.error', {
      'action': actionName,
      'store': store.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'error': e.toString(),
    });
    rethrow;
  }
}
