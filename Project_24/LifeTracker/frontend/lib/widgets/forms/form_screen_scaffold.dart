import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../responsive_form_container.dart';
import '../save_success_overlay.dart';

class FormScreenScaffold extends StatelessWidget {
  const FormScreenScaffold({
    super.key,
    required this.formKey,
    required this.scrollController,
    required this.onDismissKeyboard,
    required this.children,
    this.successMessage,
    this.onSuccessComplete,
  });

  final GlobalKey<FormState> formKey;
  final ScrollController scrollController;
  final VoidCallback onDismissKeyboard;
  final List<Widget> children;
  final String? successMessage;
  final VoidCallback? onSuccessComplete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: GestureDetector(
            onTap: onDismissKeyboard,
            behavior: HitTestBehavior.translucent,
            child: Form(
              key: formKey,
              child: ListView(
                controller: scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  formScrollBottomPadding(context),
                ),
                children: [
                  ResponsiveFormContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (successMessage != null && onSuccessComplete != null)
          Positioned.fill(
            child: SaveSuccessOverlay(
              message: successMessage!,
              onComplete: onSuccessComplete!,
            ),
          ),
      ],
    );
  }
}
