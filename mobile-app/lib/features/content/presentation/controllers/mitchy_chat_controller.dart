import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/services/learnova_api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class MitchyChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? error;

  const MitchyChatState({
    this.messages = const [],
    this.isTyping = false,
    this.error,
  });

  MitchyChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
  }) {
    return MitchyChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: error,
    );
  }
}

class MitchyChatController extends Notifier<MitchyChatState> {
  late final LearNovaApiService _apiService;

  @override
  MitchyChatState build() {
    _apiService = ref.watch(learnovaApiServiceProvider);
    return const MitchyChatState();
  }

  Future<void> sendMessage({
    required String message,
    String? topicId,
    String? moduleId,
    String screenContext = 'unknown',
  }) async {
    if (message.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: message.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      error: null,
    );

    try {
      final result = await _apiService.sendMitchyMessage(
        message: message,
        topicId: topicId,
        moduleId: moduleId,
        screenContext: screenContext,
      );

      final mitchyMessage = ChatMessage(
        text: result.responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, mitchyMessage],
        isTyping: false,
      );
    } catch (e) {
      final errorMessage = e is LearNovaApiException
          ? e.message
          : 'Mitchy is having trouble right now. Please try again.';
      state = state.copyWith(
        isTyping: false,
        error: errorMessage,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final mitchyChatControllerProvider =
    NotifierProvider<MitchyChatController, MitchyChatState>(
  MitchyChatController.new,
);
