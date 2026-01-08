import 'package:flutter/material.dart';

/// Type definition for a provider builder function.
///
/// Takes a child widget and returns a provider widget wrapping it.
typedef PureProviderBuilder = Widget Function(Widget child);

/// Widget that provides multiple stores to the widget tree.
///
/// Takes a list of provider builders and nests them to provide
/// multiple stores simultaneously.
///
/// Example:
/// ```dart
/// PureMultiProvider(
///   providers: [
///     (child) => PureProvider<CounterState>(store: counterStore, child: child),
///     (child) => PureProvider<UserState>(store: userStore, child: child),
///   ],
///   child: MyApp(),
/// )
/// ```
class PureMultiProvider extends StatelessWidget {
  /// Creates a new [PureMultiProvider].
  ///
  /// - [providers]: List of provider builder functions
  /// - [child]: The widget tree that will have access to all stores
  const PureMultiProvider({
    required this.providers,
    required this.child,
    super.key,
  });

  /// List of provider builder functions.
  ///
  /// Each builder takes a child and returns a provider widget.
  final List<PureProviderBuilder> providers;

  /// The widget tree that will have access to all stores.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var tree = child;
    for (final providerBuilder in providers.reversed) {
      tree = providerBuilder(tree);
    }

    return tree;
  }
}
