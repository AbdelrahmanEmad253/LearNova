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

class ChatSessionModel {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String title;

  const ChatSessionModel({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.title,
  });
}

class MitchyChatState {
  final List<ChatMessage> messages;
  final List<ChatSessionModel> sessions;
  final String? currentSessionId;
  final bool isTyping;
  final bool isLoadingHistory;
  final String? error;

  const MitchyChatState({
    this.messages = const [],
    this.sessions = const [],
    this.currentSessionId,
    this.isTyping = false,
    this.isLoadingHistory = false,
    this.error,
  });

  MitchyChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatSessionModel>? sessions,
    String? currentSessionId,
    bool? isTyping,
    bool? isLoadingHistory,
    String? error,
  }) {
    return MitchyChatState(
      messages: messages ?? this.messages,
      sessions: sessions ?? this.sessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isTyping: isTyping ?? this.isTyping,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error,
    );
  }
}

class MitchyChatController extends Notifier<MitchyChatState> {
  LearNovaApiService get _apiService => ref.read(learnovaApiServiceProvider);
  dynamic get _supabase => ref.read(supabaseClientProvider);

  @override
  MitchyChatState build() {
    // Optionally watch them if you want the controller to rebuild when they change
    ref.watch(learnovaApiServiceProvider);
    ref.watch(supabaseClientProvider);
    
    // We defer the fetch so it doesn't run synchronously during build
    Future.microtask(() => fetchSessions());
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
        sessionId: state.currentSessionId,
        screenContext: screenContext,
      );

      final mitchyMessage = ChatMessage(
        text: result.responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, mitchyMessage],
        currentSessionId: result.sessionId ?? state.currentSessionId,
        isTyping: false,
      );
      
      // If a new session was created, refetch the sessions list
      if (state.currentSessionId != null && 
          !state.sessions.any((s) => s.id == state.currentSessionId)) {
        fetchSessions();
      }
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

  void injectMessage({required String text, required bool isUser}) {
    final message = ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, message],
      error: null,
    );
  }

  Future<void> fetchSessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch sessions and join with their earliest chat_message to use as title
      final response = await _supabase
          .from('chat_sessions')
          .select('id, started_at, ended_at, chat_messages!inner(content, sent_at)')
          .eq('user_id', userId)
          .order('started_at', ascending: false);

      final List<ChatSessionModel> loadedSessions = [];
      for (final item in response) {
        final messagesList = item['chat_messages'] as List<dynamic>? ?? [];
        if (messagesList.isEmpty) continue;
        
        // Sort to get the first message
        messagesList.sort((a, b) => (a['sent_at'] as String).compareTo(b['sent_at'] as String));
        final title = messagesList.first['content']?.toString() ?? 'New Session';
        
        loadedSessions.add(ChatSessionModel(
          id: item['id'],
          startedAt: DateTime.parse(item['started_at']).toLocal(),
          endedAt: item['ended_at'] != null ? DateTime.parse(item['ended_at']).toLocal() : null,
          // Truncate title if it's too long
          title: title.length > 30 ? '${title.substring(0, 30)}...' : title,
        ));
      }

      state = state.copyWith(sessions: loadedSessions);

      // Auto-load the most recent session if we don't have one active
      // (This typically happens on app launch)
      if (state.currentSessionId == null && loadedSessions.isNotEmpty) {
        loadSession(loadedSessions.first.id);
      }
    } catch (e) {
      // Silently fail or log, since this is a background fetch
    }
  }

  Future<void> loadSession(String sessionId) async {
    state = state.copyWith(isLoadingHistory: true, error: null);
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('session_id', sessionId)
          .order('sent_at', ascending: true);

      final List<ChatMessage> loadedMessages = response.map<ChatMessage>((item) {
        return ChatMessage(
          text: item['content']?.toString() ?? '',
          isUser: item['role'] == 'user',
          timestamp: DateTime.parse(item['sent_at']).toLocal(),
        );
      }).toList();

      state = state.copyWith(
        messages: loadedMessages,
        currentSessionId: sessionId,
        isLoadingHistory: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        error: 'Could not load chat history.',
      );
    }
  }

  Future<void> startNewSession() async {
    // End the current session if it exists
    if (state.currentSessionId != null) {
      try {
        await _supabase
            .from('chat_sessions')
            .update({'ended_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', state.currentSessionId!);
      } catch (_) {}
    }

    state = state.copyWith(
      messages: [],
      currentSessionId: null, // Forces backend to create a new one
      error: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final mitchyChatControllerProvider =
    NotifierProvider<MitchyChatController, MitchyChatState>(
  MitchyChatController.new,
);
