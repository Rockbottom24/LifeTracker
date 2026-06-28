import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../empty_state.dart';
import '../loading_view.dart';
import '../responsive_form_container.dart';
import '../section_title.dart';

class AsyncEntityListBody extends StatelessWidget {
  const AsyncEntityListBody({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.errorMessage,
    required this.onRefresh,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.loadingMessage,
    required this.errorTitle,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyActionLabel,
    required this.onEmptyAction,
    required this.itemCount,
    required this.itemBuilder,
    this.topBanner,
  });

  final bool isLoading;
  final bool isEmpty;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final String headerTitle;
  final String headerSubtitle;
  final String loadingMessage;
  final String errorTitle;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String emptyActionLabel;
  final VoidCallback onEmptyAction;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget? topBanner;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.xl,
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: ResponsiveFormContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?topBanner,
                    SectionTitle(
                      title: headerTitle,
                      subtitle: headerSubtitle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading && isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: LoadingView(message: loadingMessage)),
            )
          else if (errorMessage != null && isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: errorTitle,
                  message: errorMessage!,
                  actionLabel: 'Retry',
                  onAction: onRefresh,
                ),
              ),
            )
          else if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  icon: emptyIcon,
                  title: emptyTitle,
                  message: emptyMessage,
                  actionLabel: emptyActionLabel,
                  onAction: onEmptyAction,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.listBottomInset,
              ),
              sliver: SliverList.separated(
                itemCount: itemCount,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sectionGap),
                itemBuilder: itemBuilder,
              ),
            ),
        ],
      ),
    );
  }
}
