import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';
import 'package:pure_state/src/multi_pure_provider.dart';
import 'package:pure_state/src/pure_listener.dart';
import 'models/todo_model.dart';
import 'models/app_settings_model.dart';
import 'stores/app_stores.dart';
import 'screens/todo_list_screen.dart';
import 'screens/settings_screen.dart';
import 'actions/todo_actions.dart';

void main() {
  // Optional: Global configuration
  // PureStateConfig.enableHashCache = false; // Disable for memory/simple apps
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppStores _stores;

  @override
  void initState() {
    super.initState();
    _stores = AppStores();
    // Load todos - first set loading, then load
    // Use executeBatch to ensure SetLoadingAction executes first
    // Dispatch SetLoadingAction first, then LoadTodosAction after a microtask
    // This ensures loading state is visible before async operation starts
    _stores.todoStore.dispatch(SetLoadingAction(true));
    Future.microtask(() {
      _stores.todoStore.dispatch(LoadTodosAction());
    });
  }

  @override
  void dispose() {
    _stores.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PureMultiProvider(
      providers: [
        (child) =>
            PureProvider<TodoState>(store: _stores.todoStore, child: child),
        (child) => PureProvider<AppSettingsState>(
          store: _stores.settingsStore,
          child: child,
        ),
      ],
      child: PureBuilder<AppSettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'Pure State Example',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            themeMode: settings.themeMode,
            home: const TodoListScreen(),
            routes: {'/settings': (context) => const SettingsScreen()},
            // Add listener for state changes (example of PureListener usage)
            builder: (context, child) {
              return PureListener<TodoState>(
                listener: (context, state) {
                  // Example: Show snackbar when todos are loaded
                  if (!state.isLoading && state.todos.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${state.todos.length} todo yüklendi'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                listenWhen: (previous, current) {
                  // Only listen when loading state changes from true to false
                  return previous.isLoading && !current.isLoading;
                },
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
