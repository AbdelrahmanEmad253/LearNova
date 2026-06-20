import 'package:learnova/features/content/domain/entities/audio_playback_state.dart';

class RestartAudioPlaybackUseCase {
  const RestartAudioPlaybackUseCase();

  AudioPlaybackState call(AudioPlaybackState state) {
    return state.copyWith(position: Duration.zero);
  }
}
