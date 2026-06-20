import 'package:learnova/features/content/domain/entities/audio_playback_state.dart';

class ToggleLyricsVisibilityUseCase {
  const ToggleLyricsVisibilityUseCase();

  AudioPlaybackState call(AudioPlaybackState state) {
    return state.copyWith(showLyrics: !state.showLyrics);
  }
}
