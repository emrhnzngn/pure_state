import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';
import '../models/app_settings_model.dart';
import '../actions/settings_actions.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: PureBuilder<AppSettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme mode section
              _SettingsSection(
                title: 'Tema',
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('Sistem'),
                    value: ThemeMode.system,
                    groupValue: state.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        final store = PureProvider.of<AppSettingsState>(
                          context,
                        );
                        store.dispatch(ChangeThemeModeAction(value));
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Açık'),
                    value: ThemeMode.light,
                    groupValue: state.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        final store = PureProvider.of<AppSettingsState>(
                          context,
                        );
                        store.dispatch(ChangeThemeModeAction(value));
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Koyu'),
                    value: ThemeMode.dark,
                    groupValue: state.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        final store = PureProvider.of<AppSettingsState>(
                          context,
                        );
                        store.dispatch(ChangeThemeModeAction(value));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Language section
              _SettingsSection(
                title: 'Dil',
                children: [
                  RadioListTile<String>(
                    title: const Text('Türkçe'),
                    value: 'tr',
                    groupValue: state.language,
                    onChanged: (value) {
                      if (value != null) {
                        final store = PureProvider.of<AppSettingsState>(
                          context,
                        );
                        store.dispatch(ChangeLanguageAction(value));
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('English'),
                    value: 'en',
                    groupValue: state.language,
                    onChanged: (value) {
                      if (value != null) {
                        final store = PureProvider.of<AppSettingsState>(
                          context,
                        );
                        store.dispatch(ChangeLanguageAction(value));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Preferences section
              _SettingsSection(
                title: 'Tercihler',
                children: [
                  SwitchListTile(
                    title: const Text('Bildirimler'),
                    subtitle: const Text('Todo bildirimlerini etkinleştir'),
                    value: state.enableNotifications,
                    onChanged: (value) {
                      final store = PureProvider.of<AppSettingsState>(context);
                      store.dispatch(ToggleNotificationsAction());
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Animasyonlar'),
                    subtitle: const Text('UI animasyonlarını etkinleştir'),
                    value: state.enableAnimations,
                    onChanged: (value) {
                      final store = PureProvider.of<AppSettingsState>(context);
                      store.dispatch(ToggleAnimationsAction());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Info section
              _SettingsSection(
                title: 'Bilgi',
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Pure State Example'),
                    subtitle: const Text('Kapsamlı örnek uygulama'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Versiyon'),
                    subtitle: const Text('1.0.0'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}
