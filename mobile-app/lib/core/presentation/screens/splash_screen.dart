import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/navigation/initial_routing_screen.dart';
import 'package:learnova/features/auth/presentation/screens/login_screen.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/features/island_map/presentation/providers/island_map_providers.dart';

import '../../../features/home/presentation/providers/home_providers.dart';
import '../../theme/app_colors_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  String _displayedText = '';
  final String _fullText = 'Learnova';
  Timer? _timer;

  late AnimationController _starController;
  late Animation<double> _starScale;
  late Animation<double> _starRotation;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _starScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    );
    _starRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeOutCubic),
    );

    _startTypewriter();
  }

  void _startTypewriter() {
    int currentIndex = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (currentIndex < _fullText.length) {
        setState(() {
          _displayedText = _fullText.substring(0, currentIndex + 1);
        });

        // Trigger star animation when 'v' is typed (index 6)
        if (currentIndex == 6) {
          _starController.forward();
        }

        currentIndex++;
      } else {
        timer.cancel();
        // Wait a bit, then navigate
        Future.delayed(const Duration(milliseconds: 1500), _navigate);
      }
    });
  }

  void _navigate() {
    if (!mounted) return;
    final session = ref.read(currentSessionProvider);
    if (session != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InitialRoutingScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Preload the map data if we get a valid session during the splash screen
    ref.listen(authSessionStreamProvider, (prev, next) {
      if (next.value != null) {
        ref.read(globalMapProvider);
      }
    });

    final colors = AppColors.of(context);
    final isDark = colors.isDark;

    final textColor =
        isDark ? const Color(0xFF72F7D7) : const Color(0xFF03478E);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          Center(
            child: SizedBox(
              width: 320,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Text
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      _displayedText,
                      style: GoogleFonts.poppins(
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -1.5,
                        shadows: isDark
                            ? [
                                BoxShadow(
                                  color: textColor.withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                ),
                                BoxShadow(
                                  color: textColor.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  offset: const Offset(0, 0),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  // Star above the 'v'
                  if (_displayedText.length >= 7)
                    Positioned(
                      // Approximated position above the 'v'
                      right: 62,
                      top: 10,
                      child: AnimatedBuilder(
                        animation: _starController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _starScale.value,
                            child: Transform.rotate(
                              angle: _starRotation.value * 3.14159,
                              child: SvgPicture.asset(
                                AppAssets.starIcon,
                                width: 36,
                                height: 36,
                                colorFilter: ColorFilter.mode(
                                  textColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
