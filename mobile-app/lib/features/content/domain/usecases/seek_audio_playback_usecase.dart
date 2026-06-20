import 'package:learnova/features/content/domain/entities/audio_playback_state.dart';
import 'package:learnova/features/content/domain/repositories/audio_playback_repository.dart';

class SeekAudioPlaybackUseCase {
  final AudioPlaybackRepository _repository;

  const SeekAudioPlaybackUseCase(this._repository);

  AudioPlaybackState call(AudioPlaybackState state, Duration delta) {
    final Duration nextPosition = _repository.clampPosition(
      position: state.position + delta,
      totalDuration: state.totalDuration,
    );

    return state.copyWith(position: nextPosition);
  }
}
