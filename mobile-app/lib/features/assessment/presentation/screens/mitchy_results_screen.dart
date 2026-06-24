import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/navigation/main_navigation_screen.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/custom_button.dart';

class MitchyResultsScreen extends StatefulWidget {
  final String userName;
  final String learningStyle;
  final String trackName;

  const MitchyResultsScreen({
    super.key,
    required this.userName,
    required this.learningStyle,
    required this.trackName,
  });

  @override
  State<MitchyResultsScreen> createState() => _MitchyResultsScreenState();
}

class _MitchyResultsScreenState extends State<MitchyResultsScreen> with TickerProviderStateMixin {
  int _step = 0;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _startStep();
  }

  void _startStep() async {
    setState(() {
      _showButton = false;
    });

    if (_step == 1 || _step == 2) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _showButton = true;
        });
      }
    }
  }

  void _onNextPressed() async {
    if (_step < 2) {
      setState(() {
        _showButton = false;
      });
      await Future.delayed(const Duration(milliseconds: 600)); // wait for button slide
      if (mounted) {
        setState(() {
          _step++;
        });
        _startStep();
      }
    } else {
      _navigateToNext();
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

  String _getLearningStyleSubtext() {
    final style = widget.learningStyle.toLowerCase();
    if (style.contains('visual')) {
      return "You learn best through images, charts, and spatial understanding.";
    } else if (style.contains('auditory')) {
      return "You learn best through listening, speaking, and sound.";
    } else if (style.contains('read') || style.contains('write')) {
      return "You learn best through reading texts and writing notes.";
    } else if (style.contains('kinesthetic')) {
      return "You learn best through hands-on experience and practice.";
    }
    return "You have a unique and blended way of learning.";
  }

  String _getTrackSubtext() {
    final track = widget.trackName.toLowerCase();
    if (track.contains('analysis')) {
      return "Discover the stories hidden within data and drive decisions.";
    } else if (track.contains('engineering')) {
      return "Build the robust pipelines that power modern data platforms.";
    } else if (track.contains('science')) {
      return "Apply advanced algorithms to predict the future and create AI.";
    } else if (track.contains('software')) {
      return "Design and build software systems that solve real world problems.";
    }
    return "Explore various fields to find your perfect technical path.";
  }

  Widget _buildStepContent(Color textColor, List<Shadow> textShadows, Color styleColor, List<Shadow> styleShadows, Color trackColor, List<Shadow> trackShadows) {
    if (_step == 0) {
      return SizedBox(
        key: const ValueKey(0),
        height: 140,
        child: Center(
          child: _CustomTypewriterText(
            text: "Hi ${widget.userName}! I am Mitchy. I have analyzed your personality, and I am your AI friend and guide.",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: textColor,
              shadows: textShadows,
            ),
            textAlign: TextAlign.center,
            onFinished: () {
              if (mounted) {
                setState(() {
                  _showButton = true;
                });
              }
            },
          ),
        ),
      );
    } else if (_step == 1) {
      return Column(
        key: const ValueKey(1),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Your Learning Style is:",
            style: TextStyle(color: styleColor, fontSize: 22, fontWeight: FontWeight.w600, shadows: styleShadows),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.learningStyle,
            style: TextStyle(color: styleColor, fontSize: 36, fontWeight: FontWeight.bold, shadows: styleShadows),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            _getLearningStyleSubtext(),
            style: TextStyle(color: textColor, fontSize: 18, height: 1.4, shadows: textShadows),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey(2),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Your Track is:",
            style: TextStyle(color: trackColor, fontSize: 22, fontWeight: FontWeight.w600, shadows: trackShadows),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.trackName,
            style: TextStyle(color: trackColor, fontSize: 36, fontWeight: FontWeight.bold, shadows: trackShadows),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            _getTrackSubtext(),
            style: TextStyle(color: textColor, fontSize: 18, height: 1.4, shadows: textShadows),
            textAlign: TextAlign.center,
          ),
        ],
      );
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
    final learningStyleColor = ColorManager.accentCyan;
    final trackColor = ColorManager.subtitlesActive;
    
    final learningStyleShadows = _createShadows(learningStyleColor, isDark);
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
                  const SizedBox(height: 40),
                  const _MitchyAvatar(size: 240), // Increased Mitchy size to 240
                  const Spacer(),
                  
                  // Animated Step Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    child: _buildStepContent(textColor, textShadows, learningStyleColor, learningStyleShadows, trackColor, trackShadows),
                  ),
                  
                  const Spacer(),
                  
                  // Start Learning Button sliding down/up
                  AnimatedSlide(
                    offset: Offset(0, _showButton ? 0 : 3.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedOpacity(
                      opacity: _showButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: IgnorePointer(
                        ignoring: !_showButton,
                        child: CustomButton(
                          text: _step == 2 ? 'Start Learning' : 'Next',
                          onPressed: _onNextPressed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
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
  const _MitchyAvatar({Key? key, this.size = 240}) : super(key: key);

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
    final colors = AppColors.of(context);

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
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.5 * _scale.value),
                    blurRadius: 40,
                    spreadRadius: 10,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/avatar/Mitchy.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.smart_toy_rounded, size: widget.size / 2, color: colors.primary),
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
