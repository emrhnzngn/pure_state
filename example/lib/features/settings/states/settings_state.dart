import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';

/// Settings state with validation.
class SettingsState with ValidatableState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.enableNotifications = true,
    this.autoSave = true,
    this.maxTasksPerUser = 100,
  });

  final ThemeMode themeMode;
  final bool enableNotifications;
  final bool autoSave;
  final int maxTasksPerUser;

  @override
  ValidationResult validate() {
    final errors = <String>[];

    if (maxTasksPerUser < 1) {
      errors.add('Max tasks must be at least 1');
    }

    if (maxTasksPerUser > 1000) {
      errors.add('Max tasks cannot exceed 1000');
    }

    return ValidationResult(errors);
  }

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? enableNotifications,
    bool? autoSave,
    int? maxTasksPerUser,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoSave: autoSave ?? this.autoSave,
      maxTasksPerUser: maxTasksPerUser ?? this.maxTasksPerUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'enableNotifications': enableNotifications,
      'autoSave': autoSave,
      'maxTasksPerUser': maxTasksPerUser,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      autoSave: json['autoSave'] as bool? ?? true,
      maxTasksPerUser: json['maxTasksPerUser'] as int? ?? 100,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          enableNotifications == other.enableNotifications &&
          autoSave == other.autoSave &&
          maxTasksPerUser == other.maxTasksPerUser;

  @override
  int get hashCode => Object.hash(
        themeMode,
        enableNotifications,
        autoSave,
        maxTasksPerUser,
      );

  @override
  String toString() =>
      'SettingsState(theme: $themeMode, notifications: $enableNotifications)';
}

