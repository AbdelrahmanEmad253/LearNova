import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/widgets/app_top_bar.dart';
import 'package:learnova/features/weekly_challenge/data/models/challenge_schedule_model.dart';
import 'package:learnova/features/weekly_challenge/presentation/providers/weekly_challenge_provider.dart';
import 'package:learnova/features/weekly_challenge/presentation/widgets/weekly_challenge_badge.dart';
import 'package:learnova/features/weekly_challenge/presentation/widgets/weekly_challenge_chest.dart';
import 'package:learnova/features/weekly_challenge/presentation/widgets/weekly_challenge_countdown_pill.dart';

class WeeklyChallengeScreen extends ConsumerWidget {
  final double bottomInset;
  
  const WeeklyChallengeScreen({
    super.key,
    this.bottomInset = 0.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final state = ref.watch(weeklyChallengeProvider);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: topPadding),
                  SvgPicture.asset(
                    AppAssets.mapScrollTop,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.fitWidth,
                    colorFilter: const ColorFilter.mode(Color(0xFF03478E), BlendMode.srcIn),
                  ),
                  const SizedBox(height: 60),
                  
                  if (state.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (state.isFoundationTrack)
                    _buildFoundationMessage(colors)
                  else if (state.schedule != null) ...[
                    Transform.translate(
                      offset: const Offset(0, -38),
                      child: const WeeklyChallengeBadge(title: 'Week 1 Weekly Challenge'),
                    ),
                    WeeklyChallengeChest(state: state),
                    const SizedBox(height: 54),
                    _buildChallengeDashboard(context, state, colors),
                  ] else
                    const Center(child: Text('No challenge available', style: TextStyle(color: Colors.white))),
                    
                  SizedBox(height: bottomInset + 40),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SvgPicture.asset(
                AppAssets.mapFixedTop,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fitWidth,
                colorFilter: const ColorFilter.mode(Color(0xFF03478E), BlendMode.srcIn),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppTopBar(
              topPadding: topPadding,
              title: 'Weekly Challenge',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundationMessage(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderWeak),
        ),
        child: Column(
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Locked',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Weekly challenges will unlock after you complete the Foundation track. Keep going!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeDashboard(BuildContext context, WeeklyChallengeState state, AppColors colors) {
    final schedule = state.schedule!;
    final details = schedule.challengeDetails;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Challenge Info Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderWeak),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        details?.title ?? 'Weekly Challenge',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _buildStatusBadge(schedule.status, colors),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  details?.description ?? "Complete this week's challenge to earn bonus XP.",
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                
                // XP Rewards
                Row(
                  children: [
                    _buildXpPill(details?.xpRewardEasy ?? 20, colors),
                    const SizedBox(width: 8),
                    _buildXpPill(details?.xpRewardMid ?? 50, colors),
                    const SizedBox(width: 8),
                    _buildXpPill(details?.xpRewardHard ?? 100, colors),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action & Countdown Area
          _buildActionArea(schedule, state.countdownString, colors),
        ],
      ),
    );
  }

  Widget _buildXpPill(int xp, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            '$xp XP',
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppColors colors) {
    Color bgColor;
    Color textColor;
    String label = status.toUpperCase();
    
    switch (status) {
      case 'available':
      case 'started':
        bgColor = Colors.blue.withValues(alpha: 0.2);
        textColor = Colors.blue;
        break;
      case 'passed':
        bgColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green;
        break;
      case 'failed':
      case 'expired':
        bgColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        break;
      default:
        bgColor = colors.borderWeak;
        textColor = colors.textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionArea(ChallengeScheduleModel schedule, String countdown, AppColors colors) {
    final status = schedule.status;
    
    bool isActionable = status == 'available' || status == 'started';
    String actionText = status == 'started' ? 'Continue Challenge' : 'Start Weekly Challenge';
    
    return Column(
      children: [
        if (schedule.bestScore != null) ...[
          Text(
            'Your Score: ${schedule.bestScore!.toStringAsFixed(1)}',
            style: TextStyle(
              color: schedule.passed ? Colors.green : Colors.red,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isActionable ? () {
              // TODO: Navigate to challenge exam taking screen
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              disabledBackgroundColor: colors.borderWeak,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                color: isActionable ? ColorManager.uiPanelDark : colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        WeeklyChallengeCountdownPill(
          prefix: status == 'available' || status == 'started' 
              ? 'Closes in' 
              : 'Next in',
          countdown: countdown,
        ),
      ],
    );
  }
}
