import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';
import '../states/settings_state.dart';

/// Update theme action with validation.
class UpdateThemeAction extends PureValidatedAction<SettingsState> {
  UpdateThemeAction(this.themeMode);

  final ThemeMode themeMode;

  @override
  SettingsState executeWithoutValidation(SettingsState state) {
    return state.copyWith(themeMode: themeMode);
  }
}

/// Toggle notifications action.
class ToggleNotificationsAction extends PureValidatedAction<SettingsState> {
  @override
  SettingsState executeWithoutValidation(SettingsState state) {
    return state.copyWith(
      enableNotifications: !state.enableNotifications,
    );
  }
}

/// Toggle auto-save action.
class ToggleAutoSaveAction extends PureValidatedAction<SettingsState> {
  @override
  SettingsState executeWithoutValidation(SettingsState state) {
    return state.copyWith(autoSave: !state.autoSave);
  }
}

/// Update max tasks action with validation.
class UpdateMaxTasksAction extends PureValidatedAction<SettingsState> {
  UpdateMaxTasksAction(this.maxTasks);

  final int maxTasks;

  @override
  SettingsState executeWithoutValidation(SettingsState state) {
    return state.copyWith(maxTasksPerUser: maxTasks);
  }

  // This will throw StateValidationException if maxTasks is < 1 or > 1000
}

