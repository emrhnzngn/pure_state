# Contributing to Pure State

First off, thank you for considering contributing to Pure State! 🎉

It's people like you that make Pure State such a great tool for the Flutter community.

## Table of Contents

- [Contributing to Pure State](#contributing-to-pure-state)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
    - [Our Pledge](#our-pledge)
  - [How Can I Contribute?](#how-can-i-contribute)
    - [Reporting Bugs](#reporting-bugs)
      - [Template for Bug Reports](#template-for-bug-reports)
    - [Documentation Style Guide](#documentation-style-guide)
  - [Development Setup](#development-setup)
    - [Prerequisites](#prerequisites)
    - [Setup Steps](#setup-steps)
    - [Project Structure](#project-structure)
  - [Testing](#testing)
    - [Running Tests](#running-tests)
    - [Writing Tests](#writing-tests)
    - [Test Coverage](#test-coverage)
  - [Release Process](#release-process)
  - [Questions?](#questions)
  - [Recognition](#recognition)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title** for the issue
* **Describe the exact steps which reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps**
* **Explain which behavior you expected to see instead and why**
* **Include screenshots or animated GIFs** if possible
* **Include your Flutter version** (`flutter --version`)
* **Include your Dart version** (`dart --version`)
* **Include device/emulator information**

#### Template for Bug Reports

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Create a store with '...'
2. Dispatch action '....'
3. Observe '....'

**Expected behavior**
A clear and concise description of what you expected to happen.

**Code sample**
```dart
// Your code here
```

**Environment:**
- Pure State version: [e.g., 1.0.0]
- Flutter version: [e.g., 3.10.0]
- Dart version: [e.g., 3.0.0]
- Platform: [e.g., iOS, Android, Web]

**Additional context**
Add any other context about the problem here.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a detailed description of the suggested enhancement**
* **Provide specific examples to demonstrate the use case**
* **Describe the current behavior** and **explain the desired behavior**
* **Explain why this enhancement would be useful** to most Pure State users

### Your First Code Contribution

Unsure where to begin? You can start by looking through these issues:

* `good-first-issue` - issues which should only require a few lines of code
* `help-wanted` - issues which are a bit more involved

### Pull Requests

1. **Fork the repo** and create your branch from `main`
2. **Make your changes** following our style guides
3. **Add tests** if you've added code that should be tested
4. **Ensure the test suite passes** (`flutter test`)
5. **Make sure your code lints** (`flutter analyze`)
6. **Update documentation** if you've changed APIs
7. **Write a good commit message**
8. **Issue the pull request**

#### Pull Request Process

1. Update the README.md with details of changes if applicable
2. Update the CHANGELOG.md following the Keep a Changelog format
3. The PR will be merged once you have the sign-off of at least one maintainer

## Style Guides

### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line
* Consider starting the commit message with an applicable emoji:
    * 🎉 `:tada:` - Initial commit
    * ✨ `:sparkles:` - New feature
    * 🐛 `:bug:` - Bug fix
    * 📝 `:memo:` - Documentation
    * 🎨 `:art:` - Improve structure/format
    * ⚡ `:zap:` - Performance improvement
    * ♻️ `:recycle:` - Refactor code
    * ✅ `:white_check_mark:` - Add tests
    * 🔒 `:lock:` - Fix security issues
    * ⬆️ `:arrow_up:` - Upgrade dependencies
    * ⬇️ `:arrow_down:` - Downgrade dependencies
    * 🔧 `:wrench:` - Configuration changes

**Example:**
```
✨ Add AsyncState wrapper for async operations

- Implement AsyncState<T> class with loading/data/error states
- Add .when() method for pattern matching
- Update documentation with AsyncState examples
- Add tests for all AsyncState scenarios

Closes #123
```

### Dart Style Guide

We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).

Key points:
* Use `dart format` to format your code
* Follow the 80-character line limit (flexible for readability)
* Use meaningful variable and function names
* Add documentation comments for public APIs
* Prefer `final` over `var` when possible
* Use trailing commas for better git diffs

**Example:**
```dart
/// Executes a batch of actions in order.
///
/// Actions are processed sequentially, maintaining their relative order
/// while still respecting priority levels within the batch.
///
/// Example:
/// ```dart
/// store.executeBatch([
///   IncrementAction(),
///   SaveAction(),
/// ]);
/// ```
void executeBatch(List<PureAction<T>> actions) {
  if (actions.isEmpty) return;
  
  for (final action in actions) {
    dispatch(action);
  }
}
```

### Documentation Style Guide

* Use `///` for documentation comments (not `//`)
* Start with a brief one-line summary
* Add a blank line before detailed description
* Include examples in code blocks
* Document parameters with `- [paramName]: description` format
* Document return values
* Document exceptions that might be thrown
* Link to related classes/methods using `[ClassName]` or `[methodName]`

**Example:**
```dart
/// Waits for the store to reach the expected state.
///
/// Returns a future that completes when the state matches [expectedState],
/// or throws a [TimeoutException] if the timeout is reached.
///
/// Example:
/// ```dart
/// await PureTestUtils.waitForState(
///   store,
///   UserState(isLoggedIn: true),
///   timeout: Duration(seconds: 5),
/// );
/// ```
///
/// - [store]: The store to watch for state changes
/// - [expectedState]: The expected state value to wait for
/// - [timeout]: Maximum time to wait before throwing [TimeoutException]
/// - [matcher]: Optional custom equality function for state comparison
///
/// Throws [TimeoutException] if the expected state is not reached within [timeout].
static Future<void> waitForState<T>(
  PureStore<T> store,
  T expectedState, {
  Duration timeout = const Duration(seconds: 5),
  bool Function(T, T)? matcher,
}) async {
  // Implementation...
}
```

## Development Setup

### Prerequisites

* Flutter SDK (3.10.0 or higher)
* Dart SDK (3.0.0 or higher)
* Git
* A code editor (VS Code, Android Studio, or IntelliJ IDEA)

### Setup Steps

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/emrhnzngn/pure_state.git
   cd pure_state
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run tests to verify setup**
   ```bash
   flutter test
   ```

4. **Run the example app**
   ```bash
   cd example
   flutter run
   ```

5. **Create a new branch for your feature**
   ```bash
   git checkout -b feature/my-awesome-feature
   ```

### Project Structure

```
pure_state/
├── lib/
│   ├── pure_state.dart           # Main export file
│   └── src/                       # Source code
│       ├── pure_action.dart       # Action system
│       ├── pure_store.dart        # Core store implementation
│       ├── pure_provider.dart     # Flutter widgets
│       ├── pure_selector.dart     # Selector with memoization
│       ├── pure_equality.dart     # Equality utilities
│       ├── pure_middlewares.dart  # Middleware implementations
│       ├── pure_persistence.dart  # Persistence layer
│       └── widgets/               # Additional widgets
├── test/                          # Unit tests
├── example/                       # Example application
├── docs/                          # Additional documentation
└── README.md                      # Main documentation
```

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/pure_store_test.dart

# Run tests in watch mode (if using a plugin)
flutter test --watch
```

### Writing Tests

* Every public API should have tests
* Aim for 80%+ code coverage
* Test both success and error cases
* Test edge cases and boundary conditions
* Use descriptive test names

**Example:**
```dart
group('PureStore', () {
  late PureStore<CounterState> store;

  setUp(() {
    store = PureStore<CounterState>(CounterState(count: 0));
  });

  tearDown(() {
    store.dispose();
  });

  test('initial state is correct', () {
    expect(store.state.count, 0);
  });

  test('dispatching action updates state', () async {
    store.dispatch(IncrementAction());
    
    await Future.delayed(Duration(milliseconds: 10));
    
    expect(store.state.count, 1);
  });

  test('handles errors gracefully', () async {
    final errors = <Object>[];
    final subscription = store.errorStream.listen(errors.add);

    store.dispatch(ErrorAction());
    
    await Future.delayed(Duration(milliseconds: 10));

    expect(errors, isNotEmpty);
    expect(errors.first.toString(), contains('Test Error'));

    await subscription.cancel();
  });
});
```

### Test Coverage

Generate and view coverage reports:

```bash
# Generate coverage
flutter test --coverage

# View HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Release Process

(For maintainers only)

1. **Update version** in `pubspec.yaml`
2. **Update CHANGELOG.md** with release notes
3. **Commit changes**
   ```bash
   git commit -am "🔖 Release version X.Y.Z"
   ```
4. **Create a git tag**
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
5. **Publish to pub.dev**
   ```bash
   flutter pub publish --dry-run  # Verify first
   flutter pub publish
   ```
6. **Create GitHub release** with changelog notes

## Questions?

Feel free to open an issue with your question or reach out to the maintainers directly.

## Recognition

Contributors will be recognized in:
* README.md contributors section
* Release notes
* GitHub contributors page

Thank you for contributing to Pure State! 🚀

