import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth/login_request.dart';
import '../providers/auth_provider.dart';
import '../screens/register_screen.dart';
import '../theme/app_spacing.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_text_field.dart';
import '../widgets/form_section_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_form_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.login(
      LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );

    if (!mounted) return;
    if (!ok && auth.errorMessage != null) {
      SnackBarUtils.showError(context, auth.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: ResponsiveFormContainer(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome back',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sign in to continue tracking your habits, learning, and money.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FormSectionCard(
                      title: 'Sign In',
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sectionGap),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Sign In',
                      loadingLabel: 'Signing in...',
                      expand: true,
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
                              );
                            },
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
