import 'package:flutter/material.dart';
import 'package:learnova/core/navigation/main_bottom_nav.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/features/home/presentation/screens/home_screen.dart';
import 'package:learnova/features/content/presentation/screens/mitchy_chat_screen.dart';
import 'package:learnova/features/profile/presentation/screens/profile_screen.dart';
import 'package:learnova/features/weekly_challenge/presentation/screens/weekly_challenge_screen.dart';
import 'package:learnova/features/rank/presentation/screens/rank_screen.dart';
import 'package:learnova/core/services/supabase/presence_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/features/home/presentation/providers/home_providers.dart';
import 'package:learnova/features/auth/presentation/providers/avatar_providers.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/features/profile/presentation/providers/profile_providers.dart';
import 'package:learnova/features/rank/presentation/providers/rank_providers.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  static const double _bottomNavReservedSpace = 120;
  late int _selectedIndex;
  late final PresenceService _presenceService;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _presenceService = PresenceService(Supabase.instance.client);
    _presenceService.start();
    
    Future.microtask(() {
      ref.read(activityTrackingServiceProvider).markAppOpenToday();
    });
  }

  @override
  void dispose() {
    _presenceService.stop();
    super.dispose();
  }

  List<Widget> get _pages => const [
        HomeScreen(),
        WeeklyChallengeScreen(bottomInset: _bottomNavReservedSpace),
        MitchyChatScreen(isEmbedded: true, bottomInset: _bottomNavReservedSpace),
        RankScreen(bottomInset: _bottomNavReservedSpace),
        ProfileScreen(bottomInset: _bottomNavReservedSpace),
      ];

  void _onTabSelected(int index) {
    if (index == _selectedIndex) {
      return;
    }
    
    if (index == 4) {
      ref.invalidate(studentProfileProvider);
      ref.invalidate(profileDataProvider);
    } else if (index == 3) {
      ref.invalidate(studentProfileProvider);
      ref.invalidate(rankDataProvider);
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isMapAnimating = ref.watch(isMapAnimatingProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            left: 20,
            right: 20,
            bottom: isMapAnimating ? -150 : 16,
            child: SafeArea(
              top: false,
                child: MainBottomNav(
                selectedIndex: _selectedIndex,
                onTabSelected: _onTabSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


