import 'dart:async';

import 'package:video_player/video_player.dart';
import 'package:learnova/features/content/domain/repositories/video_playback_repository.dart';

/// Video playback implementation for direct URLs (Supabase Storage, CDN).
///
/// Uses the official `video_player` package. For YouTube links, the UI layer
/// uses [YoutubePlayerIFrame] directly since it manages its own controller.
class DirectVideoPlaybackRepositoryImpl implements VideoPlaybackRepository {
  VideoPlayerController? _controller;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();

  Timer? _positionTimer;

  @override
  bool get isYoutube => false;

  @override
  Duration? get totalDuration => _controller?.value.duration;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Future<Duration?> initialize(String url) async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await _controller!.initialize();

    // Listen for changes and broadcast to streams.
    _controller!.addListener(_onValueChanged);

    // Start a periodic timer to emit position updates (VideoPlayerController
    // only fires value changes for play/pause/seek, not every frame).
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_controller != null && _controller!.value.isInitialized) {
        _positionController.add(_controller!.value.position);
      }
    });

    return _controller!.value.duration;
  }

  void _onValueChanged() {
    if (_controller == null) return;
    _playingController.add(_controller!.value.isPlaying);
  }

  @override
  Future<void> play() async {
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> disposePlayer() async {
    _positionTimer?.cancel();
    _controller?.removeListener(_onValueChanged);
    await _controller?.dispose();
    _controller = null;
    await _positionController.close();
    await _playingController.close();
  }

  /// Access the underlying controller for the [VideoPlayer] widget.
  VideoPlayerController? get nativeController => _controller;
}
