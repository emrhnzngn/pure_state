/// Pure State Management Library
///
/// A lightweight, performant state management solution for Flutter applications.
///
/// This library provides:
/// - [PureStore]: Core store for managing application state
/// - [PureAction]: Base class for state-changing actions
/// - [PureProvider]: Widget for providing stores to the widget tree
/// - [PureBuilder]: Widget that rebuilds on state changes
/// - [PureSelector]: Widget that rebuilds only when selected state changes
/// - [PureListener]: Widget for side effects on state changes
/// - Middleware support for logging, persistence, and more
/// - Priority-based action queue
/// - Efficient equality checks and memoization
///
/// Example:
/// ```dart
/// // Define state
/// class CounterState {
///   final int count;
///   CounterState({required this.count});
///   CounterState copyWith({int? count}) => CounterState(count: count ?? this.count);
/// }
///
/// // Define action
/// class IncrementAction extends PureAction<CounterState> {
///   @override
///   CounterState execute(CounterState state) {
///     return state.copyWith(count: state.count + 1);
///   }
/// }
///
/// // Create store
/// final store = PureStore<CounterState>(CounterState(count: 0));
///
/// // Use in widget
/// PureProvider<CounterState>(
///   store: store,
///   child: PureBuilder<CounterState>(
///     builder: (context, state) => Text('Count: ${state.count}'),
///   ),
/// )
/// ```
library;

import 'package:pure_state/pure_state.dart';

export 'src/multi_pure_provider.dart';
export 'src/pure_action.dart';
export 'src/pure_action_enhancements.dart';
export 'src/pure_async_value.dart';
export 'src/pure_auto_dispose_store.dart';
export 'src/pure_batch_extension.dart';
export 'src/pure_computed_selector.dart';
export 'src/pure_config.dart';
export 'src/pure_create_provider.dart';
export 'src/pure_devtools.dart';
export 'src/pure_equality.dart';
export 'src/pure_error_builder.dart';
export 'src/pure_extensions.dart';
// Note: pure_flutter_test_utils.dart is not exported as it requires flutter_test
// which is only available in dev_dependencies. Import it directly if needed:
// import 'package:pure_state/src/pure_flutter_test_utils.dart';
export 'src/pure_listener.dart';
export 'src/pure_middlewares.dart';
export 'src/pure_performance_profiler.dart';
export 'src/pure_persistence.dart';
export 'src/pure_provider.dart';
export 'src/pure_selector.dart';
export 'src/pure_state_annotations.dart';
export 'src/pure_state_helper.dart';
export 'src/pure_store.dart';
export 'src/pure_store_container.dart';
export 'src/pure_store_family.dart';
export 'src/pure_test_utils.dart';
export 'src/pure_value.dart';
export 'src/widgets/pure_debugger.dart';
export 'src/widgets/pure_multi_selector.dart';
