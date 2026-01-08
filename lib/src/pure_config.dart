/// Global configuration for PureState package.
///
/// Use this class to configure global behaviors such as performance optimizations,
/// logging, or default timeouts.
class PureStateConfig {
  /// Whether to enable the global HashCache for performance optimization.
  ///
  /// Defaults to `true`.
  ///
  /// When enabled, [PureEquality.shallowEq] uses a cached hash mechanism
  /// to speed up equality checks for immutable objects. This requires memory
  /// for the cache and background timers for cleanup.
  ///
  /// If set to `false`, [PureEquality.shallowEq] falls back to standard `==`
  /// checks after identity comparison, and the [HashCache] is not accessed.
  /// This is useful for simple apps where memory usage is a concern or where
  /// the overhead of caching outweighs the benefits.
  static bool enableHashCache = true;

  /// Resets all configuration to default values.
  static void reset() {
    enableHashCache = true;
  }
}
