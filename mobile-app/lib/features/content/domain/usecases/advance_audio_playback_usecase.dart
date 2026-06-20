import 'package:learnova/features/content/domain/entities/audio_playback_state.dart';
import 'package:learnova/features/content/domain/repositories/audio_playback_repository.dart';

class AdvanceAudioPlaybackUseCase {
  final AudioPlaybackRepository _repository;

  const AdvanceAudioPlaybackUseCase(this._repository);

  AudioPlaybackState call(AudioPlaybackState state, Duration delta) {
    if (!state.isPlaying) {
      return state;
    }

    final Duration nextPosition = _repository.clampPosition(
      position: state.position + delta,
      totalDuration: state.totalDuration,
    );
    final bool hasFinished = nextPosition >= state.totalDuration;

    return state.copyWith(
      position: nextPosition,
      isPlaying: hasFinished ? false : true,
    );
  }
}
