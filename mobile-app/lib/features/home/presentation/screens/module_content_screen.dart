import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/features/content/domain/entities/content_destination.dart';
import 'package:learnova/features/content/domain/entities/content_item_payload.dart';
import 'package:learnova/features/content/presentation/providers/content_providers.dart';
import 'package:learnova/features/content/presentation/screens/content_audio_player.dart';
import 'package:learnova/features/content/presentation/screens/content_document_reader.dart';
import 'package:learnova/features/content/presentation/screens/mitchy_chat_screen.dart';
import 'package:learnova/features/content/presentation/screens/content_video_player.dart';
import 'package:learnova/features/home/domain/entities/level_module.dart';
import 'package:learnova/features/home/presentation/screens/level_preexam_screen.dart';
import 'package:learnova/features/home/presentation/providers/home_providers.dart';
import 'package:learnova/features/auth/presentation/providers/avatar_providers.dart';
import 'package:learnova/features/island_map/domain/entities/topic.dart';
import 'package:learnova/features/island_map/presentation/providers/island_map_providers.dart';

import '../../../../core/di/app_providers.dart';
class ModuleContentScreen extends ConsumerStatefulWidget {
  final LevelModule module;
  final String examId;
  final bool showCustomPreExam;
  final bool isLastModule;
  final String mapNodeId;

  const ModuleContentScreen({
    super.key,
    required this.module,
    required this.examId,
    required this.showCustomPreExam,
    required this.isLastModule,
    required this.mapNodeId,
  });

  @override
  ConsumerState<ModuleContentScreen> createState() =>
      _ModuleContentScreenState();
}

class _ModuleContentScreenState extends ConsumerState<ModuleContentScreen> {
  int? _selectedIndex;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    if (elapsedSeconds >= 5) {
      ref.read(activityTrackingServiceProvider).logActivity(
            moduleId: widget.module.id,
            levelId: 'level_${widget.module.levelNumber}',
            durationSeconds: elapsedSeconds,
          );
    }
    // Refresh global map to reflect new progress on previous screens
    // Need to use Future.microtask since ref.invalidate inside dispose can cause exceptions
    Future.microtask(() {
      try {
        ref.invalidate(globalMapProvider);
      } catch (_) {}
    });
    super.dispose();
  }

  Future<void> _openContentDestination(
    BuildContext context,
    ContentItemPayload item,
    int itemIndex,
    List<ContentItemPayload> modulePayloads,
  ) async {
    final ContentDestination destination =
        ref.read(resolveContentDestinationUseCaseProvider)(item);

    if (destination == ContentDestination.audio) {
      await AppRouter.push(
        context,
        AudioStudyPlayerScreen(
          item: item,
          moduleItems: modulePayloads,
          moduleIndex: itemIndex,
          moduleId: widget.module.id,
        ),
        routeName: AppRoutePaths.contentAudioPlayer,
      );
      if (mounted) {
        setState(() {});
      }
      return;
    }
    if (destination == ContentDestination.video) {
      await AppRouter.push(
        context,
        VideoPlayerPlaceholderScreen(
          item: item,
          moduleItems: modulePayloads,
          moduleIndex: itemIndex,
          moduleId: widget.module.id,
        ),
        routeName: AppRoutePaths.contentVideoPlayer,
      );
      if (mounted) {
        setState(() {});
      }
      return;
    }

    await AppRouter.push(
      context,
      DocumentReaderPlaceholderScreen(
        item: item,
        moduleItems: modulePayloads,
        moduleIndex: itemIndex,
        moduleId: widget.module.id,
      ),
      routeName: AppRoutePaths.contentDocumentReader,
    );
    if (mounted) {
      setState(() {});
    }
  }

  String _normalizedType(ContentItemPayload item) {
    return item.contentType.trim().toLowerCase();
  }

  bool _isAudio(ContentItemPayload item) {
    return _normalizedType(item) == 'audio';
  }

  bool _isVideo(ContentItemPayload item) {
    return _normalizedType(item) == 'video';
  }

  String _resumeLabelForItem(ContentItemPayload item) {
    if (_isAudio(item)) {
      return 'Resume audio';
    }
    if (_isVideo(item)) {
      return 'Resume video';
    }
    return 'Resume article';
  }

  ContentItemPayload? _selectedItem(List<ContentItemPayload> items) {
    if (_selectedIndex == null || items.isEmpty) {
      return null;
    }
    if (_selectedIndex! < 0 || _selectedIndex! >= items.length) {
      return null;
    }
    return items[_selectedIndex!];
  }

  Future<void> _onResumePressed(
      BuildContext context, List<ContentItemPayload> items) async {
    if (items.isEmpty) {
      return;
    }

    if (_selectedItem(items) != null && _selectedIndex != null) {
      await _openContentDestination(
          context, _selectedItem(items)!, _selectedIndex!, items);
      return;
    }

    final int nextIndex = items.indexWhere((item) {
      return !ref.read(moduleProgressProvider.notifier).isItemCompleted(
            moduleId: widget.module.id,
            itemId: item.id,
          );
    });
    final int resolvedIndex = nextIndex == -1 ? 0 : nextIndex;
    await _openContentDestination(
      context,
      items[resolvedIndex],
      resolvedIndex,
      items,
    );
  }

  double _resolvedProgress(List<ContentItemPayload> items, Map<String, Set<String>> progressState) {
    final completedIds = progressState[widget.module.id] ?? <String>{};
    final completedCount = items
        .where(
          (item) => completedIds.contains(item.id),
        )
        .length;
    final trackedProgress = items.isEmpty ? 0.0 : completedCount / items.length;
    return trackedProgress > widget.module.progressPercentage
        ? trackedProgress
        : widget.module.progressPercentage;
  }

  bool _isCurrentModuleCompleted(List<ContentItemPayload> items, Map<String, Set<String>> progressState) {
    if (items.isEmpty) {
      return false;
    }
    final completedIds = progressState[widget.module.id] ?? <String>{};

    return items.every(
      (item) => completedIds.contains(item.id),
    );
  }

  String _primaryActionLabel(
      ContentItemPayload? selectedItem, bool moduleCompleted) {
    if (moduleCompleted) {
      if (widget.module.isFoundation) {
        return 'Continue';
      }
      return 'Take Quiz';
    }
    if (selectedItem == null) {
      return 'Select content';
    }
    return _resumeLabelForItem(selectedItem);
  }

  Future<void> _onPrimaryActionPressed(BuildContext context,
      bool moduleCompleted, List<ContentItemPayload> items) async {
    if (moduleCompleted) {
      if (widget.module.isFoundation) {
        AppRouter.pop(context);
        return;
      }

      await AppRouter.push(
        context,
        LevelPreExamScreen(
          levelNumber: widget.module.levelNumber,
          examId: widget.module.id,
          isModuleExam: true,
          module: widget.module,
          mapNodeId: widget.mapNodeId,
        ),
        routeName: AppRoutePaths.homeLevelPreExam,
      );
      return;
    }

    await _onResumePressed(context, items);
  }

  bool _isSyncing = false;

  Future<void> _syncTopicProgressToSupabase(
      List<Topic> topics, Map<String, Set<String>> progressState) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final moduleId = widget.module.id;
      final completedItems = progressState[moduleId] ?? <String>{};
      if (completedItems.isEmpty) return;

      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      if (user == null) return;

      for (final topic in topics) {
        final isTopicCompleted = completedItems.contains(topic.id);
        if (!isTopicCompleted) continue;


        // Sync overall topic progress to 'completed'
        final status = 'completed';
        try {
          final existing = await supabase
              .from('student_progress')
              .select('id, status')
              .eq('user_id', user.id)
              .eq('topic_id', topic.id)
              .maybeSingle();

          if (existing != null) {
            if (existing['status'] != status) {
              await supabase
                  .from('student_progress')
                  .update({
                'status': status,
                'completed_at': DateTime.now().toIso8601String()
              }).eq('id', existing['id']);
            }
          } else {
            await supabase.from('student_progress').insert({
              'user_id': user.id,
              'topic_id': topic.id,
              'status': status,
              'format_served': 'Textual',
              'started_at': DateTime.now().toIso8601String(),
              'completed_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('Failed to sync topic progress: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final colors = AppColors.of(context);

    final asyncTopics = ref.watch(moduleTopicsProvider(widget.module.id));
    final topics = asyncTopics.value ?? [];
    final progressState = ref.watch(moduleProgressProvider);

    ref.listen<Map<String, Set<String>>>(
      moduleProgressProvider,
      (previous, next) {
        if (topics.isNotEmpty) {
          _syncTopicProgressToSupabase(topics, next);
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (topics.isNotEmpty && mounted) {
        _syncTopicProgressToSupabase(topics, ref.read(moduleProgressProvider));
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppBackground(),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: topPadding + 120),
                  _buildContentData(size, context, colors, topics, progressState, asyncTopics.isLoading, asyncTopics.hasError, asyncTopics.error),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SvgPicture.asset(
                  AppAssets.mapModuleBottom,
                  width: size.width,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
          _buildFixedOverlay(
            topPadding,
            size,
            _selectedItem(_topicsToContentItems(topics))?.id,
          ),
        ],
      ),
    );
  }

  Widget _buildContentData(
      Size size,
      BuildContext context,
      AppColors colors,
      List<Topic> topics,
      Map<String, Set<String>> progressState,
      bool isLoading,
      bool hasError,
      Object? error) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(color: ColorManager.primary),
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load topics.\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
      );
    }

    if (topics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Text(
            'No lessons found for this module.',
            style: TextStyle(color: colors.textPrimary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _buildContent(
      size,
      context,
      _topicsToContentItems(topics),
      progressState,
      colors,
    );
  }

  List<ContentItemPayload> _topicsToContentItems(List<Topic> topics) {
    final List<ContentItemPayload> items = [];

    for (final topic in topics) {
      if (topic.resources.isEmpty) {
        items.add(ContentItemPayload(
          id: topic.id,
          title: topic.title,
          contentType: 'text',
          meta: 'No resource available',
          topicId: topic.id,
        ));
        continue;
      }

      for (final resource in topic.resources) {
        // We use the topic.id as the identifier for completion tracking
        // so that it matches the IDs synced from Supabase student_progress.
        items.add(ContentItemPayload(
          id: topic.id, // Changed from resource.id to topic.id
          title: topic.title,
          contentType: _contentTypeForFormat(resource.formatType),
          meta: _metaForFormat(resource.formatType),
          mediaUrl: resource.resourceUrl,
          topicId: topic.id,
        ));
      }
    }

    return items;
  }

  String _contentTypeForFormat(String formatType) {
    return switch (formatType) {
      'Visual' => 'video',
      'Auditory' => 'audio',
      'Textual' => 'text',
      _ => 'text',
    };
  }

  String _metaForFormat(String formatType) {
    return switch (formatType) {
      'Visual' => 'Video lesson',
      'Auditory' => 'Audio lesson',
      'Textual' => 'Reading material',
      _ => 'Lesson',
    };
  }

  Widget _buildContent(
    Size size,
    BuildContext context,
    List<ContentItemPayload> items,
    Map<String, Set<String>> progressState,
    AppColors colors,
  ) {
    final ContentItemPayload? selectedItem = _selectedItem(items);
    final bool hasSelection = selectedItem != null;
    final bool isCompleted = _isCurrentModuleCompleted(items, progressState);
    final double progress = _resolvedProgress(items, progressState);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            widget.module.moduleName,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Current Progress:',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: ColorManager.progressTrack,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorManager.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...items.asMap().entries.map((entry) {
            final completedIds = progressState[widget.module.id] ?? <String>{};
            final bool isItemCompleted = completedIds.contains(entry.value.id);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ContentCard(
                index: entry.key + 1,
                item: entry.value,
                isSelected: _selectedIndex == entry.key,
                isCompleted: isItemCompleted,
                onTap: () {
                  setState(() {
                    _selectedIndex = entry.key;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 32),
          CustomButton(
            text: isCompleted ? 'Review Content' : _primaryActionLabel(selectedItem, isCompleted),
            onPressed: () {
              if (isCompleted) {
                // When reviewing, just open the first item if none is selected
                final targetItem = selectedItem ?? items.first;
                final targetIndex = _selectedIndex ?? 0;
                _openContentDestination(context, targetItem, targetIndex, items);
              } else {
                _onPrimaryActionPressed(context, isCompleted, items);
              }
            },
            backgroundColor: isCompleted || hasSelection
                ? ColorManager.primary
                : colors.cardBackground,
            textColor: isCompleted || hasSelection
                ? ColorManager.buttonDark
                : colors.textPrimary,
            height: 64,
            borderRadius: 16,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Back to Levels',
            onPressed: () {
              ref.invalidate(globalMapProvider);
              AppRouter.pop(context);
            },
            textColor: colors.textPrimary,
            isOutlined: true,
            height: 64,
            borderRadius: 16,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildFixedOverlay(double topPadding, Size size, String? selectedTopicId) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SvgPicture.asset(
              AppAssets.mapTop,
              width: size.width,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        Positioned(
          top: topPadding + 16,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40), // Placeholder for symmetry
              Text(
                'Level ${widget.module.levelNumber} - Module ${widget.module.moduleNumber}',
                style: const TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {
                  AppRouter.push(
                    context,
                    MitchyChatScreen(
                      moduleId: widget.module.id,
                      topicId: selectedTopicId,
                    ),
                    routeName: AppRoutePaths.contentMitchyChat,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    AppAssets.avatarMitchy,
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final int index;
  final ContentItemPayload item;
  final bool isSelected;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ContentCard({
    required this.index,
    required this.item,
    required this.isSelected,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String normalizedType = item.contentType.trim().toLowerCase();
    final bool isAudio = normalizedType == 'audio';
    final bool isVideo = normalizedType == 'video';
    final bool hasImage = (index == 2 && !isVideo) || isAudio;
    final String previewImagePath =
        isAudio ? AppAssets.audioPreview : AppAssets.testSmallCircle;

    return Material(
      color: ColorManager.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: ColorManager.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? ColorManager.primary
                  : ColorManager.primary.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                if (isVideo)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              ColorManager.accentBlue.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 30,
                          color: ColorManager.accentBlue,
                        ),
                      ),
                    ),
                  ),
                if (hasImage)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: 0.8,
                      child: Image.asset(
                        previewImagePath,
                        width: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (hasImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            ColorManager.white,
                            ColorManager.white,
                            ColorManager.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 68, 0),
                  child: Row(
                    children: [
                      Text(
                        '$index',
                        style: const TextStyle(
                          color: ColorManager.buttonDark,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: ColorManager.buttonDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isAudio
                                      ? Icons.graphic_eq
                                      : isVideo
                                          ? Icons.play_circle_fill_rounded
                                          : Icons.description_outlined,
                                  size: 16,
                                  color: ColorManager.infoMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.meta,
                                  style: const TextStyle(
                                    color: ColorManager.infoMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isCompleted
                            ? const [Color(0xFF7DF6D8), Color(0xFF03478E)]
                            : const [Color(0xFFE9EEF5), Color(0xFFC6D5E6)],
                      ),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.radio_button_unchecked,
                      color: isCompleted
                          ? ColorManager.white
                          : ColorManager.infoMuted,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
