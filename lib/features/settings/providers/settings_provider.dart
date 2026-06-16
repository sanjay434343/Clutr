import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:clutr/core/services/background_task_service.dart';
import 'package:clutr/core/services/background_cleaning_service.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsState {
  final bool isTemporaryDelete;
  final ThemeMode themeMode;
  final bool whatsappCleaner;
  final int autoEmptySchedule; // 0 for off, 1 for 30s test, 7, 14, 30 days
  final List<String> autoEmptyFolders;
  final double spaceLimitGb;
  final bool spaceLimitEnabled;
  final bool notificationsEnabled;
  final bool useDynamicColor;
  final int trashAutoEmptyDays;

  SettingsState({
    this.isTemporaryDelete = true,
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.whatsappCleaner = false,
    this.autoEmptySchedule = 0,
    this.autoEmptyFolders = const [],
    this.spaceLimitGb = 5.0,
    this.spaceLimitEnabled = false,
    this.notificationsEnabled = false,
    this.trashAutoEmptyDays = 30,
  });

  SettingsState copyWith({
    bool? isTemporaryDelete,
    ThemeMode? themeMode,
    bool? useDynamicColor,
    bool? whatsappCleaner,
    int? autoEmptySchedule,
    List<String>? autoEmptyFolders,
    double? spaceLimitGb,
    bool? spaceLimitEnabled,
    bool? notificationsEnabled,
    int? trashAutoEmptyDays,
  }) {
    return SettingsState(
      isTemporaryDelete: isTemporaryDelete ?? this.isTemporaryDelete,
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      whatsappCleaner: whatsappCleaner ?? this.whatsappCleaner,
      autoEmptySchedule: autoEmptySchedule ?? this.autoEmptySchedule,
      autoEmptyFolders: autoEmptyFolders ?? this.autoEmptyFolders,
      spaceLimitGb: spaceLimitGb ?? this.spaceLimitGb,
      spaceLimitEnabled: spaceLimitEnabled ?? this.spaceLimitEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      trashAutoEmptyDays: trashAutoEmptyDays ?? this.trashAutoEmptyDays,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const String _tempDeleteKey = 'settings_temp_delete';
  static const String _themeModeKey = 'settings_theme_mode';
  static const String _dynamicColorKey = 'settings_dynamic_color';
  static const String _whatsappKey = 'settings_whatsapp_cleaner';
  static const String _scheduleKey = 'settings_auto_empty_sched';
  static const String _folderKey = 'settings_auto_empty_folder';
  static const String _notificationsKey = 'settings_notifications_enabled';
  static const String _trashAutoEmptyKey = 'settings_trash_auto_empty_days';

  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isTempDelete = prefs.getBool(_tempDeleteKey) ?? true;
    final themeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final themeMode = ThemeMode.values[themeIndex];
    final dynamicColor = prefs.getBool(_dynamicColorKey) ?? true;
    final whatsapp = prefs.getBool(_whatsappKey) ?? false;
    final schedule = prefs.getInt(_scheduleKey) ?? 0;
    final folders = prefs.getStringList(_folderKey) ?? [];
    final spaceLimit = prefs.getDouble('settings_space_limit_gb') ?? 5.0;
    final spaceLimitEnabled = prefs.getBool('settings_space_limit_enabled') ?? false;
    final notifications = prefs.getBool(_notificationsKey) ?? false;
    final trashAutoEmptyDays = prefs.getInt(_trashAutoEmptyKey) ?? 30;

    state = state.copyWith(
      isTemporaryDelete: isTempDelete,
      themeMode: themeMode,
      useDynamicColor: dynamicColor,
      whatsappCleaner: whatsapp,
      autoEmptySchedule: schedule,
      autoEmptyFolders: folders,
      spaceLimitGb: spaceLimit,
      spaceLimitEnabled: spaceLimitEnabled,
      notificationsEnabled: notifications,
      trashAutoEmptyDays: trashAutoEmptyDays,
    );
  }

  Future<void> setTemporaryDelete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tempDeleteKey, value);
    state = state.copyWith(isTemporaryDelete: value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setUseDynamicColor(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicColorKey, value);
    state = state.copyWith(useDynamicColor: value);
  }

  Future<void> setWhatsappCleaner(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_whatsappKey, value);
    state = state.copyWith(whatsappCleaner: value);
  }

  Future<void> setAutoEmptySchedule(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scheduleKey, days);
    state = state.copyWith(autoEmptySchedule: days);
    
    await BackgroundCleaningService.scheduleAutoClean(days, state.autoEmptyFolders);
  }

  Future<void> toggleAutoEmptyFolder(String folder) async {
    final prefs = await SharedPreferences.getInstance();
    final currentFolders = List<String>.from(state.autoEmptyFolders);
    if (currentFolders.contains(folder)) {
      currentFolders.remove(folder);
    } else {
      currentFolders.add(folder);
    }
    await prefs.setStringList(_folderKey, currentFolders);
    state = state.copyWith(autoEmptyFolders: currentFolders);

    await BackgroundCleaningService.scheduleAutoClean(state.autoEmptySchedule, currentFolders);
  }

  Future<void> setSpaceLimitGb(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('settings_space_limit_gb', limit);
    state = state.copyWith(spaceLimitGb: limit);
  }

  Future<void> setSpaceLimitEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_space_limit_enabled', enabled);
    state = state.copyWith(spaceLimitEnabled: enabled);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    state = state.copyWith(notificationsEnabled: value);
    
    if (value) {
      await BackgroundTaskService().registerPeriodicTask();
    } else {
      await BackgroundTaskService().cancelAllTasks();
    }
  }

  Future<void> setTrashAutoEmptyDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_trashAutoEmptyKey, days);
    state = state.copyWith(trashAutoEmptyDays: days);
  }
}
