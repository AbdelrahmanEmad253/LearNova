import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/features/weekly_challenge/data/models/challenge_schedule_model.dart';
import 'package:learnova/features/weekly_challenge/data/repositories/challenge_repository.dart';

class WeeklyChallengeState {
  final bool isLoading;
  final bool isFoundationTrack;
  final ChallengeScheduleModel? schedule;
  final String countdownString;

  WeeklyChallengeState({
    this.isLoading = false,
    this.isFoundationTrack = false,
    this.schedule,
    this.countdownString = '',
  });

  WeeklyChallengeState copyWith({
    bool? isLoading,
    bool? isFoundationTrack,
    ChallengeScheduleModel? schedule,
    String? countdownString,
  }) {
    return WeeklyChallengeState(
      isLoading: isLoading ?? this.isLoading,
      isFoundationTrack: isFoundationTrack ?? this.isFoundationTrack,
      schedule: schedule ?? this.schedule,
      countdownString: countdownString ?? this.countdownString,
    );
  }
}

class WeeklyChallengeNotifier extends Notifier<WeeklyChallengeState> {
  Timer? _timer;

  @override
  WeeklyChallengeState build() {
    _init();
    
    ref.onDispose(() {
      _timer?.cancel();
    });

    return WeeklyChallengeState(isLoading: true);
  }

  Future<void> _init() async {
    final profileAsync = ref.watch(studentProfileProvider);
    
    if (profileAsync.isLoading) {
      return; 
    }

    final profile = profileAsync.value;
    final isFoundation = profile?.assignedTrack?.toLowerCase() == 'foundation';

    if (isFoundation) {
      state = state.copyWith(isLoading: false, isFoundationTrack: true);
      return;
    }

    final repo = ref.read(challengeRepositoryProvider);
    final schedule = await repo.getCurrentChallengeSchedule();

    state = state.copyWith(
      isLoading: false,
      isFoundationTrack: false,
      schedule: schedule,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final schedule = state.schedule;
    if (schedule == null) return;

    DateTime targetDate;
    final status = schedule.status;
    if (status == 'available' || status == 'started') {
      targetDate = schedule.expiresAt;
    } else {
      targetDate = schedule.availableFrom;
    }

    final diff = targetDate.difference(DateTime.now());
    
    if (diff.isNegative) {
      state = state.copyWith(countdownString: '00:00:00');
    } else {
      state = state.copyWith(countdownString: _formatDuration(diff));
    }
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }
}

final weeklyChallengeProvider = NotifierProvider<WeeklyChallengeNotifier, WeeklyChallengeState>(WeeklyChallengeNotifier.new);
