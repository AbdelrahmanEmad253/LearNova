import 'package:learnova/features/content/domain/repositories/audio_playback_repository.dart';

class FormatAudioDurationUseCase {
  final AudioPlaybackRepository _repository;

  const FormatAudioDurationUseCase(this._repository);

  String call(Duration duration) {
    return _repository.formatDuration(duration);
  }
}
