import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/theme/app_colors.dart';

class WeeklyChallengeCountdownPill extends StatelessWidget {
  final String prefix;
  final String countdown;
  final bool isLocked;

  const WeeklyChallengeCountdownPill({
    super.key,
    required this.prefix,
    required this.countdown,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      decoration: BoxDecoration(
        color: isLocked ? colors.borderWeak : colors.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: isLocked ? [] : [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              prefix,
              style: TextStyle(
                color: isLocked ? colors.textPrimary : ColorManager.uiPanelDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (countdown.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                countdown,
                style: TextStyle(
                  color: isLocked ? colors.textPrimary : ColorManager.uiPanelDark,
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
