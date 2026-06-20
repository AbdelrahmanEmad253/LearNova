class AudioPlaybackState {
  final Duration position;
  final Duration totalDuration;
  final bool isPlaying;
  final bool showLyrics;
  final bool isLoading;

  const AudioPlaybackState({
    required this.position,
    required this.totalDuration,
    required this.isPlaying,
    required this.showLyrics,
    required this.isLoading,
  });

  factory AudioPlaybackState.initial({required Duration totalDuration}) {
    return AudioPlaybackState(
      position: Duration.zero,
      totalDuration: totalDuration,
      isPlaying: false,
      showLyrics: false,
      isLoading: false,
    );
  }

  double get progress {
    if (totalDuration.inMilliseconds <= 0) {
      return 0;
    }
    return (position.inMilliseconds / totalDuration.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  AudioPlaybackState copyWith({
    Duration? position,
    Duration? totalDuration,
    bool? isPlaying,
    bool? showLyrics,
    bool? isLoading,
  }) {
    return AudioPlaybackState(
      position: position ?? this.position,
      totalDuration: totalDuration ?? this.totalDuration,
      isPlaying: isPlaying ?? this.isPlaying,
      showLyrics: showLyrics ?? this.showLyrics,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
