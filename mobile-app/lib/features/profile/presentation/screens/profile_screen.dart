import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/hex_avatar_panel.dart';
import 'package:learnova/core/widgets/avatar_display_widget.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/features/auth/presentation/screens/login_screen.dart';
import 'package:learnova/features/profile/domain/entities/profile_data.dart';
import 'package:learnova/features/profile/presentation/providers/profile_providers.dart';

import 'package:learnova/features/profile/presentation/screens/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.bottomInset = 120});

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileDataAsync = ref.watch(profileDataProvider);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: profileDataAsync.when(
          data: (profileData) => Stack(
            children: [
              const Positioned.fill(
                child: AppBackground(),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopProfileCard(context, profileData, colors),
                    const SizedBox(height: 18),
                    _buildJourneyCompletion(profileData, colors),
                    const SizedBox(height: 24),
                    _buildTimeStatus(profileData, colors),
                    const SizedBox(height: 26),
                    _buildInfoList(profileData, colors),
                    const SizedBox(height: 22),
                    _buildActivityStreak(profileData, colors),
                    const SizedBox(height: 30),
                    _buildPerksSection(profileData, colors),
                    const SizedBox(height: 30),
                    _buildBadgesSection(profileData, colors),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context, ref, colors),
                    SizedBox(height: bottomInset),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: ColorManager.primary)),
          error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: colors.textPrimary))),
        ),
      ),
    );
  }

  Widget _buildTopProfileCard(
      BuildContext context, ProfileData profileData, AppColors colors) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SizedBox(
          width: double.infinity,
          child: SvgPicture.asset(
            AppAssets.profileTop,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 60),
            Stack(
              alignment: Alignment.topCenter,
              children: [
                SvgPicture.asset(
                  AppAssets.profilePic,
                  width: 272,
                ),
                Column(
                  children: [
                    const SizedBox(height: 10),
                    HexAvatarPanel(
                      width: 118,
                      height: 108,
                      borderColor: colors.primary,
                      borderWidth: 2,
                      imageInset: 2.5,
                      child: AvatarDisplayWidget(
                        avatarUrl: profileData.avatarUrl,
                        size: 108,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profileData.username,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          AppAssets.starIcon,
                          width: 16,
                          colorFilter:
                              ColorFilter.mode(colors.primary, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profileData.rank,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 132,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.borderWeak,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            profileData.journeyCompletion.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 50,
          right: 24,
          child: GestureDetector(
            onTap: () {
              AppRouter.push(
                context,
                const SettingsScreen(),
                routeName: AppRoutePaths.profileSettings,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: colors.borderWeak, width: 1.5),
                borderRadius: BorderRadius.circular(9),
                color: colors.cardBackground.withValues(alpha: 0.8),
              ),
              child: Icon(
                Icons.settings_outlined,
                size: 18,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyCompletion(ProfileData profileData, AppColors colors) {
    final percentText = '${(profileData.journeyCompletion * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Journey completion',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.borderWeak,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: profileData.journeyCompletion.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                percentText,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatus(ProfileData profileData, AppColors colors) {
    final data = profileData.timeStatus;
    final maxValue =
        data.isEmpty ? 0.0 : data.map((e) => e.value).reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            'Time Status',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.borderWeak),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data
                  .map(
                    (item) => Expanded(
                      child: _buildTimeBar(
                          item: item, maxValue: maxValue, colors: colors),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBar(
      {required TimeStatusPoint item,
      required double maxValue,
      required AppColors colors}) {
    final ratio = maxValue == 0 ? 0.0 : (item.value / maxValue).clamp(0.0, 1.0);
    final isTotal = item.label == 'Total Time';
    final isLevel = item.label == 'Per Level';
    final Color barColor = isTotal
        ? ColorManager.softMint
        : isLevel
            ? ColorManager.uiBlue450
            : colors.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${_formatChartValue(item.value)} hr.s',
          style: TextStyle(
            color: barColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 145 * ratio,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              if (isTotal)
                BoxShadow(
                  color: barColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatChartValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  Widget _buildInfoList(ProfileData profileData, AppColors colors) {
    const icons = [
      Icons.emoji_events_outlined,
      Icons.school_outlined,
      Icons.military_tech_outlined,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: List.generate(profileData.infoItems.length, (index) {
          final item = profileData.infoItems[index];
          final icon = index < icons.length ? icons[index] : Icons.info_outline;
          return _buildInfoItem(icon, item.label, item.value, colors);
        }),
      ),
    );
  }

  Widget _buildInfoItem(
      IconData icon, String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: colors.textPrimary, size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: colors.textPrimary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStreak(ProfileData profileData, AppColors colors) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final active = profileData.weeklyActivity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Active for ',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                TextSpan(
                  text: '${profileData.activeStreak} Days',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' in a row!',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: colors.borderWeak),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                return Column(
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      days[index],
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    _buildWeeklyActivityDot(active[index], colors),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityDot(bool isActive, AppColors colors) {
    if (isActive) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primary,
        ),
        child: Icon(Icons.check,
            color: colors.isDark ? ColorManager.uiBlueToneStrong : Colors.white,
            size: 16),
      );
    }

    return CustomPaint(
      size: const Size(28, 28),
      painter: _DashedCirclePainter(color: colors.primary),
    );
  }

  Widget _buildPerksSection(ProfileData profileData, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perks',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: profileData.perks
                  .map(
                    (perk) => _buildPerkCard(
                      image: perk.imagePath,
                      name: perk.name,
                      sub: perk.subtitle,
                      colors: colors,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerkCard(
      {String? image,
      required String name,
      required String sub,
      required AppColors colors}) {
    final isUnlocked = image != null;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HexAvatarPanel(
            width: 88,
            height: 255,
            borderColor: colors.primary,
            borderWidth: 2,
            imageInset: 2.5,
            child: isUnlocked
                ? Image.asset(image, fit: BoxFit.cover)
                : Container(
                    color: colors.borderWeak,
                    alignment: Alignment.center,
                    child: Text(
                      '???',
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 24),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(ProfileData profileData, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badges',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: profileData.badges
                  .map(
                    (badge) => Padding(
                      padding: const EdgeInsets.only(right: 22),
                      child: _buildBadgeItem(
                          label: badge.label,
                          isLocked: badge.isLocked,
                          colors: colors),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, WidgetRef ref, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
            if (!context.mounted) {
              return;
            }

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
                settings: const RouteSettings(name: AppRoutePaths.login),
              ),
              (route) => false,
            );
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colors.primary, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: colors.primary,
          ),
          icon: const Icon(Icons.logout_rounded, size: 22),
          label: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildBadgeItem(
      {required String label,
      required bool isLocked,
      required AppColors colors}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          height: 108,
          child: isLocked
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.cardBackground,
                    border: Border.all(color: colors.borderWeak, width: 2.8),
                  ),
                  child: Center(
                    child: Text(
                      '???',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                  ),
                )
              : SvgPicture.asset(AppAssets.profileBadge, fit: BoxFit.contain),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 112,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: isLocked ? 14 : 13,
              fontWeight: isLocked ? FontWeight.w500 : FontWeight.w700,
              fontStyle: isLocked ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    const dashes = 16;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.4;

    for (var i = 0; i < dashes; i++) {
      if (i.isEven) {
        final startAngle = (2 * math.pi / dashes) * i;
        final sweepAngle = (2 * math.pi / dashes) * 0.55;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
