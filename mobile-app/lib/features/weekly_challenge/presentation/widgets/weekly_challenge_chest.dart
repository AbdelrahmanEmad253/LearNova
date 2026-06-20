import 'package:flutter/material.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/features/weekly_challenge/presentation/providers/weekly_challenge_provider.dart';

class WeeklyChallengeChest extends StatefulWidget {
  final WeeklyChallengeState state;

  const WeeklyChallengeChest({super.key, required this.state});

  @override
  State<WeeklyChallengeChest> createState() => _WeeklyChallengeChestState();
}

class _WeeklyChallengeChestState extends State<WeeklyChallengeChest> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _checkState();
  }

  @override
  void didUpdateWidget(WeeklyChallengeChest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.schedule?.status != widget.state.schedule?.status) {
      _checkState();
    }
  }

  void _checkState() {
    final schedule = widget.state.schedule;
    if (schedule != null && schedule.status == 'passed') {
      final score = schedule.bestScore ?? 0;
      if (score >= 90) {
        if (!_isOpen) {
          setState(() {
            _isOpen = true;
          });
          _controller.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final schedule = widget.state.schedule;
    
    // Determine the glow color based on state
    Color glowStrong = const Color(0xFF00FFB2).withValues(alpha: 0.6); // Mint glow
    Color glowSoft = const Color(0xFF00FFB2).withValues(alpha: 0.3);
    
    if (schedule?.status == 'locked') {
      glowStrong = colors.textSecondary.withValues(alpha: 0.4);
      glowSoft = colors.textSecondary.withValues(alpha: 0.2);
    } else if (schedule?.status == 'failed') {
      glowStrong = Colors.red.withValues(alpha: 0.6);
      glowSoft = Colors.red.withValues(alpha: 0.3);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: -6,
              child: Container(
                width: 244,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: glowStrong,
                      blurRadius: 34,
                      spreadRadius: 8,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: glowSoft,
                      blurRadius: 56,
                      spreadRadius: 8,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
              ),
            ),
            ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _isOpen
                    ? Column(
                        key: const ValueKey('open'),
                        children: [
                          Image.asset(
                            AppAssets.perkOwl, // Representing the perk
                            width: 180,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: const Text(
                              'Unlocked: Wisdom Perk!',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Image.asset(
                        AppAssets.questChestPng,
                        key: const ValueKey('closed'),
                        width: 258,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
