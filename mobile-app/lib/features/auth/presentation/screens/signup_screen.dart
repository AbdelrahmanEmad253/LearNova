import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/utils/input_validators.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/features/auth/presentation/screens/login_screen.dart';
import 'package:learnova/features/auth/presentation/screens/confirm_email_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learnova/core/constants/app_assets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool get _canContinue {
    final usernameValid = InputValidators.hasMinLength(
      _usernameController.text,
      3,
    );
    final emailValid = InputValidators.isValidEmail(_emailController.text);
    final passwordValid = InputValidators.hasMinLength(
      _passwordController.text,
      6,
    );
    final passwordsMatch =
        _passwordController.text == _confirmPasswordController.text;

    return usernameValid &&
        emailValid &&
        passwordValid &&
        passwordsMatch &&
        _agreeToTerms;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text,
            password: _passwordController.text,
            username: _usernameController.text,
          );
      if (mounted) {
        AppRouter.push(
          context,
          ConfirmEmailScreen(
            email: _emailController.text,
            password: _passwordController.text,
          ),
          routeName: AppRoutePaths.confirmEmail,
        );
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final colors = AppColors.of(context);

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
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
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
                            'Sign Up',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        _buildTextField(
                          label: 'Full Name',
                          controller: _usernameController,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 24),
                        _buildTextField(
                          label: 'Confirm Password',
                          controller: _confirmPasswordController,
                          isPassword: true,
                          obscureText: _obscureConfirmPassword,
                          onChanged: (_) => setState(() {}),
                          onToggleVisibility: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) => setState(
                                () => _agreeToTerms = value ?? false,
                              ),
                              side: BorderSide(color: colors.textPrimary),
                              checkColor: colors.buttonForeground,
                              activeColor: colors.buttonBackground,
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the terms and conditions',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have account? ',
                              style: TextStyle(color: colors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () {
                                AppRouter.pushReplacement(
                                  context,
                                  const LoginScreen(),
                                  routeName: AppRoutePaths.login,
                                );
                              },
                              child: Text(
                                'Login',
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
                        const SizedBox(height: 24),
                        if (_isLoading)
                          CircularProgressIndicator(color: colors.textPrimary)
                        else
                          CustomButton(
                            text: 'Save & Continue',
                            backgroundColor: colors.buttonBackground,
                            textColor: colors.buttonForeground,
                            onPressed: _canContinue ? _signUp : null,
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
