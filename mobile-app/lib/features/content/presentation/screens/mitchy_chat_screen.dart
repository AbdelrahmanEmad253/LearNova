import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/features/content/presentation/controllers/mitchy_chat_controller.dart';

class MitchyChatScreen extends ConsumerStatefulWidget {
  /// When true, the screen is embedded inside the main bottom nav (no back arrow).
  /// When false, it's pushed as a standalone route (shows back arrow).
  final bool isEmbedded;
  final double bottomInset;
  final String? topicId;
  final String? moduleId;

  const MitchyChatScreen({
    super.key,
    this.isEmbedded = false,
    this.bottomInset = 0,
    this.topicId,
    this.moduleId,
  });

  @override
  ConsumerState<MitchyChatScreen> createState() => _MitchyChatScreenState();
}

class _MitchyChatScreenState extends ConsumerState<MitchyChatScreen> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _applySuggestion(String suggestion) {
    setState(() {
      _promptController.text = suggestion;
    });
  }

  Future<void> _sendMessage() async {
    final String text = _promptController.text.trim();
    if (text.isEmpty) return;

    final controller = ref.read(mitchyChatControllerProvider.notifier);
    _promptController.clear();
    
    await controller.sendMessage(
      message: text,
      topicId: widget.topicId,
      moduleId: widget.moduleId,
      screenContext: widget.isEmbedded ? 'dashboard' : 'topic_page',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final chatState = ref.watch(mitchyChatControllerProvider);
    final messages = chatState.messages;
    final isMitchyTyping = chatState.isTyping;
    
    final bool isSessionEnded = chatState.currentSessionId != null &&
        chatState.sessions.any((s) => s.id == chatState.currentSessionId && s.endedAt != null);

    // Listen for errors and show SnackBar
    ref.listen(mitchyChatControllerProvider.select((s) => s.error), (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: ColorManager.error),
        );
        ref.read(mitchyChatControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawerScrimColor: Colors.black.withValues(alpha: 0.2), // Lighten the scrim so the blur looks better
      endDrawer: const _ChatHistoryDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Only show the back arrow when NOT embedded in main nav
                  if (!widget.isEmbedded)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: colors.textPrimary,
                            size: 28,
                          ),
                        ),
                        Builder(
                          builder: (context) => IconButton(
                            onPressed: () => Scaffold.of(context).openEndDrawer(),
                            icon: Icon(
                              Icons.menu,
                              color: colors.textPrimary,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // When embedded, show a simple title row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'Mitchy',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• Online',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Builder(
                            builder: (context) => IconButton(
                              onPressed: () => Scaffold.of(context).openEndDrawer(),
                              icon: Icon(
                                Icons.menu,
                                color: colors.textPrimary,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: messages.isNotEmpty || isMitchyTyping
                        ? ListView.separated(
                            reverse: true,
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: messages.length + (isMitchyTyping ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (isMitchyTyping && index == 0) {
                                return const _TypingBubble();
                              }
                              final int messageIndex = isMitchyTyping ? index - 1 : index;
                              final message = messages[messages.length - 1 - messageIndex];
                              return _ChatBubble(message: message);
                            },
                          )
                        : CustomScrollView(
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Spacer(),
                                    Text(
                                      'So, got your\nquestions set?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colors.isDark ? const Color(0xFF3E4248) : Colors.grey.shade400,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w300,
                                        height: 1.2,
                                      ),
                                    ),
                                    const Spacer(),
                                    _SuggestionCard(
                                      text: 'Quick revision on\nboth topics',
                                      onTap: () {
                                        _applySuggestion('Quick revision on both topics');
                                        _sendMessage();
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _SuggestionCard(
                                      text: 'Tips to improve at\nPython scripting',
                                      onTap: () {
                                        _applySuggestion('Tips to improve at Python scripting');
                                        _sendMessage();
                                      },
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  isSessionEnded 
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          'This chat session has ended.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    : Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: colors.isDark ? const Color(0xFF262626) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: colors.borderWeak,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _promptController,
                                onChanged: (_) {
                                  setState(() {});
                                },
                                onSubmitted: (_) => _sendMessage(),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ask Mitchy!',
                                  hintStyle: TextStyle(
                                    color: colors.textSecondary.withValues(alpha: 0.6),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _promptController.text.trim().isEmpty 
                                      ? colors.isDark ? const Color(0xFF333333) : Colors.grey.shade300
                                      : colors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: _promptController.text.trim().isEmpty 
                                      ? colors.isDark ? Colors.white38 : Colors.black26
                                      : ColorManager.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 16),
                  // Extra padding for bottom nav bar when embedded
                  if (widget.isEmbedded)
                    SizedBox(height: widget.bottomInset),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionCard({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 102,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colors.cardBackground,
          border: Border.all(color: colors.borderWeak, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bool isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? (colors.isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0))
              : (colors.isDark ? const Color(0xFF1C2230) : const Color(0xFFEFF6FF)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.borderWeak,
            width: 0.5,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF1C2230) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.borderWeak,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mitchy is typing...',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ChatHistoryDrawer extends ConsumerStatefulWidget {
  const _ChatHistoryDrawer();

  @override
  ConsumerState<_ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends ConsumerState<_ChatHistoryDrawer> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final chatState = ref.watch(mitchyChatControllerProvider);

    // Filter sessions based on search query
    final filteredSessions = chatState.sessions.where((session) {
      if (_searchQuery.isEmpty) return true;
      return session.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Drawer(
      backgroundColor: Colors.transparent, // Make drawer background transparent for blur
      elevation: 0,
      child: Stack(
        children: [
          // Frosted glass effect with shadow and border
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.isDark 
                        ? Colors.black.withValues(alpha: 0.01)
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '❖ Chat History',
                    style: TextStyle(
                      color: colors.primary, // Primary color
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: colors.primary.withValues(alpha: 0.6),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: TextField(
                      style: TextStyle(color: colors.textPrimary),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                        prefixIcon: Icon(Icons.search, color: colors.textSecondary.withValues(alpha: 0.5), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    ref.read(mitchyChatControllerProvider.notifier).startNewSession();
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Icon(Icons.edit_square, color: colors.textPrimary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'New chat',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      final isSelected = session.id == chatState.currentSessionId;
                      return InkWell(
                        onTap: () {
                          ref.read(mitchyChatControllerProvider.notifier).loadSession(session.id);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2.0),
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (colors.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? colors.textPrimary : colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.keyboard_return, color: colors.textPrimary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Back to chat',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
