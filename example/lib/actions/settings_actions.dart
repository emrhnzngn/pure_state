import 'dart:async';
import 'package:pure_state/pure_state.dart';
import 'package:flutter/material.dart';
import '../models/app_settings_model.dart';

/// Action to change theme mode
class ChangeThemeModeAction extends PureAction<AppSettingsState> {
  final ThemeMode themeMode;

  ChangeThemeModeAction(this.themeMode);

  @override
  FutureOr<AppSettingsState> execute(AppSettingsState currentState) {
    return currentState.copyWith(themeMode: themeMode);
  }
}

/// Action to change language
class ChangeLanguageAction extends PureAction<AppSettingsState> {
  final String language;

  ChangeLanguageAction(this.language);

  @override
  FutureOr<AppSettingsState> execute(AppSettingsState currentState) {
    return currentState.copyWith(language: language);
  }
}

/// Action to toggle notifications
class ToggleNotificationsAction extends PureAction<AppSettingsState> {
  @override
  FutureOr<AppSettingsState> execute(AppSettingsState currentState) {
    return currentState.copyWith(
      enableNotifications: !currentState.enableNotifications,
    );
  }
}

/// Action to toggle animations
class ToggleAnimationsAction extends PureAction<AppSettingsState> {
  @override
  FutureOr<AppSettingsState> execute(AppSettingsState currentState) {
    return currentState.copyWith(
      enableAnimations: !currentState.enableAnimations,
    );
  }
}

/// Action to set items per page
class SetItemsPerPageAction extends PureAction<AppSettingsState> {
  final int itemsPerPage;

  SetItemsPerPageAction(this.itemsPerPage);

  @override
  FutureOr<AppSettingsState> execute(AppSettingsState currentState) {
    return currentState.copyWith(itemsPerPage: itemsPerPage);
  }
}
