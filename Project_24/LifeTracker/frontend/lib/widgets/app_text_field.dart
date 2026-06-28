import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
