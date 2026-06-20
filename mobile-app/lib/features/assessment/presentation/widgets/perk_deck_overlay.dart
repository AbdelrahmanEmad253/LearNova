import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learnova/features/assessment/domain/entities/exam_perk.dart';
import 'package:learnova/features/assessment/domain/entities/perk_state.dart';
import 'package:learnova/features/assessment/presentation/providers/perk_providers.dart';
import 'package:learnova/features/assessment/presentation/widgets/perk_card_widget.dart';

/// The bottom "Deck of Cards" overlay shown during Module Exams.
///
/// Wraps a [Row] of [PerkCardWidget]s inside an animated slide-up panel.
/// The deck can be toggled via a floating tab at the bottom edge.
class PerkDeckOverlay extends ConsumerStatefulWidget {
  /// The ID of the currently displayed question.
  final String currentQuestionId;

  /// Whether the current question is MCQ.
  final bool isCurrentQuestionMcq;

  /// Callback invoked after a successful perk cast so the parent screen
  /// can apply the visual effect (hint/elimination).
  final VoidCallback? onPerkCast;

  const PerkDeckOverlay({
    super.key,
    required this.currentQuestionId,
    required this.isCurrentQuestionMcq,
    this.onPerkCast,
  });

  @override
  ConsumerState<PerkDeckOverlay> createState() => _PerkDeckOverlayState();
}

class _PerkDeckOverlayState extends ConsumerState<PerkDeckOverlay>
    with SingleTickerProviderStateMixin {
  bool _isDeckOpen = false;

  late final AnimationController _deckController;
  late final Animation<Offset> _deckSlide;

  @override
  void initState() {
    super.initState();

    _deckController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _deckSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _deckController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    // Initialize perk inventory on first mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(perkDeckViewModelProvider.notifier).initialise();
    });
  }

  @override
  void dispose() {
    _deckController.dispose();
    super.dispose();
  }

  void _toggleDeck() {
    setState(() => _isDeckOpen = !_isDeckOpen);
    if (_isDeckOpen) {
      _deckController.forward();
    } else {
      _deckController.reverse();
    }
  }

  Future<void> _onCastPerk(ExamPerk perk) async {
    final vm = ref.read(perkDeckViewModelProvider.notifier);
    final success = await vm.castPerk(
      perk: perk,
      questionId: widget.currentQuestionId,
      currentQuestionType: widget.isCurrentQuestionMcq ? 'mcq' : 'open',
    );

    if (success) {
      widget.onPerkCast?.call();
      // Auto-close the deck after a short delay so the user sees the effect.
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _isDeckOpen) {
          _toggleDeck();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deckState = ref.watch(perkDeckViewModelProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Don't render until initialised.
    if (!deckState.isInitialised) return const SizedBox.shrink();

    // Listen for errors and show SnackBar.
    ref.listen<PerkDeckState>(perkDeckViewModelProvider, (prev, next) {
      if (next.lastError != null && next.lastError != prev?.lastError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.lastError!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(perkDeckViewModelProvider.notifier).clearError();
      }
    });

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Toggle tab ──
          GestureDetector(
            onTap: _toggleDeck,
            child: _buildToggleTab(deckState),
          ),

          // ── Sliding deck ──
          SlideTransition(
            position: _deckSlide,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                bottomPadding + 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0B1628).withValues(alpha: 0.92),
                    const Color(0xFF041C32),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: deckState.perks.map((perk) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: PerkCardWidget(
                        perk: perk,
                        remainingCount: deckState.remainingForPerk(perk.id),
                        isCurrentQuestionMcq: widget.isCurrentQuestionMcq,
                        isUsedOnCurrentQuestion: deckState.isPerkUsedOnQuestion(
                          perk.id,
                          widget.currentQuestionId,
                        ),
                        isCasting: deckState.castingPerkId == perk.id,
                        onCast: () => _onCastPerk(perk),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(PerkDeckState deckState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1628).withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border.all(
          color: const Color(0xFF72F7D7).withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF72F7D7).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.style_rounded,
            color: Color(0xFF72F7D7),
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            'Perks',
            style: TextStyle(
              color: Color(0xFF72F7D7),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          // Remaining total badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF72F7D7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${deckState.remaining.values.fold<int>(0, (a, b) => a + b)}',
              style: const TextStyle(
                color: Color(0xFF72F7D7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedRotation(
            turns: _isDeckOpen ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Color(0xFF72F7D7),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
