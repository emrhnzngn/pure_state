import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';

import 'core/stores/app_stores.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/states/user_state.dart';
import 'features/tasks/screens/home_screen.dart';
import 'features/tasks/states/task_state.dart';
import 'features/settings/states/settings_state.dart';

void main() {
  // Initialize stores
  final stores = AppStores();

  runApp(PureStateExampleApp(stores: stores));
}

/// Main app with Pure State providers.
class PureStateExampleApp extends StatelessWidget {
  const PureStateExampleApp({required this.stores, super.key});

  final AppStores stores;

  @override
  Widget build(BuildContext context) {
    return PureMultiProvider(
      providers: [
        (child) =>
            PureProvider<UserState>(store: stores.userStore, child: child),
        (child) =>
            PureProvider<TaskState>(store: stores.taskStore, child: child),
        (child) => PureProvider<SettingsState>(
          store: stores.settingsStore,
          child: child,
        ),
      ],
      child: PureBuilder<SettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'Pure State Example',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
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
                seedColor: Colors.deepPurple,
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
            home: PureBuilder<UserState>(
              builder: (context, userState) {
                return userState.isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
