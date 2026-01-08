import 'package:flutter/material.dart';

/// App settings state containing user preferences.
class AppSettingsState {
  final ThemeMode themeMode;
  final String language;
  final bool enableNotifications;
  final bool enableAnimations;
  final int itemsPerPage;

  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.language = 'tr',
    this.enableNotifications = true,
    this.enableAnimations = true,
    this.itemsPerPage = 20,
  });

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? enableNotifications,
    bool? enableAnimations,
    int? itemsPerPage,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          language == other.language &&
          enableNotifications == other.enableNotifications &&
          enableAnimations == other.enableAnimations &&
          itemsPerPage == other.itemsPerPage;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      language.hashCode ^
      enableNotifications.hashCode ^
      enableAnimations.hashCode ^
      itemsPerPage.hashCode;
}
