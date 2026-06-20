import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/app_top_bar.dart';
import 'package:learnova/features/rank/domain/entities/rank_data.dart';
import 'package:learnova/features/rank/presentation/providers/rank_providers.dart';
import 'package:learnova/features/rank/presentation/widgets/rank_entry_tile.dart';
import 'package:learnova/core/widgets/avatar_display_widget.dart';

class RankScreen extends ConsumerWidget {
  const RankScreen({super.key, this.bottomInset = 120});

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Size size = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final asyncData = ref.watch(rankDataProvider);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),

          Positioned.fill(
            child: asyncData.when(
              loading: () => const Center(child: CircularProgressIndicator(color: ColorManager.primary)),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: ColorManager.error))),
              data: (data) {
                final currentUser = data.leaderboard.firstWhere(
                  (e) => e.isCurrentUser,
                  orElse: () => RankEntry(
                    id: 'unknown',
                    name: 'You',
                    userTag: '#000000',
                    position: data.leaderboard.length + 1,
                    pointsChange: 0,
                    isCurrentUser: true,
                  ),
                );
                final others = data.leaderboard.where((e) => !e.isCurrentUser).toList();

                return CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: topPadding)),

                    // SVG wave
                    SliverToBoxAdapter(
                      child: SvgPicture.asset(
                        AppAssets.mapScrollTop,
                        width: size.width,
                        fit: BoxFit.fitWidth,
                        colorFilter: const ColorFilter.mode(Color(0xFF03478E), BlendMode.srcIn),
                      ),
                    ),

                    // ── Top students podium ──
                    SliverToBoxAdapter(
                      child: _TopStudentsPodium(
                        entries: data.leaderboard,
                        colors: colors,
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // ── Global Rank title ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Text(
                              'Global Rank',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // ── Current user card ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _CurrentUserCard(
                          position: data.currentUserPosition,
                          entry: currentUser,
                          colors: colors,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 18)),

                    // ── Leaderboard list ──
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.isDark
                                ? ColorManager.uiBlueDeep.withValues(alpha: 0.72)
                                : colors.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.borderSoft),
                          ),
                          child: Column(
                            children: [
                              ...List.generate(others.length, (i) {
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 14),
                                      child: RankEntryTile(entry: others[i]),
                                    ),
                                    if (i < others.length - 1)
                                      Divider(
                                        color: colors.borderWeak,
                                        height: 1,
                                        indent: 18,
                                        endIndent: 18,
                                      ),
                                  ],
                                );
                              }),
                              Divider(color: colors.borderSoft, height: 1),
                              InkWell(
                                onTap: () {},
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                          child: Divider(
                                              color: colors.borderWeak,
                                              indent: 18,
                                              endIndent: 8)),
                                      Text(
                                        'View full Leaderboard',
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Expanded(
                                          child: Divider(
                                              color: colors.borderWeak,
                                              indent: 8,
                                              endIndent: 18)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // ── Rank promotion section ──
                    SliverToBoxAdapter(
                      child: _RankPromotionSection(
                        currentUser: currentUser,
                        data: data,
                        colors: colors,
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(height: bottomInset + 24),
                    ),
                  ],
                );
              },
            ),
          ),

          // Fixed top SVG overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SvgPicture.asset(
                AppAssets.mapFixedTop,
                width: size.width,
                fit: BoxFit.fitWidth,
                colorFilter: const ColorFilter.mode(Color(0xFF03478E), BlendMode.srcIn),
              ),
            ),
          ),

          // AppTopBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppTopBar(
              topPadding: topPadding, 
              title: asyncData.asData?.value.screenTitle ?? 'Leaderboard'
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Students Hex Podium ──────────────────────────────────────────────────

class _TopStudentsPodium extends StatelessWidget {
  const _TopStudentsPodium({
    required this.entries,
    required this.colors,
  });

  final List<RankEntry> entries;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final top4 = entries.take(4).toList();
    if (top4.isEmpty) return const SizedBox.shrink();

    // Widths & heights keeping the hex aspect ratio (119:373)
    const hexWidths = [72.0, 88.0, 82.0, 66.0];
    const hexHeights = [226.0, 276.0, 257.0, 207.0];
    const offsets = [50.0, 0.0, 20.0, 70.0]; // vertical offset for podium

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(top4.length, (i) {
          return Padding(
            padding: EdgeInsets.only(top: offsets[i], left: i == 0 ? 0 : 2),
            child: _HexAvatar(
              entry: top4[i],
              hexWidth: hexWidths[i],
              hexHeight: hexHeights[i],
              isHighlighted: top4[i].isCurrentUser,
              colors: colors,
            ),
          );
        }),
      ),
    );
  }
}

class _HexAvatar extends StatelessWidget {
  const _HexAvatar({
    required this.entry,
    required this.hexWidth,
    required this.hexHeight,
    required this.isHighlighted,
    required this.colors,
  });

  final RankEntry entry;
  final double hexWidth;
  final double hexHeight;
  final bool isHighlighted;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final double avatarHeight = hexWidth * 3;
    final Color glowColor = isHighlighted ? ColorManager.primary : Colors.white.withValues(alpha: 0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: hexWidth,
          height: hexHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Native Pillar Background
              CustomPaint(
                painter: _PillarPainter(
                  isHighlighted: isHighlighted,
                  glowColor: glowColor,
                ),
              ),

              // 2. Avatar perfectly clipped to the top of the pillar
              Positioned(
                top: 0,
                left: 0,
                child: ClipPath(
                  clipper: _AvatarClipper(
                    avatarHeight: avatarHeight,
                    hexHeight: hexHeight,
                  ),
                  child: SizedBox(
                    width: hexWidth,
                    height: avatarHeight,
                    child: AvatarDisplayWidget(
                      avatarUrl: entry.avatarUrl,
                      size: avatarHeight,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // 3. Native Borders & Glows (drawn over the avatar)
              CustomPaint(
                painter: _PillarBorderPainter(
                  isHighlighted: isHighlighted,
                  glowColor: glowColor,
                  avatarHeight: avatarHeight,
                  hexHeight: hexHeight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SvgPicture.asset(
          AppAssets.starIcon,
          width: 18,
          colorFilter: const ColorFilter.mode(
            ColorManager.primary,
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }
}

// ── Native Pillar Geometry ───────────────────────────────────────────────────

Path _buildPillarPath(double w, double h) {
  final path = Path();
  path.moveTo(w * (58 / 119), h * (3.6 / 373));
  path.lineTo(w * (113 / 119), h * (41 / 373));
  path.lineTo(w * (113 / 119), h * (327 / 373));
  path.lineTo(w * (58 / 119), h * (364.4 / 373));
  path.lineTo(w * (3 / 119), h * (327 / 373));
  path.lineTo(w * (3 / 119), h * (41 / 373));
  path.close();
  return path;
}

class _PillarPainter extends CustomPainter {
  final bool isHighlighted;
  final Color glowColor;

  _PillarPainter({required this.isHighlighted, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = _buildPillarPath(w, h);

    // Pillar gradient
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, h * 0.4),
        Offset(w / 2, h),
        [const Color(0xFF03478E), const Color(0xFF01172E)],
      );
    canvas.drawPath(path, paint);

    // Default pillar border
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF03478E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PillarPainter oldDelegate) => false;
}

class _AvatarClipper extends CustomClipper<Path> {
  final double hexHeight;
  final double avatarHeight;
  _AvatarClipper({required this.hexHeight, required this.avatarHeight});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = hexHeight;
    final drop = h * (37.4 / 373);
    
    final path = Path();
    path.moveTo(w * (58 / 119), h * (3.6 / 373));
    path.lineTo(w * (113 / 119), h * (41 / 373));
    path.lineTo(w * (113 / 119), avatarHeight - drop);
    path.lineTo(w * (58 / 119), avatarHeight);
    path.lineTo(w * (3 / 119), avatarHeight - drop);
    path.lineTo(w * (3 / 119), h * (41 / 373));
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _AvatarClipper oldClipper) => 
      oldClipper.avatarHeight != avatarHeight || oldClipper.hexHeight != hexHeight;
}

class _PillarBorderPainter extends CustomPainter {
  final bool isHighlighted;
  final Color glowColor;
  final double hexHeight;
  final double avatarHeight;

  _PillarBorderPainter({
    required this.isHighlighted,
    required this.glowColor,
    required this.hexHeight,
    required this.avatarHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height; // This is hexHeight
    final drop = h * (37.4 / 373);

    // V-line separator at the bottom of the avatar
    final vLinePath = Path();
    vLinePath.moveTo(w * (3 / 119), avatarHeight - drop);
    vLinePath.lineTo(w * (58 / 119), avatarHeight);
    vLinePath.lineTo(w * (113 / 119), avatarHeight - drop);

    canvas.drawPath(
      vLinePath,
      Paint()
        ..color = isHighlighted ? glowColor : glowColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Highlighted global border
    if (isHighlighted) {
      final pillarPath = _buildPillarPath(w, h);

      canvas.drawPath(
        pillarPath,
        Paint()
          ..color = glowColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      canvas.drawPath(
        pillarPath,
        Paint()
          ..color = glowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PillarBorderPainter oldDelegate) => true;
}


// ── Rank Promotion Section ───────────────────────────────────────────────────

class _RankPromotionSection extends StatelessWidget {
  const _RankPromotionSection({
    required this.currentUser,
    required this.data,
    required this.colors,
  });

  final RankEntry currentUser;
  final RankData data;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Next rank promotion in:',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderSoft, width: 2),
            ),
            clipBehavior: Clip.hardEdge,
            child: AvatarDisplayWidget(
              avatarUrl: currentUser.avatarUrl,
              size: 68,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  data.currentRankName,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: colors.textPrimary,
                  size: 22,
                ),
              ),
              Flexible(
                child: Text(
                  data.nextRankName,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: data.xpProgress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: ColorManager.overlayMedium,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(ColorManager.primary),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: ColorManager.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${data.remainingXP} EXPs remaining',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorManager.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Current user highlighted card ────────────────────────────────────────────

class _CurrentUserCard extends StatelessWidget {
  const _CurrentUserCard({
    required this.position,
    required this.entry,
    required this.colors,
  });

  final int position;
  final RankEntry entry;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final bool isPositive = entry.pointsChange >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            '$position',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          SvgPicture.asset(
            AppAssets.starIcon,
            width: 14,
            colorFilter:
                const ColorFilter.mode(ColorManager.primary, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: colors.primary.withValues(alpha: 0.4)),
            ),
            clipBehavior: Clip.hardEdge,
            child: AvatarDisplayWidget(
              avatarUrl: entry.avatarUrl,
              size: 42,
            ),
          ),
          const SizedBox(width: 12),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color:
                    isPositive ? ColorManager.primary : ColorManager.dangerBright,
                size: 24,
              ),
              Text(
                '${entry.pointsChange.abs()}',
                style: TextStyle(
                  color: isPositive
                      ? ColorManager.primary
                      : ColorManager.dangerBright,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

