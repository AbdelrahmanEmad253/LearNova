import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/features/profile/presentation/providers/reminder_settings_notifier.dart';

import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/theme/app_theme_provider.dart';
import 'package:learnova/features/profile/presentation/screens/about_us_screen.dart';
import 'package:learnova/features/profile/presentation/screens/profile_edits_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedHour = 0;
  int _selectedMinute = 0;
  bool _emailReminder = false;
  bool _pushNotification = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final reminderState = ref.watch(reminderSettingsNotifierProvider);

    if (!_initialized && !reminderState.isLoading) {
      _selectedHour = reminderState.time?.hour ?? 0;
      _selectedMinute = reminderState.time?.minute ?? 0;
      _emailReminder = reminderState.isEmail;
      _pushNotification = reminderState.isPush;
      _initialized = true;
    }

    ref.listen<ReminderSettingsState>(reminderSettingsNotifierProvider, (previous, next) {
      if (next.isSuccess && (previous == null || !previous.isSuccess)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.errorMessage}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppBackground(),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colors.textPrimary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildAccountCard(colors),
                        const SizedBox(height: 28),
                        _buildThemeSection(colors, isDarkMode),
                        const SizedBox(height: 28),
                        _buildNotificationsSection(colors),
                        const SizedBox(height: 28),
                        _buildAboutUsCard(colors),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Account Card ──
  Widget _buildAccountCard(AppColors colors) {
    return GestureDetector(
      onTap: () {
        AppRouter.push(context, const ProfileEditsScreen());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderWeak, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Account',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ── Theme & Appearance ──
  Widget _buildThemeSection(AppColors colors, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette_outlined, color: colors.textPrimary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Theme & Appearance',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderWeak, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Switch between ',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'Deep Space',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Technical void',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' color theme'),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).toggleTheme(value);
                },
                activeThumbColor: colors.primary,
                activeTrackColor: colors.primary.withValues(alpha: 0.38),
                inactiveThumbColor: colors.textSecondary,
                inactiveTrackColor: colors.borderWeak,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Notifications ──
  Widget _buildNotificationsSection(AppColors colors) {
    final reminderState = ref.watch(reminderSettingsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: colors.textPrimary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Notifications',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderWeak, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Studying Reminder label
              Text(
                'Studying Reminder:',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Time picker row
              _buildTimePicker(colors),
              const SizedBox(height: 22),

              // Reminder Methods
              Text(
                'Reminder Methods:',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildReminderMethod(
                colors,
                label: 'Email/Inbox message',
                value: _emailReminder,
                onChanged: (v) => setState(() => _emailReminder = v ?? false),
              ),
              const SizedBox(height: 8),
              _buildReminderMethod(
                colors,
                label: 'Push notification',
                value: _pushNotification,
                onChanged:
                    (v) => setState(() => _pushNotification = v ?? false),
              ),
              const SizedBox(height: 24),
              reminderState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Save',
                      onPressed: () {
                        ref.read(reminderSettingsNotifierProvider.notifier).saveReminderSettings(
                              time: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                              isEmail: _emailReminder,
                              isPush: _pushNotification,
                            );
                      },
                      backgroundColor: colors.primary,
                      textColor: Colors.white,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(AppColors colors) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: colors.isDark ? colors.borderWeak : colors.borderSoft.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CupertinoTheme(
        data: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          key: ValueKey(_initialized),
          mode: CupertinoDatePickerMode.time,
          initialDateTime: DateTime(0, 0, 0, _selectedHour, _selectedMinute),
          onDateTimeChanged: (DateTime newDateTime) {
            setState(() {
              _selectedHour = newDateTime.hour;
              _selectedMinute = newDateTime.minute;
            });
          },
        ),
      ),
    );
  }

  Widget _buildReminderMethod(
    AppColors colors, {
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colors.primary,
          activeTrackColor: colors.primary.withValues(alpha: 0.38),
          inactiveThumbColor: colors.textSecondary,
          inactiveTrackColor: colors.borderWeak,
        ),
      ],
    );
  }

  // ── About Us Card ──
  Widget _buildAboutUsCard(AppColors colors) {
    return GestureDetector(
      onTap: () {
        AppRouter.push(context, const AboutUsScreen());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderWeak, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'About Us',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
