# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-08

### 🎉 Initial Release

#### Added
- **Core State Management**
  - `PureStore`: High-performance state container with action queue system
  - `PureAction`: Base class for state-modifying actions
  - `SimpleUpdateAction` and `NamedAction` for low-boilerplate updates
  - Synchronous and asynchronous action support

- **Performance Optimizations**
  - Sampling equality checks for large collections (O(1) complexity)
  - Adaptive batching system to prevent UI freezing
  - Priority queue for action ordering (high-priority actions first)
  - LRU cache for selector memoization
  - Hash cache system (local and global) for efficient equality checks
  - Configurable batch processing parameters

- **Flutter Widgets**
  - `PureProvider`: InheritedWidget for store injection
  - `PureBuilder`: Reactive widget that rebuilds on state changes
  - `PureSelector`: Selective rebuilds with memoization
  - `PureListener`: Side-effect handler without rebuilds
  - `PureMultiProvider`: Multi-store provider support
  - `PureMultiSelector`: Select from multiple stores simultaneously
  - `PureCreateProvider`: Lazy store creation

- **Advanced Features**
  - Action debouncing and throttling
  - Action timeout handling with fallback states
  - Action priority system (0-100+)
  - State history for undo/redo functionality
  - State snapshot and restoration
  - Multi-store management with `StoreContainer`
  - Cross-store dependencies with `watch<T>()` and `read<T>()`

- **Middleware System**
  - Local middleware support per store
  - Global middleware support across all stores
  - Middleware with result transformation
  - `PureLogger`: Built-in logging middleware
  - `PureThrottle`: Throttle middleware
  - `PureDebounce`: Debounce middleware
  - `pureDevToolsMiddleware`: Flutter DevTools integration

- **Persistence**
  - `PureStorage`: Abstract storage interface
  - `PureMemoryStorage`: In-memory storage implementation
  - `purePersistenceMiddleware`: Auto-save middleware
  - State hydration and rehydration support
  - JSON serialization helpers

- **Debugging Tools**
  - `PureDebugger`: Floating debug panel widget
  - Action history tracking
  - Execution time monitoring
  - Error tracking and display
  - Global error handler support
  - Error stream for custom error handling

- **Testing Utilities**
  - `PureTestUtils.waitForState`: Wait for specific state
  - `PureTestUtils.waitForCondition`: Wait for state condition
  - `PureTestUtils.captureStates`: Capture state changes over time
  - `PureTestUtils.waitForAction`: Execute action and wait for result

- **Configuration**
  - `PureStateConfig`: Global configuration options
  - Configurable hash cache behavior
  - Adaptive batch delay configuration
  - Custom equality functions support

- **Documentation**
  - Comprehensive README with examples
  - Inline documentation for all public APIs
  - Example Todo application demonstrating best practices
  - Migration guides (coming soon)

#### Technical Highlights
- **Zero external dependencies** (only Flutter SDK required)
- **Type-safe** API throughout
- **Memory efficient** with automatic cleanup
- **Production-ready** with extensive error handling
- **~6,400 lines** of well-documented Dart code
- **Comprehensive test coverage** with 9 test suites

### Architecture Patterns Supported
- Flux/Redux-like unidirectional data flow
- Event-driven architecture with actions
- Dependency injection via StoreContainer
- Middleware/interceptor pattern
- Observer pattern for state changes
- Command pattern for actions

### Performance Characteristics
- O(1) equality checks for large collections via sampling
- Sub-millisecond action dispatch overhead
- Adaptive frame-rate-aware batching
- Minimal memory footprint with LRU caching
- No unnecessary rebuilds with selective updates

---

## [Unreleased]

### Planned Features
- Code generation support via `build_runner`
- `AsyncState` wrapper class for async operations
- Family pattern for parametric providers
- Effect system for reactive side effects
- VS Code extension with snippets
- Flutter DevTools extension
- Performance profiler API
- Additional middleware examples

---

## How to Upgrade

### From 0.0.1 to 1.0.0
This is the first production release. If you were using the pre-release version:

1. Update your `pubspec.yaml`:
   ```yaml
   dependencies:
     pure_state: ^1.0.0
   ```

2. Run `flutter pub get`

3. No breaking changes - all APIs are backward compatible

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

---

## License

MIT License - see [LICENSE](LICENSE) file for details.
