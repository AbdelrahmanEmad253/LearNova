import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/features/content/domain/entities/content_destination.dart';
import 'package:learnova/features/content/data/repositories/audio_playback_repository_impl.dart';
import 'package:learnova/features/content/domain/entities/content_item_payload.dart';
import 'package:learnova/features/content/presentation/providers/content_providers.dart';
import 'package:learnova/features/content/presentation/controllers/audio_study_player_controller.dart';
import 'package:learnova/features/content/presentation/screens/content_document_reader.dart';
import 'package:learnova/features/content/presentation/screens/content_video_player.dart';
import 'package:learnova/features/home/presentation/providers/home_providers.dart';

class AudioStudyPlayerScreen extends ConsumerStatefulWidget {
  final ContentItemPayload item;
  final List<ContentItemPayload>? moduleItems;
  final int? moduleIndex;
  final String? moduleId;

  const AudioStudyPlayerScreen({
    super.key,
    required this.item,
    this.moduleItems,
    this.moduleIndex,
    this.moduleId,
  });

  @override
  ConsumerState<AudioStudyPlayerScreen> createState() =>
      _AudioStudyPlayerScreenState();
}

class _AudioStudyPlayerScreenState extends ConsumerState<AudioStudyPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AudioStudyPlayerController _controller;

  final List<String> _lyrics = const [
    'Isn\'t it rich?',
    'Are we a pair?',
    'Me here at last on the ground, you in mid air',
    'Send in the Clowns',
    'Isn\'t it bliss?',
    'Don\'t you approve?',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );

    _controller = AudioStudyPlayerController(
      repository: AudioPlaybackRepositoryImpl(),
      rawDuration: widget.item.meta,
      mediaUrl: widget.item.mediaUrl,
    )..addListener(_syncRotationWithPlayback);

    // Load the real audio source if a URL is available.
    _controller.initialize();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  ContentItemPayload? _nextItemInModule() {
    final List<ContentItemPayload>? items = widget.moduleItems;
    final int? index = widget.moduleIndex;
    if (items == null || index == null) {
      return null;
    }

    final int nextIndex = index + 1;
    if (nextIndex < 0 || nextIndex >= items.length) {
      return null;
    }
    return items[nextIndex];
  }

  void _onFinishPressed() {
    if (widget.moduleId != null) {
      ref.read(moduleProgressProvider.notifier).markItemCompleted(
            moduleId: widget.moduleId!,
            itemId: widget.item.id,
          );
    }

    final ContentItemPayload? nextItem = _nextItemInModule();
    if (nextItem == null) {
      AppRouter.pop(context);
      return;
    }

    final ContentDestination destination =
        ref.read(resolveContentDestinationUseCaseProvider)(nextItem);

    if (destination == ContentDestination.audio) {
      AppRouter.pushReplacement(
        context,
        AudioStudyPlayerScreen(
          item: nextItem,
          moduleItems: widget.moduleItems,
          moduleIndex: (widget.moduleIndex ?? 0) + 1,
          moduleId: widget.moduleId,
        ),
        routeName: AppRoutePaths.contentAudioPlayer,
      );
      return;
    }

    if (destination == ContentDestination.video) {
      AppRouter.pushReplacement(
        context,
        VideoPlayerPlaceholderScreen(
          item: nextItem,
          moduleItems: widget.moduleItems,
          moduleIndex: (widget.moduleIndex ?? 0) + 1,
          moduleId: widget.moduleId,
        ),
        routeName: AppRoutePaths.contentVideoPlayer,
      );
      return;
    }

    AppRouter.pushReplacement(
      context,
      DocumentReaderPlaceholderScreen(
        item: nextItem,
        moduleItems: widget.moduleItems,
        moduleIndex: (widget.moduleIndex ?? 0) + 1,
        moduleId: widget.moduleId,
      ),
      routeName: AppRoutePaths.contentDocumentReader,
    );
  }

  void _syncRotationWithPlayback() {
    if (_controller.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
      return;
    }

    if (_rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncRotationWithPlayback);
    _controller.dispose();
    _rotationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;
            final double sx = width / 412;
            final double sy = height / 917;
            final double ss = math.min(sx, sy);

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final bool showLyrics = _controller.showLyrics;
                final double artTop = showLyrics ? 96 : 180;
                final double cardTop = showLyrics ? 341 : 158;
                final double cardOpacity = showLyrics ? 0.5 : 0.75;
                final double discSize = 316 * ss;
                final ContentItemPayload? nextItem = _nextItemInModule();
                final bool hasFinished =
                    _controller.totalDuration > Duration.zero &&
                        _controller.position >= _controller.totalDuration;
                final String displayTitle = widget.item.title.trim().isEmpty
                    ? 'Linear Algebra (Vectors)'
                    : widget.item.title.trim();

                return Stack(
                  children: [
                    Positioned(
                      left: -11.891 * sx,
                      bottom: -11.98 * sy,
                      width: 444.862 * sx,
                      height: 319.383 * sy,
                      child: IgnorePointer(
                        child: SvgPicture.asset(
                          AppAssets.contentWaveBottom,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      left: 32 * sx,
                      top: cardTop * sy,
                      width: 348 * sx,
                      height: 360 * sy,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 320),
                        opacity: cardOpacity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ColorManager.secondary,
                            borderRadius: BorderRadius.circular(16 * ss),
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      left: (width - discSize) / 2,
                      top: artTop * sy,
                      width: discSize,
                      height: discSize,
                      child: RotationTransition(
                        turns: _rotationController,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorManager.accentCyan,
                          ),
                          child: Image.asset(
                            AppAssets.audioDisc,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24 * sx,
                      top: 22 * sy,
                      child: InkWell(
                        onTap: () => AppRouter.pop(context),
                        borderRadius: BorderRadius.circular(20 * ss),
                        child: Container(
                          width: 40 * ss,
                          height: 40 * ss,
                          decoration: BoxDecoration(
                            color:
                                colors.cardBackground.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.borderWeak.withValues(alpha: 0.7),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: colors.textPrimary,
                            size: 18 * ss,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 86 * sx,
                      top: 542 * sy,
                      width: 240 * sx,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: showLyrics ? 0 : 1,
                        child: Text(
                          displayTitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 32 * ss,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color:
                                    colors.textPrimary.withValues(alpha: 0.35),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 76 * sx,
                      top: 733 * sy,
                      width: 262 * sx,
                      height: 29 * sy,
                      child: _TimelineWave(
                        progress: _controller.progress,
                        onScrub: _controller.scrubToRatio,
                      ),
                    ),
                    Positioned(
                      left: 32 * sx,
                      top: 736 * sy,
                      child: Text(
                        _controller.positionLabel,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16 * ss,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 352 * sx,
                      top: 736 * sy,
                      child: Text(
                        _controller.totalDurationLabel,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16 * ss,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 32 * sx,
                      top: 806 * sy,
                      child: _SubtitlesToggle(
                        size: 25 * ss,
                        isActive: showLyrics,
                        onTap: _controller.toggleLyrics,
                      ),
                    ),
                    Positioned(
                      left: 352 * sx,
                      top: 806 * sy,
                      child: _RepeatToggle(
                        size: 25 * ss,
                        onTap: _controller.restart,
                      ),
                    ),
                    if (hasFinished)
                      Positioned(
                        left: 96 * sx,
                        top: 790 * sy,
                        width: 220 * sx,
                        height: 54 * sy,
                        child: FilledButton.icon(
                          onPressed: _onFinishPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.buttonForeground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14 * ss),
                            ),
                          ),
                          icon: Icon(Icons.check_circle_outline,
                              color: colors.buttonForeground),
                          label: Text(
                            nextItem == null ? 'Finish' : 'Finish & Next',
                            style: TextStyle(
                              fontSize: 18 * ss,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        left: 113 * sx,
                        top: 786 * sy,
                        child: Row(
                          children: [
                            _SkipButton(
                              size: 44 * ss,
                              isForward: false,
                              onTap: () => _controller.seekBy(
                                const Duration(seconds: -5),
                              ),
                            ),
                            SizedBox(width: 16 * sx),
                            _PlayPauseButton(
                              size: 66 * ss,
                              isPlaying: _controller.isPlaying,
                              isLoading: _controller.isLoading,
                              onTap: _controller.togglePlayPause,
                            ),
                            SizedBox(width: 16 * sx),
                            _SkipButton(
                              size: 44 * ss,
                              isForward: true,
                              onTap: () => _controller.seekBy(
                                const Duration(seconds: 5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      left: 48 * sx,
                      top: 365 * sy,
                      width: 297 * sx,
                      height: 320 * sy,
                      child: IgnorePointer(
                        ignoring: !showLyrics,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 240),
                          opacity: showLyrics ? 1 : 0,
                          child: _LyricsScrollable(
                            lyrics: _lyrics,
                            fontScale: ss,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LyricsScrollable extends StatelessWidget {
  final List<String> lyrics;
  final double fontScale;

  const _LyricsScrollable({required this.lyrics, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: lyrics.length,
        separatorBuilder: (_, __) => SizedBox(height: 16 * fontScale),
        itemBuilder: (context, index) {
          return _LyricLine(
            text: lyrics[index],
            isPrimary: index == 0,
            fontScale: fontScale,
          );
        },
      ),
    );
  }
}

class _LyricLine extends StatelessWidget {
  final String text;
  final bool isPrimary;
  final double fontScale;

  const _LyricLine({
    required this.text,
    required this.isPrimary,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final Color color = isPrimary ? colors.textPrimary : colors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '-',
          style: TextStyle(
            color: color,
            fontSize: 16 * fontScale,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 9 * fontScale),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16 * fontScale,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  final double size;
  final bool isForward;
  final VoidCallback onTap;

  const _SkipButton({
    required this.size,
    required this.isForward,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.cardBackground.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: size * 0.17,
              child: Icon(
                isForward ? Icons.refresh_rounded : Icons.refresh,
                size: size * 0.5,
                color: colors.buttonForeground,
              ),
            ),
            Positioned(
              bottom: size * 0.08,
              child: Text(
                '5',
                style: TextStyle(
                  color: colors.buttonForeground,
                  fontSize: size * 0.255,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final double size;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlayPauseButton({
    required this.size,
    required this.isPlaying,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(0.5, 0.5),
            radius: 0.5,
            colors: [
              colors.primary.withValues(alpha: 0.16),
              colors.primary.withValues(alpha: 0.26),
              colors.primary,
            ],
          ),
          border: Border.all(
            color: colors.borderWeak.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all(size * 0.25),
                child: CircularProgressIndicator(
                  color: colors.buttonForeground,
                  strokeWidth: 3,
                ),
              )
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow,
                color: colors.buttonForeground,
                size: size * 0.5,
              ),
      ),
    );
  }
}

class _SubtitlesToggle extends StatelessWidget {
  final double size;
  final bool isActive;
  final VoidCallback onTap;

  const _SubtitlesToggle({
    required this.size,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 5),
      child: Icon(
        Icons.subtitles_rounded,
        color: isActive ? colors.primary : colors.textPrimary,
        size: size,
      ),
    );
  }
}

class _RepeatToggle extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _RepeatToggle({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Icon(
        Icons.repeat,
        color: colors.textPrimary,
        size: size,
      ),
    );
  }
}

class _TimelineWave extends StatelessWidget {
  final double progress;
  final ValueChanged<double> onScrub;

  const _TimelineWave({required this.progress, required this.onScrub});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handle(details.localPosition.dx, width),
          onPanDown: (details) => _handle(details.localPosition.dx, width),
          onPanUpdate: (details) => _handle(details.localPosition.dx, width),
          child: CustomPaint(
            painter: _WavePainter(progress: progress.clamp(0, 1).toDouble()),
          ),
        );
      },
    );
  }

  void _handle(double dx, double width) {
    if (width <= 0) {
      return;
    }
    onScrub((dx / width).clamp(0.0, 1.0).toDouble());
  }
}

class _WavePainter extends CustomPainter {
  final double progress;

  _WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint inactivePaint = Paint()
      ..color = ColorManager.primary.withValues(alpha: 0.22)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final Paint activePaint = Paint()
      ..color = ColorManager.primary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    const List<double> heights = [
      8,
      16,
      24,
      20,
      28,
      18,
      12,
      30,
      22,
      14,
      26,
      18,
      32,
      24,
      14,
      20,
      28,
      18,
      10,
      24,
      16,
      30,
      20,
      14,
      26,
      18,
      12,
      28,
      20,
      10,
      24,
      18,
      14,
      26,
      20,
      12,
    ];

    final double gap = size.width / (heights.length - 1);
    final double centerY = size.height / 2;

    for (int i = 0; i < heights.length; i++) {
      final double x = i * gap;
      final double h = (heights[i] / 32) * size.height;
      final Paint paint =
          (i / (heights.length - 1)) <= progress ? activePaint : inactivePaint;

      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
