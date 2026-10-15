import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    authState.whenOrNull(
      error: (error, _) {
        final message = error is AppException
            ? error.message
            : 'Unable to sign in. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: BrandAtmosphere(
        intense: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SoftScaleIn(
                          child: const BrandMark(hero: true),
                        ),
                        const SizedBox(height: 18),
                        FadeRise(
                          delay: const Duration(milliseconds: 80),
                          child: Text(
                            'Dues, payments & notices — kept clear for every member.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                              fontSize: 15.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        FadeRise(
                          delay: const Duration(milliseconds: 140),
                          child: Text(
                            'Welcome back',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 36,
                              height: 1.05,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeRise(
                          delay: const Duration(milliseconds: 180),
                          child: Text(
                            'Sign in with your association email.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeRise(
                          delay: const Duration(milliseconds: 240),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: AppColors.fieldBorder.withValues(alpha: 0.7),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withValues(alpha: 0.07),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: const InputDecoration(
                                      hintText: 'you@association.org',
                                      labelText: 'Email',
                                      prefixIcon:
                                          Icon(Icons.mail_outline_rounded),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    autofillHints: const [
                                      AutofillHints.password
                                    ],
                                    decoration: InputDecoration(
                                      hintText: 'Your password',
                                      labelText: 'Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () =>
                                              context.push('/forgot-password'),
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GradientButton(
                                    label: 'Continue',
                                    isLoading: isLoading,
                                    onPressed: isLoading ? null : _submit,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeRise(
                          delay: const Duration(milliseconds: 320),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.mist,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  size: 15,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'Secure access for members and staff.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
