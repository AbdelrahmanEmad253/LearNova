import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/features/auth/presentation/screens/avatar_selection_screen.dart';

class ConfirmEmailScreen extends ConsumerStatefulWidget {
  final String email;
  final String? password;

  const ConfirmEmailScreen({
    super.key,
    required this.email,
    this.password,
  });

  @override
  ConsumerState<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start polling every 2 seconds
    _timer = Timer.periodic(
        const Duration(seconds: 2), (_) => _checkConfirmationStatus());
    Future.microtask(_checkConfirmationStatus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkConfirmationStatus();
    }
  }

  Future<void> _checkConfirmationStatus() async {
    if (_isChecking || widget.password == null) return;
    
    // We try to sign in with the password. 
    // If it succeeds, the account is confirmed.
    // If it fails with "Email not confirmed", we just wait for the next tick.
    try {
      await ref.read(authControllerProvider.notifier).signInWithPassword(
            email: widget.email,
            password: widget.password!,
          );
      // Success is handled by the authSessionStreamProvider listener in build()
    } catch (_) {
      // Silently ignore errors during auto-polling
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending) return;
    setState(() => _isResending = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resendConfirmationEmail(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmation email resent!'),
            backgroundColor: ColorManager.accentMint,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: ${e.toString()}'),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _attemptSignIn() async {
    if (widget.password == null) return;
    try {
      setState(() => _isChecking = true);
      await ref.read(authControllerProvider.notifier).signInWithPassword(
            email: widget.email,
            password: widget.password!,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Automatically redirect when a session is detected
    ref.listen(authSessionStreamProvider, (previous, next) {
      final session = next.value;
      if (session != null) {
        _timer?.cancel();
        AppRouter.pushReplacement(
          context,
          const AvatarSelectionScreen(),
          routeName: AppRoutePaths.avatarSelection,
        );
      }
    });

    return SpaceScaffold(
      resizeToAvoidBottomInset: false,
      topWavePaths: const [
        AppAssets.wavesTop,
        AppAssets.wavesPrimeTop,
      ],
      bottomWavePaths: const [
        AppAssets.wavesPrimeBottom,
        AppAssets.wavesBottom,
      ],
      topWavesColor: colors.isDark ? null : colors.primary,
      bottomWavesColor: colors.isDark ? null : colors.primary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: colors.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Confirm Account',
                style: TextStyle(
                  color: colors.textTitle,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We sent a confirmation link to:\n${widget.email}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorManager.accentMint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Checking confirmation status...',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isResending)
                    const CircularProgressIndicator(
                        color: ColorManager.accentMint)
                  else
                    InkWell(
                      onTap: _resendEmail,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          'Resend Confirmation Email',
                          style: TextStyle(
                            color: colors.isDark ? ColorManager.accentMint : colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isChecking ? null : _attemptSignIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.buttonBackground,
                      foregroundColor: colors.buttonForeground,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _isChecking ? 'Checking...' : 'I Confirmed',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
