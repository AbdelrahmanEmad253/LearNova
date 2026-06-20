import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/navigation/main_navigation_screen.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/custom_button.dart';

class MitchyResultsScreen extends StatefulWidget {
  final String diplomaName;
  final String trackName;

  const MitchyResultsScreen({
    super.key,
    required this.diplomaName,
    required this.trackName,
  });

  @override
  State<MitchyResultsScreen> createState() => _MitchyResultsScreenState();
}

class _MitchyResultsScreenState extends State<MitchyResultsScreen> with TickerProviderStateMixin {
  late final AnimationController _diplomaFadeController;
  late final AnimationController _trackFadeController;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _diplomaFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _trackFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _diplomaFadeController.dispose();
    _trackFadeController.dispose();
    super.dispose();
  }

  Future<void> _startFadeSequence() async {
    await _diplomaFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _trackFadeController.forward();

    // Show button instead of navigating with delay
    if (mounted) {
      setState(() {
        _showButton = true;
      });
    }
  }

  void _navigateToNext() {
    AppRouter.pushReplacement(
      context,
      const MainNavigationScreen(),
      routeName: AppRoutePaths.home,
    );
  }

  List<Shadow> _createShadows(Color c, bool isDark) {
    if (isDark) {
      return [
        Shadow(color: c.withValues(alpha: 0.6), blurRadius: 20),
        Shadow(color: c.withValues(alpha: 0.3), blurRadius: 40),
      ];
    } else {
      return [
        Shadow(color: c.withValues(alpha: 0.4), blurRadius: 10),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = colors.isDark;
    
    // Mitchy speech text
    final textColor = isDark ? const Color(0xFF72F7D7) : const Color(0xFF03478E);
    final textShadows = _createShadows(textColor, isDark);

    // Diploma and Track text
    final diplomaColor = isDark ? const Color(0xFF4DB8FF) : Colors.blue.shade700;
    final trackColor = isDark ? const Color(0xFFFF71CE) : Colors.deepPurple.shade600;
    
    final diplomaShadows = _createShadows(diplomaColor, isDark);
    final trackShadows = _createShadows(trackColor, isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40), // Safe space up
                  const _MitchyAvatar(size: 180), // Bigger bouncing Mitchy
                  const Spacer(),
                  
                  // Custom Typewriter Effect
                  SizedBox(
                    height: 120,
                    child: _CustomTypewriterText(
                      text: "Hello! I am Mitchy. I have analyzed your personality, and I am your AI friend and guide.",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: textColor,
                        shadows: textShadows,
                      ),
                      textAlign: TextAlign.center,
                      onFinished: _startFadeSequence,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  _FadeSlideText(
                    text: "Your Diploma is: ${widget.diplomaName}",
                    color: diplomaColor,
                    shadows: diplomaShadows,
                    controller: _diplomaFadeController,
                  ),
                  const SizedBox(height: 16),
                  _FadeSlideText(
                    text: "Your Track is: ${widget.trackName}",
                    color: trackColor,
                    shadows: trackShadows,
                    controller: _trackFadeController,
                  ),
                  const Spacer(),
                  
                  // Start Learning Button
                  AnimatedOpacity(
                    opacity: _showButton ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: IgnorePointer(
                      ignoring: !_showButton,
                      child: CustomButton(
                        text: 'Start Learning',
                        onPressed: _navigateToNext,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MitchyAvatar extends StatefulWidget {
  final double size;
  const _MitchyAvatar({Key? key, this.size = 180}) : super(key: key);

  @override
  State<_MitchyAvatar> createState() => _MitchyAvatarState();
}

class _MitchyAvatarState extends State<_MitchyAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _translateY;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _translateY = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
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
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade300, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3 * _scale.value),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/avatar/Mitchy.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.smart_toy_rounded, size: widget.size / 2, color: Colors.blue),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomTypewriterText extends StatefulWidget {
  final String text;
  final Duration speed;
  final VoidCallback? onFinished;
  final TextStyle? style;
  final TextAlign textAlign;

  const _CustomTypewriterText({
    Key? key,
    required this.text,
    this.speed = const Duration(milliseconds: 50),
    this.onFinished,
    this.style,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  @override
  State<_CustomTypewriterText> createState() => _CustomTypewriterTextState();
}

class _CustomTypewriterTextState extends State<_CustomTypewriterText> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (!mounted) return;
      if (_currentIndex < widget.text.length) {
        setState(() {
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, _currentIndex),
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}

class _FadeSlideText extends StatelessWidget {
  final String text;
  final Color color;
  final List<Shadow>? shadows;
  final AnimationController controller;

  const _FadeSlideText({
    Key? key,
    required this.text,
    required this.color,
    this.shadows,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeIn),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: shadows,
          ),
        ),
      ),
    );
  }
}
