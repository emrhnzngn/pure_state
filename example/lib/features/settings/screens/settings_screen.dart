import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';

import '../actions/settings_actions.dart';
import '../states/settings_state.dart';

/// Settings screen demonstrating state validation.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  PureSelector<SettingsState, ThemeMode>(
                    store: PureProvider.of<SettingsState>(context),
                    selector: (state) => state.themeMode,
                    builder: (context, themeMode) {
                      return SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.auto_mode),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          final store =
                              PureProvider.of<SettingsState>(context);
                          store.dispatch(
                            UpdateThemeAction(selection.first),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notifications
          Card(
            child: PureBuilder<SettingsState>(
              builder: (context, settings) {
                return SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle:
                      const Text('Receive updates about your tasks'),
                  value: settings.enableNotifications,
                  onChanged: (_) {
                    final store = PureProvider.of<SettingsState>(context);
                    store.dispatch(ToggleNotificationsAction());
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Auto-save
          Card(
            child: PureBuilder<SettingsState>(
              builder: (context, settings) {
                return SwitchListTile(
                  title: const Text('Auto-save'),
                  subtitle:
                      const Text('Automatically save changes'),
                  value: settings.autoSave,
                  onChanged: (_) {
                    final store = PureProvider.of<SettingsState>(context);
                    store.dispatch(ToggleAutoSaveAction());
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Max Tasks (with validation)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Limits',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maximum tasks per user (1-1000)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  PureBuilder<SettingsState>(
                    builder: (context, settings) {
                      return Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value:
                                  settings.maxTasksPerUser.toDouble(),
                              min: 1,
                              max: 1000,
                              divisions: 100,
                              label:
                                  settings.maxTasksPerUser.toString(),
                              onChanged: (value) {
                                final store =
                                    PureProvider.of<SettingsState>(context);
                                try {
                                  store.dispatch(
                                    UpdateMaxTasksAction(value.toInt()),
                                  );
                                } catch (e) {
                                  // Show validation error
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              settings.maxTasksPerUser.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Validation status
                  PureBuilder<SettingsState>(
                    builder: (context, settings) {
                      final validation = settings.validate();
                      if (validation.isInvalid) {
                        return Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validation.errors.first,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Pure State Features',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('✅ State Validation'),
                const Text('✅ Automatic middleware'),
                const Text('✅ Type-safe actions'),
                const Text('✅ Real-time updates'),
                const SizedBox(height: 8),
                Text(
                  'Try setting invalid values (< 1 or > 1000)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

