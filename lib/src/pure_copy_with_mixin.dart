/// Mixin for state classes that support copyWith operations.
///
/// Provides a common interface for immutable state classes that need
/// to create modified copies of themselves.
///
/// Example:
/// ```dart
/// class CounterState with PureCopyWithMixin<CounterState> {
///   final int count;
///   CounterState({required this.count});
///
///   @override
///   CounterState copyWith({int? count}) {
///     return CounterState(count: count ?? this.count);
///   }
/// }
/// ```
mixin PureCopyWithMixin<T> {
  /// Creates a copy of this state with optional modifications.
  ///
  /// Implement this method to return a new instance with the specified changes.
  T copyWith();
}
