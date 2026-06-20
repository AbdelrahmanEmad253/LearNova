import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/widgets/avatar_display_widget.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/features/rank/domain/entities/rank_data.dart';
import 'package:learnova/core/constants/app_assets.dart';

import '../../../../core/theme/app_colors_theme.dart';

class RankEntryTile extends StatelessWidget {
  const RankEntryTile({super.key, required this.entry});

  final RankEntry entry;

  @override
  Widget build(BuildContext context) {
    final bool isPositive = entry.pointsChange >= 0;
    final colors = AppColors.of(context);

    return Row(
      children: [
        // Rank position number
        SizedBox(
          width: 22,
          child: Text(
            '${entry.position}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SvgPicture.asset(
          AppAssets.starIcon,
          width: 14,
          colorFilter: const ColorFilter.mode(
            ColorManager.primary,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 10),
        // Circular avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.borderSoft, width: 1.5),
          ),
          clipBehavior: Clip.hardEdge,
            child: AvatarDisplayWidget(
              avatarUrl: entry.avatarUrl,
              size: 40,
            ),
        ),
        const SizedBox(width: 12),
        // Name + tag
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                entry.userTag,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Points change indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive
                  ? Icons.arrow_drop_up_rounded
                  : Icons.arrow_drop_down_rounded,
              color:
                  isPositive ? ColorManager.primary : ColorManager.dangerBright,
              size: 22,
            ),
            Text(
              '${entry.pointsChange.abs()}',
              style: TextStyle(
                color:
                    isPositive ? ColorManager.primary : ColorManager.dangerBright,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
