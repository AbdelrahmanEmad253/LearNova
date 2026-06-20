import 'package:learnova/features/content/domain/entities/audio_playback_state.dart';
import 'package:learnova/features/content/domain/repositories/audio_playback_repository.dart';

class InitializeAudioPlaybackUseCase {
  final AudioPlaybackRepository _repository;

  const InitializeAudioPlaybackUseCase(this._repository);

  AudioPlaybackState call({
    required String rawDuration,
    required Duration fallbackDuration,
  }) {
    final Duration totalDuration =
        _repository.parseDuration(rawDuration) ?? fallbackDuration;

    return AudioPlaybackState.initial(totalDuration: totalDuration);
  }
}
