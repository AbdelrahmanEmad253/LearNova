import 'package:learnova/features/content/domain/entities/audio_playback_state.dart';
import 'package:learnova/features/content/domain/repositories/audio_playback_repository.dart';

class ScrubAudioPlaybackUseCase {
  final AudioPlaybackRepository _repository;

  const ScrubAudioPlaybackUseCase(this._repository);

  AudioPlaybackState call(AudioPlaybackState state, double progress) {
    final Duration nextPosition = _repository.positionFromProgress(
      progress: progress,
      totalDuration: state.totalDuration,
    );

    return state.copyWith(position: nextPosition);
  }
}
