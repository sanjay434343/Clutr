import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:clutr/features/settings/providers/settings_provider.dart';
import 'package:clutr/core/services/notification_service.dart';
import 'package:clutr/features/cleanup/providers/media_provider.dart';
import 'package:clutr/core/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final mediaState = ref.watch(mediaProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine available folders
    List<String> availableFolders = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Movies',
    ];

    mediaState.whenData((mediaList) {
      if (mediaList != null) {
        final folders = mediaList
            .map((e) {
              final path = e['path'] as String?;
              if (path != null) {
                final parts = path.split('/');
                if (parts.length > 1) {
                  parts.removeLast(); // remove filename
                  return parts.join('/');
                }
              }
              return null;
            })
            .where((e) => e != null)
            .cast<String>()
            .toSet()
            .toList();

        if (folders.isNotEmpty) {
          availableFolders = folders;
        }
      }
    });

    for (final folder in settingsState.autoEmptyFolders) {
      if (folder.isNotEmpty && !availableFolders.contains(folder)) {
        availableFolders.add(folder);
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          _buildSectionHeader(context, 'Core Preferences'),
          _buildSettingsCard(
            context,
            children: [
              _buildSwitchTile(
                context,
                title: 'Temporary Delete',
                subtitle: 'Deleted items can be restored for a limited time',
                icon: HugeIcons.strokeRoundedDelete02,
                value: settingsState.isTemporaryDelete,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setTemporaryDelete(v),
              ),
              if (settingsState.isTemporaryDelete) ...[
                const Divider(height: 1, indent: 64),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedRecycle01,
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Auto-Empty Trash',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Permanently delete after', style: textTheme.bodyMedium),
                  trailing: DropdownButton<int>(
                    value: [7, 15, 30].contains(settingsState.trashAutoEmptyDays) 
                        ? settingsState.trashAutoEmptyDays 
                        : 30,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 Days')),
                      DropdownMenuItem(value: 15, child: Text('15 Days')),
                      DropdownMenuItem(value: 30, child: Text('30 Days')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).setTrashAutoEmptyDays(value);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingsCard(
            context,
            children: [
              _buildRadioTile<ThemeMode>(
                context,
                title: 'System Default',
                value: ThemeMode.system,
                groupValue: settingsState.themeMode,
                icon: HugeIcons.strokeRoundedSettings01,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setThemeMode(v!),
              ),
              const Divider(height: 1, indent: 64),
              _buildRadioTile<ThemeMode>(
                context,
                title: 'Light Mode',
                value: ThemeMode.light,
                groupValue: settingsState.themeMode,
                icon: HugeIcons.strokeRoundedSun01,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setThemeMode(v!),
              ),
              const Divider(height: 1, indent: 64),
              _buildRadioTile<ThemeMode>(
                context,
                title: 'Dark Mode',
                value: ThemeMode.dark,
                groupValue: settingsState.themeMode,
                icon: HugeIcons.strokeRoundedMoon01,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setThemeMode(v!),
              ),
              const Divider(height: 1, indent: 64),
              _buildSwitchTile(
                context,
                title: 'Material You Dynamic Colors',
                subtitle: 'Match app colors with your device wallpaper',
                icon: HugeIcons.strokeRoundedPaintBoard,
                value: settingsState.useDynamicColor,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setUseDynamicColor(v),
              ),
            ],
          ),

          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Smart Features'),
          _buildSettingsCard(
            context,
            children: [
              _buildSwitchTile(
                context,
                title: 'WhatsApp Cleaner',
                subtitle: 'Separate forwarded memes and voice notes',
                icon: HugeIcons.strokeRoundedMessageMultiple01,
                value: settingsState.whatsappCleaner,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setWhatsappCleaner(v),
              ),
            ],
          ),

          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Notifications & Automation'),
          _buildSettingsCard(
            context,
            children: [
              _buildSwitchTile(
                context,
                title: 'Periodic Cleanup Alerts',
                subtitle: 'Get notified when it\'s time to clean up',
                icon: HugeIcons.strokeRoundedNotification01,
                value: settingsState.notificationsEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setNotificationsEnabled(v),
              ),
              const Divider(height: 1, indent: 64),
              _buildSwitchTile(
                context,
                title: 'Space Limit Alert',
                subtitle: 'Notify me when total clutter exceeds a limit',
                icon: HugeIcons.strokeRoundedAlert02,
                value: settingsState.spaceLimitEnabled,
                onChanged: (v) => ref.read(settingsProvider.notifier).setSpaceLimitEnabled(v),
              ),
              if (settingsState.spaceLimitEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 72.0, right: 24.0, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alert at ${settingsState.spaceLimitGb.toStringAsFixed(1)} GB', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Slider(
                        value: settingsState.spaceLimitGb,
                        min: 1.0,
                        max: 20.0,
                        divisions: 38,
                        label: '${settingsState.spaceLimitGb.toStringAsFixed(1)} GB',
                        onChanged: (v) => ref.read(settingsProvider.notifier).setSpaceLimitGb(v),
                      ),
                    ],
                  ),
                ),

            ],
          ),

          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCalendar01,
                            color: colorScheme.onTertiaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Auto-Empty Schedule',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Run a background task to automatically clean specific folders and push a local notification with the space cleared.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Schedule Frequency',
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      value: [0, 7, 14, 30].contains(settingsState.autoEmptySchedule) ? settingsState.autoEmptySchedule : 0,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Off')),
                        DropdownMenuItem(value: 7, child: Text('Every 7 days')),
                        DropdownMenuItem(
                          value: 14,
                          child: Text('Every 14 days'),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text('Every 30 days'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .setAutoEmptySchedule(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Target Folders', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        height: 96,
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: availableFolders.map((path) {
                            final folderName = path.split('/').last;
                            final isSelected = settingsState.autoEmptyFolders.contains(path);
                            return FilterChip(
                              label: Text(folderName),
                              selected: isSelected,
                              onSelected: (_) {
                                ref.read(settingsProvider.notifier).toggleAutoEmptyFolder(path);
                              },
                              selectedColor: colorScheme.primaryContainer,
                              checkmarkColor: colorScheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Account'),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedLogout01,
                    color: colorScheme.onErrorContainer,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Log Out',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: Text('Sign out of your account', style: textTheme.bodyMedium),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await AuthService.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required dynamic icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: value
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: icon,
          color: value
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle, style: textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildRadioTile<T>(
    BuildContext context, {
    required String title,
    required T value,
    required T groupValue,
    required dynamic icon,
    required ValueChanged<T?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = value == groupValue;

    return RadioListTile<T>(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: icon,
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }
}
