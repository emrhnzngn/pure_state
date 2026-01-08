import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/pure_state.dart';

// Test Store
class TestStore extends PureStore<int> {
  TestStore() : super(0);
}

class IncrementAction extends PureAction<int> {
  @override
  int execute(int state) => state + 1;
}

void main() {
  testWidgets('PureDebugger shows floating button when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PureDebugger(
          child: SizedBox(),
        ),
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.bug_report), findsOneWidget);
  });

  testWidgets('PureDebugger opens panel on click', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PureDebugger(
          child: SizedBox(),
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Pure State Debugger'), findsOneWidget);
  });

  testWidgets('PureDebugger captures actions', (tester) async {
    final store = TestStore();

    // PureDebugger uses PureStore.addGlobalMiddleware when mounted
    // and removes it on dispose, so we need to ensure proper cleanup

    await tester.pumpWidget(
      MaterialApp(
        home: PureDebugger(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => store.dispatch(IncrementAction()),
                child: const Text('Increment'),
              );
            },
          ),
        ),
      ),
    );

    // Wait for PureDebugger to mount and attach middleware
    await tester.pump();

    await tester.tap(find.text('Increment'));
    await tester.pumpAndSettle();

    // Open debugger
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Check if action is logged
    expect(find.text('IncrementAction'), findsOneWidget);
    expect(find.text('Store: TestStore'), findsOneWidget);

    // Cleanup: Unmount widget to trigger dispose and remove global middleware
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();

    store.dispose();
  });
}
