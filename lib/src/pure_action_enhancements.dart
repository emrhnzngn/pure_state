import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pure_state/src/pure_action.dart';
import 'package:pure_state/src/pure_store.dart';

/// Abstract base class for actions that require authorization.
///
/// Extend this class to create actions that check permissions before execution.
///
/// Example:
/// ```dart
/// class DeleteUserAction extends PureAuthorizedAction<AppState> {
///   @override
///   bool authorize(AppState state) {
///     return state.currentUser.role == UserRole.admin;
///   }
///
///   @override
///   AppState executeAuthorized(AppState state) {
///     return state.copyWith(users: state.users.remove(userId));
///   }
/// }
/// ```
abstract class PureAuthorizedAction<T> extends PureAction<T> {
  /// Creates an authorized action.
  const PureAuthorizedAction();

  /// Checks if the action is authorized to execute.
  ///
  /// Return true to allow execution, false to deny.
  bool authorize(T state);

  /// Executes the action after authorization succeeds.
  ///
  /// This method is only called if [authorize] returns true.
  FutureOr<T> executeAuthorized(T state);

  /// Called when authorization fails.
  ///
  /// Override this to customize unauthorized behavior.
  /// By default, throws [UnauthorizedException].
  FutureOr<T> onUnauthorized(T state) {
    throw UnauthorizedException(
      'Action $runtimeType is not authorized',
    );
  }

  @override
  FutureOr<T> execute(T currentState) async {
    if (!authorize(currentState)) {
      return onUnauthorized(currentState);
    }
    return executeAuthorized(currentState);
  }
}

/// Exception thrown when an action is not authorized.
class UnauthorizedException implements Exception {
  /// Creates an unauthorized exception.
  const UnauthorizedException(this.message);

  /// Error message.
  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Abstract interface for validatable state objects.
///
/// Implement this interface on your state classes to enable validation.
///
/// Example:
/// ```dart
/// class UserState with ValidatableState {
///   final String email;
///   final int age;
///
///   @override
///   ValidationResult validate() {
///     final errors = <String>[];
///
///     if (!email.contains('@')) {
///       errors.add('Invalid email format');
///     }
///
///     if (age < 0 || age > 150) {
///       errors.add('Age must be between 0 and 150');
///     }
///
///     return ValidationResult(errors);
///   }
/// }
/// ```
mixin ValidatableState {
  /// Validates the state and returns a result.
  ValidationResult validate();
}

/// Result of a state validation.
class ValidationResult {
  /// Creates a validation result.
  const ValidationResult(this.errors);

  /// List of validation errors.
  ///
  /// Empty list means validation passed.
  final List<String> errors;

  /// Whether the validation passed (no errors).
  bool get isValid => errors.isEmpty;

  /// Whether the validation failed (has errors).
  bool get isInvalid => errors.isNotEmpty;

  /// Gets the first error message, or null if valid.
  String? get firstError => errors.isNotEmpty ? errors.first : null;

  @override
  String toString() {
    if (isValid) return 'ValidationResult: Valid';
    return 'ValidationResult: Invalid - ${errors.join(', ')}';
  }
}

/// Exception thrown when state validation fails.
class StateValidationException implements Exception {
  /// Creates a validation exception.
  const StateValidationException(this.errors);

  /// Validation errors.
  final List<String> errors;

  @override
  String toString() => 'StateValidationException: ${errors.join(', ')}';
}

/// Action that validates state after execution.
///
/// Extend this to automatically validate state after action execution.
///
/// Example:
/// ```dart
/// class UpdateUserAction extends PureValidatedAction<UserState> {
///   @override
///   UserState execute(UserState state) {
///     return state.copyWith(email: newEmail);
///   }
/// }
/// ```
abstract class PureValidatedAction<T extends ValidatableState>
    extends PureAction<T> {
  /// Creates a validated action.
  const PureValidatedAction();

  @override
  FutureOr<T> execute(T currentState) async {
    final newState = await executeWithoutValidation(currentState);

    final validation = newState.validate();
    if (validation.isInvalid) {
      throw StateValidationException(validation.errors);
    }

    return newState;
  }

  /// Executes the action without validation.
  ///
  /// Override this instead of [execute] when extending [PureValidatedAction].
  FutureOr<T> executeWithoutValidation(T state);
}

/// Abstract base class for actions with retry logic.
///
/// Extend this class to create actions that automatically retry on failure.
///
/// Example:
/// ```dart
/// class FetchUserAction extends PureRetryableAction<AppState> {
///   @override
///   int get maxRetries => 3;
///
///   @override
///   Duration get retryDelay => Duration(seconds: 1);
///
///   @override
///   bool shouldRetry(Object error) => error is NetworkException;
///
///   @override
///   Future<AppState> executeWithRetry(AppState state) async {
///     final user = await api.fetchUser();
///     return state.copyWith(user: user);
///   }
/// }
/// ```
abstract class PureRetryableAction<T> extends PureAction<T> {
  /// Creates a retryable action.
  const PureRetryableAction();

  /// Maximum number of retry attempts.
  ///
  /// Default is 3. Set to 0 to disable retries.
  int get maxRetries => 3;

  /// Delay between retry attempts.
  ///
  /// Default is 1 second.
  Duration get retryDelay => const Duration(seconds: 1);

  /// Determines whether to retry based on the error.
  ///
  /// Return true to retry, false to fail immediately.
  /// Default is to retry on any error.
  bool shouldRetry(Object error) => true;

  /// Called before each retry attempt.
  ///
  /// Override this to log retry attempts or implement backoff strategies.
  void onRetry(int attempt, Object error) {
    debugPrint(
      'Retrying $runtimeType (attempt $attempt/$maxRetries): $error',
    );
  }

  /// Called when all retries are exhausted.
  ///
  /// Override this to provide fallback behavior.
  /// By default, rethrows the last error.
  FutureOr<T> onRetriesExhausted(T state, Object lastError) {
    if (lastError is Exception) {
      final exception = lastError;
      throw exception;
    }
    if (lastError is Error) {
      final error = lastError;
      throw error;
    }
    throw Exception('Action failed: $lastError');
  }

  /// Executes the action with retry logic.
  ///
  /// Override this method with your actual action logic.
  FutureOr<T> executeWithRetry(T state);

  @override
  Future<T> execute(T currentState) async {
    var attempt = 0;
    Object? lastError;

    while (attempt <= maxRetries) {
      try {
        return await executeWithRetry(currentState);
      } on Exception catch (error) {
        lastError = error;

        if (attempt >= maxRetries || !shouldRetry(error)) {
          return onRetriesExhausted(currentState, error);
        }

        onRetry(attempt + 1, error);
        await Future<void>.delayed(retryDelay);
        attempt++;
      }
    }

    // This should never be reached, but handle it just in case
    if (lastError != null) {
      return onRetriesExhausted(currentState, lastError);
    }

    return currentState;
  }
}

/// An action with exponential backoff retry strategy.
///
/// Example:
/// ```dart
/// class FetchDataAction extends PureExponentialBackoffAction<AppState> {
///   @override
///   Future<AppState> executeWithRetry(AppState state) async {
///     final data = await api.fetchData();
///     return state.copyWith(data: data);
///   }
/// }
/// ```
abstract class PureExponentialBackoffAction<T> extends PureRetryableAction<T> {
  /// Creates an exponential backoff action.
  const PureExponentialBackoffAction();

  /// Base delay for exponential backoff.
  Duration get baseDelay => const Duration(seconds: 1);

  /// Maximum delay between retries.
  Duration get maxDelay => const Duration(seconds: 60);

  /// Multiplier for exponential backoff.
  double get backoffMultiplier => 2;

  @override
  Duration get retryDelay {
    // This is calculated per attempt in onRetry
    return baseDelay;
  }

  @override
  void onRetry(int attempt, Object error) {
    final delay = Duration(
      milliseconds: (baseDelay.inMilliseconds * (backoffMultiplier * attempt))
          .clamp(0, maxDelay.inMilliseconds)
          .toInt(),
    );

    debugPrint(
      'Retrying $runtimeType (attempt $attempt/$maxRetries) '
      'after ${delay.inMilliseconds}ms: $error',
    );
  }
}

/// Extension methods for adding validation to stores.
extension ValidatedStoreExtension<T extends ValidatableState> on PureStore<T> {
  /// Validates the current state.
  ///
  /// Throws [StateValidationException] if validation fails.
  void validateState() {
    final validation = state.validate();
    if (validation.isInvalid) {
      throw StateValidationException(validation.errors);
    }
  }

  /// Checks if the current state is valid.
  bool get isStateValid => state.validate().isValid;

  /// Gets validation errors for the current state.
  List<String> get validationErrors => state.validate().errors;
}

/// Middleware that validates state after every action.
///
/// Example:
/// ```dart
/// store.addMiddlewareWithResult(validationMiddleware<MyState>());
/// ```
PureMiddlewareWithResult<T> validationMiddleware<T extends ValidatableState>({
  bool throwOnError = true,
  void Function(List<String> errors)? onValidationError,
}) {
  return (store, action, next) async {
    final newState = await next(action);

    final validation = newState.validate();
    if (validation.isInvalid) {
      onValidationError?.call(validation.errors);

      if (throwOnError) {
        throw StateValidationException(validation.errors);
      }
    }

    return newState;
  };
}
