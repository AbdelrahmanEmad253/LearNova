import 'dart:async';

/// Contract for audio playback operations.
///
/// Pure utility methods (parseDuration, clampPosition, etc.) are kept for
/// backward compatibility with the existing UseCases. The new player methods
/// (load, play, pause, seek, dispose) drive real audio via `just_audio`.
abstract class AudioPlaybackRepository {
  // ── Pure utility methods (existing) ──

  Duration? parseDuration(String rawDuration);

  Duration clampPosition({
    required Duration position,
    required Duration totalDuration,
  });

  Duration positionFromProgress({
    required double progress,
    required Duration totalDuration,
  });

  String formatDuration(Duration duration);

  // ── Real player methods (new) ──

  /// Load an audio source from a URL. Returns the total duration if available.
  Future<Duration?> load(String url);

  /// Start or resume playback.
  Future<void> play();

  /// Pause playback.
  Future<void> pause();

  /// Seek to a specific position.
  Future<void> seek(Duration position);

  /// A stream of the current playback position, updated frequently.
  Stream<Duration> get positionStream;

  /// A stream of the playing/paused state.
  Stream<bool> get playingStream;

  /// A stream emitting when playback completes naturally.
  Stream<void> get completionStream;

  /// Release all player resources.
  Future<void> disposePlayer();
}
