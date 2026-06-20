import 'package:flutter/material.dart';

import 'package:learnova/features/assessment/domain/entities/exam_perk.dart';

/// A quick visual effect played over the question area when a perk is
/// successfully cast.
///
/// Shows a expanding circle flash of the perk's accent colour plus a
/// scaling icon, then auto-dismisses after ~800 ms.
class PerkCastEffect extends StatefulWidget {
  /// Which perk was just cast — determines colour and icon.
  final ExamPerk perk;

  /// Called when the effect animation finishes so the parent can remove
  /// this widget from the tree.
  final VoidCallback onComplete;

  const PerkCastEffect({
    super.key,
    required this.perk,
    required this.onComplete,
  });

  @override
  State<PerkCastEffect> createState() => _PerkCastEffectState();
}

class _PerkCastEffectState extends State<PerkCastEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // longer duration for a card throw
    );

    // Slide up from bottom to center
    _slide = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: const Offset(0, 1.5), end: const Offset(0, -0.1)).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: const Offset(0, -0.1), end: const Offset(0, 0)).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: const Offset(0, 0), end: const Offset(0, -0.2)).chain(CurveTween(curve: Curves.easeInCubic)), weight: 40),
    ]).animate(_controller);

    // Scale up slightly then scale down to disappear
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 40),
    ]).animate(_controller);

    // Fade in quickly, stay, then fade out
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SlideTransition(
          position: _slide,
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Optional glow behind the card
                  Container(
                    width: 140,
                    height: 200,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: widget.perk.accentColor.withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // The Playcard Image
                  Image.asset(
                    widget.perk.imageAsset,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
