import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:learnova/features/content/domain/entities/audio_playback_state.dart';
import 'package:learnova/features/content/domain/repositories/audio_playback_repository.dart';

/// Controls audio playback using a real [AudioPlaybackRepository].
///
/// When a [mediaUrl] is provided, playback is driven by `just_audio` streams.
/// When no URL is available, falls back to timer-based simulation for UI demos.
class AudioStudyPlayerController extends ChangeNotifier {
  final AudioPlaybackRepository _repository;
  final String? _mediaUrl;

  late AudioPlaybackState _state;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<void>? _completionSub;

  // Timer-based fallback for when no real URL is provided.
  static const Duration _tickInterval = Duration(milliseconds: 200);
  Timer? _fallbackTimer;

  bool get _isRealPlayback => _mediaUrl != null && _mediaUrl!.isNotEmpty;

  AudioStudyPlayerController({
    required AudioPlaybackRepository repository,
    required String rawDuration,
    String? mediaUrl,
    Duration fallbackDuration = const Duration(minutes: 4, seconds: 25),
  })  : _repository = repository,
        _mediaUrl = mediaUrl {
    final Duration totalDuration =
        _repository.parseDuration(rawDuration) ?? fallbackDuration;
    _state = AudioPlaybackState.initial(totalDuration: totalDuration);
  }

  /// Load the audio source. Call once from the screen's initState.
  Future<void> initialize() async {
    if (!_isRealPlayback) return;

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final realDuration = await _repository.load(_mediaUrl!);
      if (realDuration != null) {
        _state = _state.copyWith(
          totalDuration: realDuration,
          position: Duration.zero,
          isLoading: false,
        );
        notifyListeners();
      } else {
        _state = _state.copyWith(isLoading: false);
        notifyListeners();
      }

      _positionSub = _repository.positionStream.listen((position) {
        _state = _state.copyWith(position: position);
        notifyListeners();
      });

      _playingSub = _repository.playingStream.listen((playing) {
        _state = _state.copyWith(isPlaying: playing);
        notifyListeners();
      });

      _completionSub = _repository.completionStream.listen((_) {
        _state = _state.copyWith(isPlaying: false);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[AudioController] Error during initialization: $e');
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // ── Public getters ──

  bool get isLoading => _state.isLoading;
  bool get isPlaying => _state.isPlaying;
  bool get showLyrics => _state.showLyrics;
  Duration get position => _state.position;
  Duration get totalDuration => _state.totalDuration;
  double get progress => _state.progress;

  String get positionLabel => _repository.formatDuration(_state.position);
  String get totalDurationLabel =>
      _repository.formatDuration(_state.totalDuration);

  // ── Playback controls ──

  void togglePlayPause() {
    if (_isRealPlayback) {
      if (_state.isPlaying) {
        _repository.pause();
      } else {
        // If at end, restart from beginning
        if (_state.position >= _state.totalDuration) {
          _repository.seek(Duration.zero);
        }
        _repository.play();
      }
    } else {
      // Fallback: simulated toggle
      _state = _state.copyWith(
        isPlaying: !_state.isPlaying,
        position: (!_state.isPlaying && _state.position >= _state.totalDuration)
            ? Duration.zero
            : null,
      );
      _syncFallbackTicker();
      notifyListeners();
    }
  }

  void toggleLyrics() {
    _state = _state.copyWith(showLyrics: !_state.showLyrics);
    notifyListeners();
  }

  void seekBy(Duration delta) {
    final targetPosition = _repository.clampPosition(
      position: _state.position + delta,
      totalDuration: _state.totalDuration,
    );

    if (_isRealPlayback) {
      _repository.seek(targetPosition);
    } else {
      _state = _state.copyWith(position: targetPosition);
      notifyListeners();
    }
  }

  void scrubToRatio(double ratio) {
    final targetPosition = _repository.positionFromProgress(
      progress: ratio,
      totalDuration: _state.totalDuration,
    );

    if (_isRealPlayback) {
      _repository.seek(targetPosition);
    } else {
      _state = _state.copyWith(position: targetPosition);
      notifyListeners();
    }
  }

  void restart() {
    if (_isRealPlayback) {
      _repository.seek(Duration.zero);
      _repository.play();
    } else {
      _state = _state.copyWith(
        position: Duration.zero,
        isPlaying: false,
      );
      notifyListeners();
    }
  }

  // ── Fallback timer (simulated playback) ──

  void _syncFallbackTicker() {
    if (_state.isPlaying) {
      _startFallbackTicker();
    } else {
      _stopFallbackTicker();
    }
  }

  void _startFallbackTicker() {
    _fallbackTimer ??= Timer.periodic(_tickInterval, (_) {
      if (!_state.isPlaying) return;

      final nextPosition = _repository.clampPosition(
        position: _state.position + _tickInterval,
        totalDuration: _state.totalDuration,
      );
      final hasFinished = nextPosition >= _state.totalDuration;

      _state = _state.copyWith(
        position: nextPosition,
        isPlaying: hasFinished ? false : true,
      );

      if (hasFinished) _stopFallbackTicker();
      notifyListeners();
    });
  }

  void _stopFallbackTicker() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  // ── Lifecycle ──

  @override
  void dispose() {
    _positionSub?.cancel();
    _playingSub?.cancel();
    _completionSub?.cancel();
    _fallbackTimer?.cancel();
    if (_isRealPlayback) {
      _repository.disposePlayer();
    }
    super.dispose();
  }
}
