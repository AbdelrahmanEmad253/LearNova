import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/navigation/initial_routing_screen.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/utils/input_validators.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/features/auth/presentation/screens/signup_screen.dart';
import 'package:learnova/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learnova/core/constants/app_assets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool returnOnSuccess;

  const LoginScreen({super.key, this.returnOnSuccess = false});

  const LoginScreen.returning({super.key}) : returnOnSuccess = true;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool get _canLogin =>
      InputValidators.isValidEmail(_emailController.text) &&
      _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (widget.returnOnSuccess && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        AppRouter.pushReplacement(context, const InitialRoutingScreen());
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), backgroundColor: ColorManager.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final colors = AppColors.of(context);

    return SpaceScaffold(
      topWavePaths: const [
        AppAssets.wavesTop2,
        AppAssets.wavesPrimeTop2,
      ],
      bottomWavePaths: const [
        AppAssets.wavesBottom2,
        AppAssets.wavesPrimeBottom2,
      ],
      topWavesColor: colors.isDark ? null : colors.primary,
      bottomWavesColor: colors.isDark ? null : colors.primary,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              bottom: keyboardHeight + 32,
            ),
            child: Column(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Password',
                  controller: _passwordController,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  onToggleVisibility: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        AppRouter.push(
                          context,
                          const ForgotPasswordScreen(),
                          routeName: AppRoutePaths.forgotPassword,
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (isLoading)
                  const CircularProgressIndicator()
                else
                  CustomButton(
                    text: 'Login',
                    onPressed: _canLogin ? _login : null,
                  ),

                const SizedBox(height: 64),

                // Custom OR Divider
                Row(
                  children: [
                    _buildDot(),
                    const Expanded(
                      child: Divider(
                        color: ColorManager.borderSoft,
                        thickness: 1,
                        indent: 0,
                        endIndent: 16,
                      ),
                    ),
                    Text(
                      'or',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: ColorManager.borderSoft,
                        thickness: 1,
                        indent: 16,
                        endIndent: 0,
                      ),
                    ),
                    _buildDot(),
                  ],
                ),

                const SizedBox(height: 64),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: SignInButton(
                    Buttons.google,
                    text: "Sign up with Google",
                    onPressed: () async {
                      try {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle();
                        if (widget.returnOnSuccess && mounted) {
                          Navigator.of(context).pop(true);
                        } else if (mounted) {
                          AppRouter.pushReplacement(
                            context,
                            const InitialRoutingScreen(),
                          );
                        }
                      } on AuthException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(e.message),
                                backgroundColor: ColorManager.error),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: ColorManager.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: SignInButton(
                    Buttons.facebookNew,
                    text: "Sign up with Facebook",
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .signInWithFacebook();
                      if (widget.returnOnSuccess && mounted) {
                        Navigator.of(context).pop(true);
                      } else if (mounted) {
                        AppRouter.pushReplacement(
                          context,
                          const InitialRoutingScreen(),
                        );
                      }}
                  ),
                ),

                const SizedBox(height: 48),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New Member? ',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        AppRouter.pushReplacement(
                          context,
                          const SignupScreen(),
                          routeName: AppRoutePaths.signup,
                        );
                      },
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      ' here!',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot() {
    final colors = AppColors.of(context);

    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: colors.textPrimary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    ValueChanged<String>? onChanged,
  }) {
    final colors = AppColors.of(context);

    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.borderSoft),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.textPrimary),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: colors.textSecondary,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
}
