import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth/register_request.dart';
import '../providers/auth_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/house_theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_text_field.dart';
import '../widgets/form_section_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_form_container.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _houseKey = HouseTheme.stark.key;

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.register(
      RegisterRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        houseKey: _houseKey,
      ),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (auth.errorMessage != null) {
      SnackBarUtils.showError(context, auth.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final house = HouseTheme.fromKey(_houseKey);

    return Scaffold(
      appBar: AppBar(title: const Text('House Registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: ResponsiveFormContainer(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: house.bannerGradient,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(house.icon, color: Colors.white.withValues(alpha: 0.95), size: 28),
                        const SizedBox(height: 12),
                        Text(
                          house.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          house.motto,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Join the Realm',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choose your house and begin tracking your life with a more personal banner.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FormSectionCard(
                    title: 'Account Details',
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hint: 'Ramesh',
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                        DropdownButtonFormField<String>(
                          initialValue: _houseKey,
                          decoration: const InputDecoration(labelText: 'House Selection'),
                          items: [
                            for (final entry in HouseTheme.houses)
                              DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.displayName),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _houseKey = value);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Select a house';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
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
                          hint: 'At least 6 characters',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Create Account',
                    loadingLabel: 'Creating account...',
                    expand: true,
                    isLoading: auth.isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
