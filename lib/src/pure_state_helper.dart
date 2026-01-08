/// Extension methods for state serialization.
///
/// Provides default implementations that throw [UnimplementedError].
/// Override these methods in your state classes or use JSON-serializable.
extension PureStateHelper<T> on T {
  /// Converts the state to a map representation.
  ///
  /// Throws [UnimplementedError] by default.
  /// Override this method in your state class or use JSON-serializable.
  Map<String, dynamic> toMap() {
    throw UnimplementedError(
      'You must implement toMap() in your state class. '
      'Or make your state JSON-serializable.',
    );
  }

  /// Creates a state instance from a map representation.
  ///
  /// Throws [UnimplementedError] by default.
  /// Override this method in your state class or use JSON-serializable.
  T fromMap(Map<String, dynamic> map) {
    throw UnimplementedError(
      'You must implement fromMap() in your state class. '
      'Or make your state JSON-serializable.',
    );
  }
}

/// Extension methods for deep equality comparison.
///
/// Provides methods to compare objects deeply, including nested collections.
extension PureEqualityHelper on Object {
  /// Performs a deep equality check between this object and [other].
  ///
  /// Returns `true` if the objects are identical, equal using `==`, or
  /// if they are collections (List, Map, Set) with equal elements.
  /// Returns `false` otherwise.
  bool deepEquals(Object other) {
    if (identical(this, other)) return true;
    if (this == other) return true;

    final self = this;
    if (self is List && other is List) {
      return _listEquals(self, other);
    }

    if (self is Map && other is Map) {
      return _mapEquals(self, other);
    }

    if (self is Set && other is Set) {
      return _setEquals(self, other);
    }

    return false;
  }

  bool _listEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  bool _mapEquals(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  bool _setEquals(Set<dynamic> a, Set<dynamic> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a == b) return true;

    if (a is List && b is List) {
      return _listEquals(a, b);
    }

    if (a is Map && b is Map) {
      return _mapEquals(a, b);
    }

    if (a is Set && b is Set) {
      return _setEquals(a, b);
    }

    return false;
  }
}
