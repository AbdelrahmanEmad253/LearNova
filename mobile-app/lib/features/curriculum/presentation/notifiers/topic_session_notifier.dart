import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/topic_progress_entity.dart';
import '../providers/topic_progress_provider.dart';

class TopicSessionState {
  final bool isLoading;
  final String? error;
  
  const TopicSessionState({this.isLoading = false, this.error});
  
  TopicSessionState copyWith({bool? isLoading, String? error}) {
    return TopicSessionState(
      isLoading: isLoading ?? false,
      error: error,
    );
  }
}

class TopicSessionNotifier extends Notifier<TopicSessionState> {
  TopicProgressArgs? _arg;
  late final Stopwatch _stopwatch;

  @override
  TopicSessionState build() {
    _stopwatch = Stopwatch();
    // Ensure we flush telemetry when this notifier is disposed (e.g. user leaves screen)
    ref.onDispose(() {
      flushTelemetry();
    });
    return const TopicSessionState();
  }

  void init(TopicProgressArgs arg) {
    debugPrint('[TopicSessionNotifier] init() called with topicId: ${arg.topicId}');
    if (_arg != null) return;
    _arg = arg;
  }

  Future<void> startSession() async {
    debugPrint('[TopicSessionNotifier] startSession() called');
    if (_arg == null) return;
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    
    // ARCH-RULE: Upsert student_progress status to 'in_progress' and set started_at = now()
    try {
      await ref.read(curriculumRepositoryProvider).upsertTopicStatus(
        userId: _arg!.userId,
        topicId: _arg!.topicId,
        status: TopicStatus.inProgress,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void pauseSession() {
    debugPrint('[TopicSessionNotifier] pauseSession() called');
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    }
  }

  void resumeSession() {
    debugPrint('[TopicSessionNotifier] resumeSession() called');
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
  }

  Future<void> flushTelemetry() async {
    if (_arg == null) {
      debugPrint('[TopicSessionNotifier] flushTelemetry: _arg is null! Cannot flush.');
      return;
    }
    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    debugPrint('[TopicSessionNotifier] flushTelemetry: stopwatch says $elapsedSeconds seconds.');
    if (elapsedSeconds > 0) {
      // ARCH-RULE: Take the stopwatch elapsed seconds and reset the stopwatch.
      _stopwatch.reset();
      // If we need to continue tracking, start again.
      _stopwatch.start();
      
      final log = EngagementLog(
        userId: _arg!.userId,
        topicId: _arg!.topicId,
        formatType: _arg!.formatType,
        timeSpentSeconds: elapsedSeconds,
      );
      
      try {
        // ARCH-RULE: Insert a row into content_engagement_logs (WRITE-ONLY firehose)
        await ref.read(curriculumRepositoryProvider).logTelemetry(log);
        debugPrint('[TopicSessionNotifier] Successfully flushed $elapsedSeconds seconds of telemetry.');
      } catch (e) {
        debugPrint('[TopicSessionNotifier] FAILED to flush telemetry: $e');
        // Log to a crashlytics or analytics service quietly to avoid disrupting UX
      }
    }
  }

  Future<void> consumeResource(String resourceType) async {
    if (_arg == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      // ARCH-RULE: Invoke the 'consume-resource' Edge Function
      final xp = await ref.read(curriculumRepositoryProvider).consumeResource(
        topicId: _arg!.topicId,
        resourceType: resourceType,
      );
      state = state.copyWith(isLoading: false);
      // Could show a toast or effect with `xp` here if needed by UI
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> completeTopic() async {
    if (_arg == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await flushTelemetry();
      
      // ARCH-RULE: Upsert student_progress status to 'completed' and set completed_at = now()
      await ref.read(curriculumRepositoryProvider).upsertTopicStatus(
        userId: _arg!.userId,
        topicId: _arg!.topicId,
        status: TopicStatus.completed,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final topicSessionNotifierProvider = NotifierProvider.autoDispose<TopicSessionNotifier, TopicSessionState>(
  TopicSessionNotifier.new,
);
