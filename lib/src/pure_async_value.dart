import 'dart:async';

import 'package:flutter/foundation.dart';

/// A sealed class representing the state of an asynchronous operation.
///
/// [AsyncValue] can be in one of three states:
/// - [AsyncData]: The operation completed successfully with data
/// - [AsyncLoading]: The operation is in progress
/// - [AsyncError]: The operation failed with an error
///
/// This pattern is inspired by Riverpod's AsyncValue but implemented
/// with zero external dependencies.
///
/// Example:
/// ```dart
/// AsyncValue<User> userState = AsyncLoading();
///
/// // Later, after API call
/// userState = AsyncData(user);
///
/// // Or on error
/// userState = AsyncError(error, stackTrace);
///
/// // Usage in widgets
/// userState.when(
///   data: (user) => Text(user.name),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
@immutable
sealed class AsyncValue<T> {
  const AsyncValue();

  /// Creates an [AsyncValue] in the loading state.
  const factory AsyncValue.loading() = AsyncLoading<T>;

  /// Creates an [AsyncValue] in the data state.
  const factory AsyncValue.data(T data) = AsyncData<T>;

  /// Creates an [AsyncValue] in the error state.
  const factory AsyncValue.error(Object error, [StackTrace? stackTrace]) =
      AsyncError<T>;

  /// Returns true if this is [AsyncData].
  bool get isData => this is AsyncData<T>;

  /// Returns true if this is [AsyncLoading].
  bool get isLoading => this is AsyncLoading<T>;

  /// Returns true if this is [AsyncError].
  bool get isError => this is AsyncError<T>;

  /// Returns true if this has data (either loading with previous data or fresh data).
  bool get hasData => this is AsyncData<T>;

  /// Returns the data if available, null otherwise.
  T? get dataOrNull {
    final self = this;
    if (self is AsyncData<T>) {
      return self.data;
    }
    return null;
  }

  /// Returns the error if available, null otherwise.
  Object? get errorOrNull {
    final self = this;
    if (self is AsyncError<T>) {
      return self.error;
    }
    return null;
  }

  /// Pattern matching method for handling all states.
  ///
  /// Example:
  /// ```dart
  /// asyncValue.when(
  ///   data: (value) => Text(value.toString()),
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (err, stack) => Text('Error: $err'),
  /// );
  /// ```
  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) {
    final self = this;
    if (self is AsyncData<T>) {
      return data(self.data);
    } else if (self is AsyncLoading<T>) {
      return loading();
    } else if (self is AsyncError<T>) {
      return error(self.error, self.stackTrace);
    }
    throw StateError('Unknown AsyncValue type: $runtimeType');
  }

  /// Pattern matching with optional handlers.
  ///
  /// Handlers that are not provided will fall back to [orElse].
  ///
  /// Example:
  /// ```dart
  /// asyncValue.maybeWhen(
  ///   data: (value) => Text(value.toString()),
  ///   orElse: () => Text('Loading or Error'),
  /// );
  /// ```
  R maybeWhen<R>({
    required R Function() orElse,
    R Function(T data)? data,
    R Function()? loading,
    R Function(Object error, StackTrace? stackTrace)? error,
  }) {
    final self = this;
    if (self is AsyncData<T> && data != null) {
      return data(self.data);
    } else if (self is AsyncLoading<T> && loading != null) {
      return loading();
    } else if (self is AsyncError<T> && error != null) {
      return error(self.error, self.stackTrace);
    }
    return orElse();
  }

  /// Maps the data value if this is [AsyncData].
  ///
  /// Other states are preserved unchanged.
  AsyncValue<R> map<R>(R Function(T data) mapper) {
    final self = this;
    if (self is AsyncData<T>) {
      return AsyncData(mapper(self.data));
    } else if (self is AsyncLoading<T>) {
      return AsyncLoading<R>();
    } else if (self is AsyncError<T>) {
      return AsyncError<R>(self.error, self.stackTrace);
    }
    throw StateError('Unknown AsyncValue type: $runtimeType');
  }

  /// Returns the data if available, otherwise returns [defaultValue].
  T dataOr(T defaultValue) {
    final self = this;
    if (self is AsyncData<T>) {
      return self.data;
    }
    return defaultValue;
  }

  /// Creates an [AsyncValue] from a [Future].
  ///
  /// The returned value starts as [AsyncLoading] and transitions to
  /// [AsyncData] or [AsyncError] based on the future result.
  ///
  /// Example:
  /// ```dart
  /// final asyncValue = await AsyncValue.guard(() => api.fetchUser());
  /// ```
  static Future<AsyncValue<T>> guard<T>(FutureOr<T> Function() future) async {
    try {
      final result = await future();
      return AsyncData(result);
    } on Exception catch (error, stackTrace) {
      return AsyncError(error, stackTrace);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    if (other is AsyncData<T> && this is AsyncData<T>) {
      return (this as AsyncData<T>).data == other.data;
    } else if (other is AsyncLoading<T> && this is AsyncLoading<T>) {
      return true;
    } else if (other is AsyncError<T> && this is AsyncError<T>) {
      final thisError = this as AsyncError<T>;
      return thisError.error == other.error;
    }

    return false;
  }

  @override
  int get hashCode {
    final self = this;
    if (self is AsyncData<T>) {
      return Object.hash('AsyncData', self.data);
    } else if (self is AsyncLoading<T>) {
      return 'AsyncLoading'.hashCode;
    } else if (self is AsyncError<T>) {
      return Object.hash('AsyncError', self.error);
    }
    return 0;
  }

  @override
  String toString() {
    return when(
      data: (value) => 'AsyncData<$T>(data: $value)',
      loading: () => 'AsyncLoading<$T>()',
      error: (err, stack) => 'AsyncError<$T>(error: $err)',
    );
  }
}

/// Represents a successful async operation with data.
@immutable
final class AsyncData<T> extends AsyncValue<T> {
  /// Creates an [AsyncData] with the given value.
  const AsyncData(this.data);

  /// The data value.
  final T data;
}

/// Represents an async operation in progress.
@immutable
final class AsyncLoading<T> extends AsyncValue<T> {
  /// Creates an [AsyncLoading] state.
  const AsyncLoading();
}

/// Represents a failed async operation with an error.
@immutable
final class AsyncError<T> extends AsyncValue<T> {
  /// Creates an [AsyncError] with the given error and optional stack trace.
  const AsyncError(this.error, [this.stackTrace]);

  /// The error object.
  final Object error;

  /// The stack trace associated with the error.
  final StackTrace? stackTrace;
}

/// Extension methods for working with [Future]s and [AsyncValue].
extension FutureAsyncValueExtension<T> on Future<T> {
  /// Converts this [Future] to an [AsyncValue].
  ///
  /// Returns [AsyncData] on success or [AsyncError] on failure.
  Future<AsyncValue<T>> toAsyncValue() {
    return AsyncValue.guard(() => this);
  }
}

/// Extension methods for working with [AsyncValue] in stores.
extension AsyncValueStoreExtension<T> on AsyncValue<T> {
  /// Creates a new [AsyncValue] by replacing its data with [newData].
  ///
  /// If this is not [AsyncData], returns this unchanged.
  AsyncValue<T> copyWithData(T newData) {
    if (this is AsyncData<T>) {
      return AsyncData(newData);
    }
    return this;
  }

  /// Updates the data if this is [AsyncData], otherwise returns this unchanged.
  AsyncValue<T> updateData(T Function(T data) updater) {
    final self = this;
    if (self is AsyncData<T>) {
      return AsyncData(updater(self.data));
    }
    return this;
  }
}
