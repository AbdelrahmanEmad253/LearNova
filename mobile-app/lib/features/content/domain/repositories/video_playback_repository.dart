import 'dart:async';

/// Contract for video playback operations.
///
/// Supports both direct video URLs (Supabase Storage) and YouTube links.
abstract class VideoPlaybackRepository {
  /// Initialize the player with a video URL or YouTube link.
  /// Returns the total duration when available.
  Future<Duration?> initialize(String url);

  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);

  /// Current playback position as a stream.
  Stream<Duration> get positionStream;

  /// Whether the player is currently playing.
  Stream<bool> get playingStream;

  /// The total duration of the loaded video (null until loaded).
  Duration? get totalDuration;

  /// Whether this is a YouTube video.
  bool get isYoutube;

  /// Release all resources.
  Future<void> disposePlayer();
}
