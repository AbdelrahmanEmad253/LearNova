import 'package:learnova/features/content/domain/entities/audio_playback_state.dart';

class ToggleAudioPlaybackUseCase {
  const ToggleAudioPlaybackUseCase();

  AudioPlaybackState call(AudioPlaybackState state) {
    if (!state.isPlaying && state.position >= state.totalDuration) {
      return state.copyWith(
        position: Duration.zero,
        isPlaying: true,
      );
    }

    return state.copyWith(isPlaying: !state.isPlaying);
  }
}
