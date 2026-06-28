import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/add_food_page_route.dart';
import '../navigation/app_navigator.dart';
import '../providers/food_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/food/food_list_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_form_container.dart';
import '../widgets/section_title.dart';
import 'barcode_scanner_screen.dart';
import 'product_preview_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().loadFoods();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<FoodProvider>().searchFoods(value);
    });
  }

  Future<void> _openAdd({String? initialName}) async {
    await Navigator.of(context).push(
      AddFoodPageRoute(
        settings: const RouteSettings(name: '/add-food'),
        initialName: initialName,
      ),
    );
    if (mounted) {
      await context.read<FoodProvider>().loadFoods();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodProvider>();
    final theme = Theme.of(context);
    final showEmptySearch = provider.isSearchActive && provider.foods.isEmpty && !provider.isSearching;

    return Scaffold(
      appBar: AppBar(title: const Text('Royal Kitchen Pantry')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'food_screen_fab',
        onPressed: () => _openAdd(initialName: provider.searchQuery.trim().isEmpty ? null : provider.searchQuery.trim()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Food'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.loadFoods,
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
                        const SectionTitle(
                          title: 'Royal Kitchen Pantry',
                          subtitle: 'Browse system foods and manage your custom entries.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SearchBar(
                          controller: _searchController,
                          hintText: 'Search foods...',
                          leading: const Icon(Icons.search_rounded),
                          trailing: provider.searchQuery.isNotEmpty
                              ? [
                                  IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.loadFoods();
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ]
                              : null,
                          onChanged: _onSearchChanged,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final foodProvider = context.read<FoodProvider>();

                              final barcode = await navigator.push<String>(
                                MaterialPageRoute(
                                  builder: (_) => const BarcodeScannerScreen(),
                                ),
                              );

                              if (!mounted || barcode == null) return;

                              final product =
                                  await foodProvider.lookupBarcode(barcode);

                              if (!mounted) return;

                              if (product == null) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      foodProvider.errorMessage ??
                                          'Product not found',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => ProductPreviewScreen(
                                    product: product,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [

                                  CircleAvatar(
                                    radius: 26,
                                    child: Icon(Icons.qr_code_scanner),
                                  ),

                                  SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [

                                        Text(
                                          "Scan a Provision",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        SizedBox(height: 4),

                                        Text(
                                          "Instantly add packaged provisions",
                                        ),

                                      ],
                                    ),
                                  ),

                                  Icon(Icons.arrow_forward_ios),

                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (provider.isLoading && provider.foods.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: LoadingView(message: 'Loading foods...')),
                )
              else if (provider.errorMessage != null && provider.foods.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                )
              else if (showEmptySearch)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 56, color: theme.colorScheme.outline),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No matching food found.',
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            label: 'Create New Food',
                            icon: Icons.add_rounded,
                            expand: true,
                            onPressed: () => _openAdd(initialName: provider.searchQuery.trim()),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                if (!provider.isSearchActive) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                      AppSpacing.screenHorizontal,
                      AppSpacing.sm,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'System Foods',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.sm,
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                    ),
                    sliver: SliverList.separated(
                      itemCount: provider.systemFoods.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sectionGap),
                      itemBuilder: (context, index) {
                        final food = provider.systemFoods[index];
                        return FoodListCard(
                          key: ValueKey('system-${food.id}'),
                          food: food,
                          onTap: () => AppNavigator.openFoodDetails(context, food.id),
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                      AppSpacing.screenHorizontal,
                      AppSpacing.sm,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'My Foods',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  if (provider.customFoods.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        AppSpacing.sm,
                        AppSpacing.screenHorizontal,
                        AppSpacing.md,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'No custom foods yet. Tap Add Food to create one.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        AppSpacing.sm,
                        AppSpacing.screenHorizontal,
                        AppSpacing.listBottomInset,
                      ),
                      sliver: SliverList.separated(
                        itemCount: provider.customFoods.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sectionGap),
                        itemBuilder: (context, index) {
                          final food = provider.customFoods[index];
                          return FoodListCard(
                            key: ValueKey('custom-${food.id}'),
                            food: food,
                            onTap: () => AppNavigator.openFoodDetails(context, food.id),
                          );
                        },
                      ),
                    ),
                ] else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                      AppSpacing.screenHorizontal,
                      AppSpacing.listBottomInset,
                    ),
                    sliver: SliverList.separated(
                      itemCount: provider.foods.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sectionGap),
                      itemBuilder: (context, index) {
                        final food = provider.foods[index];
                        return FoodListCard(
                          key: ValueKey('search-${food.id}'),
                          food: food,
                          onTap: () => AppNavigator.openFoodDetails(context, food.id),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
