import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/features/assessment/domain/entities/exam_perk.dart';

/// A single perk card in the deck.
///
/// States:
/// * **idle** — compact card, shows icon + name + remaining count.
/// * **peeked** — card translates up revealing description + Cast button.
/// * **disabled** — greyed out with tooltip (non-MCQ question).
/// * **used** — "Used" badge replaces the Cast button.
/// * **loading** — spinner on the Cast button during API call.
class PerkCardWidget extends StatefulWidget {
  final ExamPerk perk;
  final int remainingCount;
  final bool isCurrentQuestionMcq;
  final bool isUsedOnCurrentQuestion;
  final bool isCasting;
  final VoidCallback onCast;

  const PerkCardWidget({
    super.key,
    required this.perk,
    required this.remainingCount,
    required this.isCurrentQuestionMcq,
    required this.isUsedOnCurrentQuestion,
    required this.isCasting,
    required this.onCast,
  });

  @override
  State<PerkCardWidget> createState() => _PerkCardWidgetState();
}

class _PerkCardWidgetState extends State<PerkCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isPeeked = false;

  late final AnimationController _peekController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _peekController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _peekController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _peekController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _peekController.dispose();
    super.dispose();
  }

  void _togglePeek() {
    setState(() => _isPeeked = !_isPeeked);
    if (_isPeeked) {
      _peekController.forward();
    } else {
      _peekController.reverse();
    }
  }

  bool get _isDisabled =>
      !widget.isCurrentQuestionMcq || widget.remainingCount <= 0;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.42;

    return AnimatedBuilder(
      animation: _peekController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: child,
        );
      },
      child: _buildCard(cardWidth),
    );
  }

  Widget _buildCard(double cardWidth) {
    return GestureDetector(
      onTap: _togglePeek,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _isDisabled && !widget.isUsedOnCurrentQuestion ? 0.45 : 1.0,
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.perk.accentColor.withValues(alpha: 0.15),
                widget.perk.accentColorAlt.withValues(alpha: 0.08),
                const Color(0xFF0B1628).withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(
              color: widget.isUsedOnCurrentQuestion
                  ? Colors.green.withValues(alpha: 0.5)
                  : widget.perk.accentColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.perk.accentColor.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Card Image Header ──
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.asset(
                      widget.perk.imageAsset,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  _buildHeader(),

                  // ── Peeked content (description + cast button) ──
                  if (_isPeeked) ...[
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildPeekedContent(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.perk.accentColor.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              '${widget.remainingCount}',
              style: TextStyle(
                color: widget.perk.accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.perk.name,
                style: const TextStyle(
                  color: ColorManager.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.remainingCount} remaining',
                style: TextStyle(
                  color: widget.remainingCount > 0
                      ? widget.perk.accentColor.withValues(alpha: 0.8)
                      : ColorManager.error.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Peek indicator arrow
        AnimatedRotation(
          turns: _isPeeked ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: ColorManager.white.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildPeekedContent() {
    return Column(
      children: [
        // Description
        Text(
          widget.perk.description,
          style: TextStyle(
            color: ColorManager.white.withValues(alpha: 0.7),
            fontSize: 11.5,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // ── Action area ──
        if (widget.isUsedOnCurrentQuestion)
          _buildUsedBadge()
        else if (!widget.isCurrentQuestionMcq)
          _buildDisabledTooltip()
        else if (widget.remainingCount <= 0)
          _buildNoPerksLabel()
        else
          _buildCastButton(),
      ],
    );
  }

  Widget _buildCastButton() {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton(
        onPressed: widget.isCasting ? null : widget.onCast,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.perk.accentColor,
          foregroundColor: const Color(0xFF0B1628),
          disabledBackgroundColor:
              widget.perk.accentColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: widget.isCasting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0B1628),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Cast Perk',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUsedBadge() {
    return Container(
      width: double.infinity,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.green.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
          SizedBox(width: 6),
          Text(
            'Used',
            style: TextStyle(
              color: Colors.green,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledTooltip() {
    return Tooltip(
      message: 'This perk is only available for MCQ questions',
      preferBelow: true,
      child: Container(
        width: double.infinity,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: ColorManager.white.withValues(alpha: 0.05),
          border: Border.all(
            color: ColorManager.white.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Text(
            'MCQ only',
            style: TextStyle(
              color: ColorManager.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoPerksLabel() {
    return Container(
      width: double.infinity,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ColorManager.error.withValues(alpha: 0.08),
        border: Border.all(
          color: ColorManager.error.withValues(alpha: 0.25),
        ),
      ),
      child: Center(
        child: Text(
          'No perks left',
          style: TextStyle(
            color: ColorManager.error.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
