import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/utils/app_formatters.dart';
import 'package:learnova/core/utils/youtube_url_helper.dart';
import 'package:learnova/features/content/domain/entities/content_destination.dart';
import 'package:learnova/features/content/domain/entities/content_item_payload.dart';
import 'package:learnova/features/content/presentation/providers/content_providers.dart';
import 'package:learnova/features/content/presentation/screens/content_audio_player.dart';
import 'package:learnova/features/content/presentation/screens/content_document_reader.dart';
import 'package:learnova/features/curriculum/presentation/notifiers/topic_session_notifier.dart';
import 'package:learnova/features/curriculum/presentation/providers/topic_progress_provider.dart';
import 'package:learnova/features/home/presentation/providers/home_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt_flutter;

/// Determines how the video is being rendered.
enum _VideoMode {
  /// YouTube video via youtube_player_flutter.
  youtube,

  /// Direct video file via video_player package.
  direct,

  /// Non-YouTube web link loaded via WebView with video extraction attempt.
  webView,
}

class VideoPlayerPlaceholderScreen extends ConsumerStatefulWidget {
  final ContentItemPayload item;
  final List<ContentItemPayload>? moduleItems;
  final int? moduleIndex;
  final String? moduleId;

  const VideoPlayerPlaceholderScreen({
    super.key,
    required this.item,
    this.moduleItems,
    this.moduleIndex,
    this.moduleId,
  });

  @override
  ConsumerState<VideoPlayerPlaceholderScreen> createState() =>
      _VideoPlayerPlaceholderScreenState();
}

class _VideoPlayerPlaceholderScreenState
    extends ConsumerState<VideoPlayerPlaceholderScreen> {
  bool _isPlaying = false;
  bool _isFullscreen = false;
  double _progress = 0.0;
  Duration _totalDuration = const Duration(minutes: 10);
  Timer? _playbackTimer;

  // Direct video player (Supabase / extracted URL).
  VideoPlayerController? _videoPlayerController;

  // YouTube player (youtube_player_flutter).
  yt_flutter.YoutubePlayerController? _ytController;

  // Generic WebView fallback.
  WebViewController? _webViewController;

  bool _videoLoading = false;
  String? _videoErrorMessage;
  _VideoMode? _mode;

  AppLifecycleListener? _lifecycleListener;
  ({String topicId, String userId, String formatType})? _sessionArgs;

  // --------------------------------------------------------------------------
  // Duration helpers
  // --------------------------------------------------------------------------

  Duration get _currentDuration {
    // Direct video controller.
    final VideoPlayerController? vc = _videoPlayerController;
    if (vc != null && vc.value.isInitialized) {
      return vc.value.position;
    }

    // YouTube – duration is tracked via listener.
    final yt_flutter.YoutubePlayerController? ytCtrl = _ytController;
    if (ytCtrl != null) {
      return ytCtrl.value.position;
    }

    return Duration(
      seconds: (_totalDuration.inSeconds * _progress).round(),
    );
  }

  // --------------------------------------------------------------------------
  // URL resolution
  // --------------------------------------------------------------------------

  String? _extractYouTubeId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return YoutubeUrlHelper.extractVideoId(url);
  }

  String? _resolvedMediaUrl() {
    final String directUrl = widget.item.mediaUrl?.trim() ?? '';
    if (directUrl.isNotEmpty) {
      return directUrl;
    }

    final List<ContentItemPayload>? moduleItems = widget.moduleItems;
    if (moduleItems != null) {
      for (final item in moduleItems) {
        if (item.id == widget.item.id) {
          final String candidate = item.mediaUrl?.trim() ?? '';
          if (candidate.isNotEmpty) {
            return candidate;
          }
        }
      }
    }

    return null;
  }

  /// Returns true if [url] looks like a direct video file link.
  bool _isDirectVideoUrl(String url) {
    final lower = url.toLowerCase();
    const extensions = [
      '.mp4',
      '.webm',
      '.mov',
      '.m4v',
      '.avi',
      '.mkv',
      '.3gp',
    ];
    for (final ext in extensions) {
      if (lower.contains(ext)) return true;
    }
    // Supabase Storage object URLs.
    if (lower.contains('supabase') && lower.contains('/storage/')) return true;
    return false;
  }

  // --------------------------------------------------------------------------
  // Initialisation
  // --------------------------------------------------------------------------

  void _initializeMedia() {
    final String? mediaUrl = _resolvedMediaUrl();
    if (mediaUrl == null || mediaUrl.isEmpty) {
      setState(() {
        _videoErrorMessage = 'No video URL was found for this lesson.';
      });
      return;
    }

    // 1. YouTube?
    final String? videoId = _extractYouTubeId(mediaUrl);
    if (videoId != null) {
      _initializeYouTube(videoId);
      return;
    }

    // 2. Direct video file?
    if (_isDirectVideoUrl(mediaUrl)) {
      _initializeDirectVideo(mediaUrl);
      return;
    }

    // 3. Other web URL – try to extract a video source from the page.
    _initializeFromWebUrl(mediaUrl);
  }

  // ---- YouTube via youtube_player_flutter ----

  void _initializeYouTube(String videoId) {
    _mode = _VideoMode.youtube;

    final controller = yt_flutter.YoutubePlayerController(
      initialVideoId: videoId,
      flags: const yt_flutter.YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: false,
        hideControls: false,
        controlsVisibleAtStart: true,
      ),
    );

    controller.addListener(_syncYouTubeState);

    setState(() {
      _ytController = controller;
    });
  }

  void _syncYouTubeState() {
    final yt_flutter.YoutubePlayerController? ctrl = _ytController;
    if (ctrl == null || !mounted) return;

    final Duration duration = ctrl.metadata.duration;
    final Duration position = ctrl.value.position;
    final bool playing = ctrl.value.isPlaying;

    // Only rebuild if something actually changed.
    final Duration newTotal =
        duration != Duration.zero ? duration : _totalDuration;
    final double newProgress = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    if (newTotal == _totalDuration &&
        playing == _isPlaying &&
        (newProgress - _progress).abs() < 0.001) {
      return;
    }

    setState(() {
      _totalDuration = newTotal;
      _isPlaying = playing;
      _progress = newProgress;
    });
  }

  // ---- Direct video ----

  Future<void> _initializeDirectVideo(String url) async {
    if (!mounted) return;
    _mode = _VideoMode.direct;

    setState(() {
      _videoLoading = true;
      _videoErrorMessage = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.setLooping(false);
      controller.addListener(_syncDirectVideoState);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _videoPlayerController = controller;
        _videoLoading = false;
        if (controller.value.duration != Duration.zero) {
          _totalDuration = controller.value.duration;
        }
        _progress = controller.value.duration == Duration.zero
            ? _progress.clamp(0.0, 1.0)
            : (controller.value.position.inMilliseconds /
                    controller.value.duration.inMilliseconds)
                .clamp(0.0, 1.0);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoErrorMessage = 'Unable to load video.';
      });
    }
  }

  void _syncDirectVideoState() {
    final VideoPlayerController? controller = _videoPlayerController;
    if (controller == null || !mounted || !controller.value.isInitialized) {
      return;
    }

    final Duration duration = controller.value.duration;
    final int totalMs = duration.inMilliseconds;
    final int currentMs = controller.value.position.inMilliseconds;
    final double progress =
        totalMs <= 0 ? 0.0 : (currentMs / totalMs).clamp(0.0, 1.0);

    if (_progress != progress || _isPlaying != controller.value.isPlaying) {
      setState(() {
        if (duration != Duration.zero) _totalDuration = duration;
        _progress = progress;
        _isPlaying = controller.value.isPlaying;
      });
    }
  }

  // ---- Web URL (extract video or fallback to WebView) ----

  Future<void> _initializeFromWebUrl(String url) async {
    if (!mounted) return;

    setState(() {
      _videoLoading = true;
      _videoErrorMessage = null;
    });

    // Try to extract a direct video source from the page HTML.
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);

        // Look for <video> src or <source> src.
        String? videoSrc;
        for (final el in doc.querySelectorAll('video, source')) {
          final src = el.attributes['src'];
          if (src != null && src.trim().isNotEmpty) {
            videoSrc = src.trim();
            break;
          }
        }

        // Also look for og:video meta tag.
        if (videoSrc == null) {
          final ogVideo = doc
              .querySelector('meta[property="og:video"]')
              ?.attributes['content'];
          if (ogVideo != null && ogVideo.trim().isNotEmpty) {
            videoSrc = ogVideo.trim();
          }
        }

        // Also check for embedded YouTube.
        if (videoSrc == null) {
          for (final iframe in doc.querySelectorAll('iframe')) {
            final iframeSrc = iframe.attributes['src'] ?? '';
            final ytId = _extractYouTubeId(iframeSrc);
            if (ytId != null) {
              if (!mounted) return;
              setState(() => _videoLoading = false);
              _initializeYouTube(ytId);
              return;
            }
          }
        }

        // If we found a video source, resolve relative URLs and play directly.
        if (videoSrc != null) {
          if (!videoSrc.startsWith('http')) {
            final uri = Uri.parse(url);
            videoSrc = uri.resolve(videoSrc).toString();
          }
          if (!mounted) return;
          setState(() => _videoLoading = false);
          _initializeDirectVideo(videoSrc);
          return;
        }
      }
    } catch (_) {
      // Extraction failed, fall back to WebView.
    }

    // Fallback: load the URL in a WebView.
    if (!mounted) return;
    _mode = _VideoMode.webView;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {},
      ))
      ..loadRequest(Uri.parse(url));

    setState(() {
      _videoLoading = false;
    });
  }

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );
    _totalDuration = _parseMetaDuration(widget.item.meta);
    _progress = _progress.clamp(0.0, 1.0);
    _initializeMedia();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    final topicId = widget.item.topicId;
    if (userId != null && topicId != null) {
      _sessionArgs = (userId: userId, topicId: topicId, formatType: widget.item.contentType);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(topicSessionNotifierProvider.notifier).init(_sessionArgs!);
        ref.read(topicSessionNotifierProvider.notifier).startSession();
      });
      _lifecycleListener = AppLifecycleListener(
        onPause: () => ref.read(topicSessionNotifierProvider.notifier).pauseSession(),
        onResume: () => ref.read(topicSessionNotifierProvider.notifier).resumeSession(),
        onHide: () => ref.read(topicSessionNotifierProvider.notifier).flushTelemetry(),
      );
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    
    _playbackTimer?.cancel();
    _videoPlayerController?.removeListener(_syncDirectVideoState);
    _videoPlayerController?.dispose();
    _ytController?.removeListener(_syncYouTubeState);
    _ytController?.dispose();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Chapters (dynamic based on video duration)
  // --------------------------------------------------------------------------

  List<_VideoChapter> get _chapters {
    final int totalSec = _totalDuration.inSeconds;

    // For very short videos (< 2min), just show start.
    if (totalSec < 120) {
      return <_VideoChapter>[
        const _VideoChapter(
          title: 'Start',
          summary: 'Beginning of the video',
          start: Duration.zero,
        ),
      ];
    }

    // Generate proportional chapters based on total duration.
    final List<_ChapterTemplate> templates = [
      _ChapterTemplate('Introduction', 'Overview and learning goals', 0.0),
      _ChapterTemplate('Core Concepts', 'Main explanation and key ideas', 0.15),
      _ChapterTemplate('Deep Dive', 'Detailed walkthrough', 0.35),
      _ChapterTemplate('Examples', 'Practical examples and demos', 0.55),
      _ChapterTemplate('Advanced Topics', 'Further exploration', 0.75),
      _ChapterTemplate('Summary', 'Recap and final notes', 0.90),
    ];

    // Filter: only keep chapters that make sense for the duration.
    // For shorter videos (<10min), use fewer chapters.
    final int maxChapters =
        totalSec < 600 ? 3 : (totalSec < 1800 ? 4 : templates.length);

    final List<_VideoChapter> chapters = <_VideoChapter>[];
    final int step = templates.length ~/ maxChapters;
    for (int i = 0;
        i < templates.length && chapters.length < maxChapters;
        i += (i == 0 ? 1 : step)) {
      final _ChapterTemplate t = templates[i.clamp(0, templates.length - 1)];
      chapters.add(_VideoChapter(
        title: t.title,
        summary: t.summary,
        start: Duration(seconds: (totalSec * t.fraction).round()),
      ));
    }

    // Always ensure at least the intro chapter.
    if (chapters.isEmpty) {
      chapters.add(const _VideoChapter(
        title: 'Introduction',
        summary: 'Beginning of the video',
        start: Duration.zero,
      ));
    }

    return chapters;
  }

  int _activeChapterIndex() {
    final int current = _currentDuration.inSeconds;
    int index = 0;
    for (int i = 0; i < _chapters.length; i++) {
      if (current >= _chapters[i].start.inSeconds) {
        index = i;
      }
    }
    return index;
  }

  // --------------------------------------------------------------------------
  // Playback controls
  // --------------------------------------------------------------------------

  void _togglePlayPause() {
    // YouTube.
    final yt_flutter.YoutubePlayerController? ytCtrl = _ytController;
    if (ytCtrl != null) {
      if (_isPlaying) {
        ytCtrl.pause();
      } else {
        ytCtrl.play();
      }
      return;
    }

    // Direct video.
    final VideoPlayerController? vc = _videoPlayerController;
    if (vc != null && vc.value.isInitialized) {
      if (vc.value.isPlaying) {
        vc.pause();
      } else {
        vc.play();
      }
      return;
    }

    // Placeholder ticker for WebView / loading states.
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _startPlaybackTicker();
    } else {
      _playbackTimer?.cancel();
    }
  }

  void _startPlaybackTicker() {
    if (_videoPlayerController != null || _ytController != null) return;
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) return;
      final int nextSeconds = _currentDuration.inSeconds + 1;
      if (nextSeconds >= _totalDuration.inSeconds) {
        setState(() {
          _progress = 1;
          _isPlaying = false;
        });
        timer.cancel();
        return;
      }
      setState(() {
        _progress = nextSeconds / _totalDuration.inSeconds;
      });
    });
  }

  void _seekBySeconds(int deltaSeconds) {
    // YouTube.
    final yt_flutter.YoutubePlayerController? ytCtrl = _ytController;
    if (ytCtrl != null) {
      final int target = (_currentDuration.inSeconds + deltaSeconds).clamp(
        0,
        _totalDuration.inSeconds,
      );
      ytCtrl.seekTo(Duration(seconds: target));
      return;
    }

    // Direct video.
    final VideoPlayerController? vc = _videoPlayerController;
    if (vc != null && vc.value.isInitialized) {
      final int target = (_currentDuration.inSeconds + deltaSeconds).clamp(
        0,
        vc.value.duration.inSeconds,
      );
      vc.seekTo(Duration(seconds: target));
      return;
    }

    final int target = (_currentDuration.inSeconds + deltaSeconds).clamp(
      0,
      _totalDuration.inSeconds,
    );
    setState(() {
      _progress = target / _totalDuration.inSeconds;
    });
  }

  void _jumpToChapter(_VideoChapter chapter) {
    final yt_flutter.YoutubePlayerController? ytCtrl = _ytController;
    if (ytCtrl != null) {
      ytCtrl.seekTo(chapter.start);
      return;
    }

    final VideoPlayerController? vc = _videoPlayerController;
    if (vc != null && vc.value.isInitialized) {
      vc.seekTo(chapter.start);
      return;
    }

    setState(() {
      _progress = chapter.start.inSeconds / _totalDuration.inSeconds;
    });
  }

  // --------------------------------------------------------------------------
  // Fullscreen
  // --------------------------------------------------------------------------

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    setState(() => _isFullscreen = true);
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp],
    );
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );
    if (!mounted) return;
    setState(() => _isFullscreen = false);
  }

  // --------------------------------------------------------------------------
  // Module navigation
  // --------------------------------------------------------------------------

  ContentItemPayload? _nextItemInModule() {
    final List<ContentItemPayload>? items = widget.moduleItems;
    final int? index = widget.moduleIndex;
    if (items == null || index == null) return null;
    final int nextIndex = index + 1;
    if (nextIndex < 0 || nextIndex >= items.length) return null;
    return items[nextIndex];
  }

  Future<void> _onFinishPressed() async {
    if (widget.moduleId != null) {
      ref.read(moduleProgressProvider.notifier).markItemCompleted(
            moduleId: widget.moduleId!,
            itemId: widget.item.id,
          );
    }

    if (_sessionArgs != null) {
      final notifier = ref.read(topicSessionNotifierProvider.notifier);
      await notifier.consumeResource('Visual');
      await notifier.completeTopic();
    }

    if (mounted) {
      AppRouter.pop(context);
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  Duration _parseMetaDuration(String meta) {
    final RegExp minSec = RegExp(r'(\d+)\s*min(?:ute)?s?\s*(\d+)\s*sec');
    final Match? minSecMatch = minSec.firstMatch(meta.toLowerCase());
    if (minSecMatch != null) {
      final int minutes = int.tryParse(minSecMatch.group(1) ?? '') ?? 0;
      final int seconds = int.tryParse(minSecMatch.group(2) ?? '') ?? 0;
      final int totalSeconds = (minutes * 60) + seconds;
      return Duration(seconds: math.max(totalSeconds, 1));
    }

    final RegExp minOnly = RegExp(r'(\d+)\s*min(?:ute)?s?');
    final Match? minOnlyMatch = minOnly.firstMatch(meta.toLowerCase());
    if (minOnlyMatch != null) {
      final int minutes = int.tryParse(minOnlyMatch.group(1) ?? '') ?? 0;
      return Duration(seconds: math.max(minutes * 60, 1));
    }

    return const Duration(minutes: 10);
  }

  String _formatDuration(Duration value) {
    return AppFormatters.toClock(value);
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(topicSessionNotifierProvider);
    final Size size = MediaQuery.of(context).size;
    final double sx = size.width / 412;
    final double sy = size.height / 917;
    final double ss = math.min(sx, sy);
    final String title = widget.item.title.trim().isEmpty
        ? 'Video Lesson'
        : widget.item.title.trim();
    final int activeChapterIndex = _activeChapterIndex();

    // For YouTube & WebView modes, allow finish without full progress.
    final bool isEmbeddedMode =
        _mode == _VideoMode.youtube || _mode == _VideoMode.webView;
    final bool canFinish = isEmbeddedMode || _progress >= 0.999;

    // All modes use the same layout with our _isFullscreen handling.
    return _buildDefaultLayout(ss, title, activeChapterIndex, canFinish);
  }

  /// Default layout for non-YouTube modes (direct video / WebView).
  Widget _buildDefaultLayout(
    double ss,
    String title,
    int activeChapterIndex,
    bool canFinish,
  ) {
    final colors = AppColors.of(context);
    final double sx = ss;
    final double sy = ss;
    final sessionState = ref.watch(topicSessionNotifierProvider);

    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _isFullscreen) {
          await _exitFullscreen();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: _isFullscreen
              ? _buildFullscreenPlayer(ss)
              : Stack(
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
                    Positioned(
                      left: 24 * sx,
                      top: 14 * sy,
                      child: InkWell(
                        onTap: () => AppRouter.pop(context),
                        borderRadius: BorderRadius.circular(20 * ss),
                        child: Container(
                          width: 40 * ss,
                          height: 40 * ss,
                          decoration: BoxDecoration(
                            color: colors.cardBackground.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.borderWeak.withValues(alpha: 0.55),
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
                      top: 20 * sy,
                      right: 24 * sx,
                      child: Text(
                        'Video Study',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 30 * ss,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24 * sx,
                      right: 24 * sx,
                      top: 86 * sy,
                      bottom: 20 * sy,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVideoCard(ss),
                            SizedBox(height: 18 * sy),
                            _buildMetaCard(title, ss),
                            SizedBox(height: 16 * sy),
                            _buildChaptersCard(ss, activeChapterIndex),
                            SizedBox(height: 18 * sy),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: (canFinish && !sessionState.isLoading) ? _onFinishPressed : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.buttonForeground,
                                  disabledBackgroundColor:
                                      const Color(0xFF1D3D55),
                                  disabledForegroundColor: colors.textSecondary,
                                  minimumSize: Size.fromHeight(60 * ss),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: sessionState.isLoading
                                    ? null
                                    : Icon(
                                        Icons.check_circle_outline,
                                        color: colors.buttonForeground,
                                      ),
                                label: sessionState.isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            colors.buttonForeground,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Finished',
                                        style: TextStyle(
                                          fontSize: 18 * ss,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: 10 * sy),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => AppRouter.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.textPrimary,
                                  side: BorderSide(
                                    color: colors.borderWeak
                                        .withValues(alpha: 0.6),
                                  ),
                                  minimumSize: Size.fromHeight(56 * ss),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: 16 * ss,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16 * sy),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Video card widget
  // --------------------------------------------------------------------------

  Widget _buildVideoCard(double ss) {
    final colors = AppColors.of(context);

    // ----- YouTube player -----
    if (_ytController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18 * ss),
          child: Stack(
            fit: StackFit.expand,
            children: [
              yt_flutter.YoutubePlayer(
                controller: _ytController!,
                showVideoProgressIndicator: false,
                // Custom bottom bar WITHOUT fullscreen button.
                bottomActions: [
                  const SizedBox(width: 14),
                  yt_flutter.CurrentPosition(),
                  const SizedBox(width: 8),
                  yt_flutter.ProgressBar(
                    isExpanded: true,
                    colors: yt_flutter.ProgressBarColors(
                      playedColor: colors.primary,
                      handleColor: colors.textPrimary,
                      bufferedColor: colors.textPrimary.withValues(alpha: 0.24),
                      backgroundColor:
                          colors.textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  yt_flutter.RemainingDuration(),
                  const SizedBox(width: 14),
                ],
              ),
              // Double-tap zones for ±5s seek.
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () => _seekBySeconds(-5),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () => _seekBySeconds(5),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
              // Our fullscreen button (top right).
              Positioned(
                right: 10 * ss,
                top: 10 * ss,
                child: _OverlayIconButton(
                  icon: Icons.fullscreen_rounded,
                  onTap: _enterFullscreen,
                  size: ss,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----- WebView fallback -----
    if (_webViewController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18 * ss),
          child: Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: _webViewController!),
              Positioned(
                left: 16 * ss,
                top: 14 * ss,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * ss,
                    vertical: 5 * ss,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardBackground.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Web video',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12 * ss,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----- Direct video player -----
    final VideoPlayerController? videoController = _videoPlayerController;

    if (_videoLoading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18 * ss),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.55),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withValues(alpha: 0.6),
                colors.background,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (videoController != null && videoController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: videoController.value.aspectRatio == 0
            ? 16 / 9
            : videoController.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18 * ss),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: videoController.value.size.width,
                    height: videoController.value.size.height,
                    child: VideoPlayer(videoController),
                  ),
                ),
              ),
              Positioned(
                left: 16 * ss,
                top: 14 * ss,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * ss,
                    vertical: 5 * ss,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardBackground.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Video',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12 * ss,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14 * ss,
                top: 12 * ss,
                child: InkWell(
                  onTap: _enterFullscreen,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36 * ss,
                    height: 36 * ss,
                    decoration: BoxDecoration(
                      color: colors.cardBackground.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fullscreen_rounded,
                      color: colors.textPrimary,
                      size: 22 * ss,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----- Error state -----
    if (_videoErrorMessage != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18 * ss),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.55),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withValues(alpha: 0.6),
                colors.background,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _videoErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorManager.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14 * ss,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ----- Static placeholder (no URL at all) -----
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18 * ss),
          border: Border.all(
            color: ColorManager.primary.withValues(alpha: 0.55),
            width: 1.5,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorManager.videoGradientStart,
              ColorManager.videoGradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16 * ss),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.textPrimary.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16 * ss,
              top: 14 * ss,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * ss,
                  vertical: 5 * ss,
                ),
                decoration: BoxDecoration(
                  color: colors.cardBackground.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Lecture',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12 * ss,
                  ),
                ),
              ),
            ),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(34 * ss),
                onTap: _togglePlayPause,
                child: Container(
                  width: 68 * ss,
                  height: 68 * ss,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.4),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 40 * ss,
                    color: colors.buttonForeground,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14 * ss,
              top: 12 * ss,
              child: InkWell(
                onTap: _enterFullscreen,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36 * ss,
                  height: 36 * ss,
                  decoration: BoxDecoration(
                    color: colors.cardBackground.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fullscreen_rounded,
                    color: colors.textPrimary,
                    size: 22 * ss,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(12 * ss, 10 * ss, 12 * ss, 8 * ss),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16 * ss),
                    bottomRight: Radius.circular(16 * ss),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorManager.transparent,
                      ColorManager.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _OverlayIconButton(
                          icon: Icons.replay_5_rounded,
                          onTap: () => _seekBySeconds(-5),
                          size: ss,
                        ),
                        SizedBox(width: 6 * ss),
                        _OverlayIconButton(
                          icon: _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: _togglePlayPause,
                          size: ss,
                          isPrimary: true,
                        ),
                        SizedBox(width: 6 * ss),
                        _OverlayIconButton(
                          icon: Icons.forward_5_rounded,
                          onTap: () => _seekBySeconds(5),
                          size: ss,
                        ),
                        const Spacer(),
                        Text(
                          '${_formatDuration(_currentDuration)} / ${_formatDuration(_totalDuration)}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11 * ss,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2 * ss),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbColor: colors.textPrimary,
                        activeTrackColor: colors.primary,
                        inactiveTrackColor: colors.borderWeak,
                        trackHeight: 3.2 * ss,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 5.5 * ss,
                        ),
                      ),
                      child: Slider(
                        value: _progress,
                        onChanged: (value) {
                          setState(() {
                            _progress = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 14 * ss,
              bottom: 12 * ss,
              child: Text(
                _isPlaying ? 'Now Playing' : 'Paused',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12 * ss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard(String title, double ss) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20 * ss,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.item.meta,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14 * ss,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Video content',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersCard(double ss, int activeChapterIndex) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Sections',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18 * ss,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          ..._chapters.asMap().entries.map((entry) {
            final int index = entry.key;
            final _VideoChapter chapter = entry.value;
            final bool isActive = index == activeChapterIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _jumpToChapter(chapter),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.primary.withValues(alpha: 0.24)
                        : colors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? colors.primary : colors.borderWeak,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _formatDuration(chapter.start),
                          style: TextStyle(
                            color: colors.buttonForeground,
                            fontSize: 11 * ss,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.title,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14 * ss,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              chapter.summary,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12 * ss,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFullscreenPlayer(double ss) {
    final colors = AppColors.of(context);

    // YouTube fullscreen.
    if (_ytController != null) {
      return Container(
        color: colors.background,
        child: Stack(
          children: [
            // YouTube player fills the entire screen.
            Positioned.fill(
              child: yt_flutter.YoutubePlayer(
                controller: _ytController!,
                showVideoProgressIndicator: false,
                bottomActions: [
                  const SizedBox(width: 14),
                  yt_flutter.CurrentPosition(),
                  const SizedBox(width: 8),
                  yt_flutter.ProgressBar(
                    isExpanded: true,
                    colors: yt_flutter.ProgressBarColors(
                      playedColor: colors.primary,
                      handleColor: colors.textPrimary,
                      bufferedColor: colors.textPrimary.withValues(alpha: 0.24),
                      backgroundColor:
                          colors.textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  yt_flutter.RemainingDuration(),
                  const SizedBox(width: 14),
                ],
              ),
            ),
            // Double-tap zones for ±5s.
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () => _seekBySeconds(-5),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () => _seekBySeconds(5),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            // Exit fullscreen (top left).
            Positioned(
              top: 16,
              left: 16,
              child: _OverlayIconButton(
                icon: Icons.fullscreen_exit_rounded,
                onTap: _exitFullscreen,
                size: ss,
              ),
            ),
          ],
        ),
      );
    }

    // Non-YouTube fullscreen (direct video / WebView).
    return Container(
      color: colors.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildVideoCard(ss),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _OverlayIconButton(
              icon: Icons.fullscreen_exit_rounded,
              onTap: _exitFullscreen,
              size: ss,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool isPrimary;

  const _OverlayIconButton({
    required this.icon,
    required this.onTap,
    required this.size,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34 * size,
        height: 34 * size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPrimary
              ? colors.primary.withValues(alpha: 0.9)
              : colors.cardBackground.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isPrimary
                ? colors.primary.withValues(alpha: 0.95)
                : colors.borderWeak.withValues(alpha: 0.4),
          ),
        ),
        child: Icon(
          icon,
          color: isPrimary ? colors.buttonForeground : colors.textPrimary,
          size: 20 * size,
        ),
      ),
    );
  }
}

class _VideoChapter {
  final String title;
  final String summary;
  final Duration start;

  const _VideoChapter({
    required this.title,
    required this.summary,
    required this.start,
  });
}

class _ChapterTemplate {
  final String title;
  final String summary;
  final double fraction;

  const _ChapterTemplate(this.title, this.summary, this.fraction);
}
