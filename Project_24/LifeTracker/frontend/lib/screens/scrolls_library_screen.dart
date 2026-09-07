import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/scroll_templates_data.dart';
import '../models/create_habit_request.dart';
import '../models/scroll_quest_template.dart';
import '../providers/habit_provider.dart';
import '../theme/app_spacing.dart';

class ScrollsLibraryScreen extends StatefulWidget {
  const ScrollsLibraryScreen({super.key});

  @override
  State<ScrollsLibraryScreen> createState() => _ScrollsLibraryScreenState();
}

class _ScrollsLibraryScreenState extends State<ScrollsLibraryScreen> {
  String _selectedCategory = 'All';

  List<String> get _categories => [
        'All',
        'TCS ➔ Product MNC',
        'Atomic Habits',
        'Deep Work',
        'Can\'t Hurt Me',
        '7 Habits',
      ];

  List<ScrollQuestTemplate> get _filteredTemplates {
    if (_selectedCategory == 'All') {
      return ScrollTemplatesData.templates;
    }
    return ScrollTemplatesData.templates
        .where((t) => t.authorOrCategory == _selectedCategory)
        .toList();
  }

  Future<void> _addQuest(ScrollQuestTemplate template) async {
    final provider = context.read<HabitProvider>();
    final categories = provider.categories;

    // Find matching category ID or fallback to first available
    int categoryId = 1;
    if (categories.isNotEmpty) {
      final matched = categories.firstWhere(
        (c) => c.code == template.categoryCode,
        orElse: () => categories.first,
      );
      categoryId = matched.id;
    }

    final req = CreateHabitRequest(
      habitCategoryId: categoryId,
      name: template.title,
      description: template.description,
      startDate: DateTime.now(),
      frequency: template.frequency.apiValue,
      reminderTime: DateTime(2026, 1, 1, 9, 0),
      notificationsEnabled: false,
      iconName: 'scroll',
      colorHex: '#C4B28B',
      points: template.xpReward,
    );

    final created = await provider.createHabit(req);
    final success = created != null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✨ Quest "${template.title}" added to Daily Quests! (+${template.xpReward} XP upon completion)'
                : 'Failed to add quest template.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const goldColor = Color(0xFFC4B28B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrolls Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: goldColor),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('About Scrolls Library'),
                  content: const Text(
                    'Scrolls Library contains self-help quest templates from famous books (Atomic Habits, Deep Work, Can\'t Hurt Me, 7 Habits) and tech job switch campaigns.\n\nTap "+ Add Quest" to add any scroll to your active Daily Quests!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Got it!'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Selector Chips
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: goldColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : scheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Templates List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _filteredTemplates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final template = _filteredTemplates[index];
                  final provider = context.watch<HabitProvider>();
                  final existingList = provider.habits.where((h) => h.name == template.title).toList();
                  final existing = existingList.isNotEmpty ? existingList.first : null;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: template.badgeColor.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: template.badgeColor.withValues(alpha: 0.2),
                              child: Icon(template.icon, color: template.badgeColor, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${template.authorOrCategory} • ${template.timeframeLabel}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: template.badgeColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: goldColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+${template.xpReward} XP',
                                style: const TextStyle(
                                  color: goldColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          template.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (existing != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8A65).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFF8A65).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '🔥 ${existing.currentStreak} Day Streak (Active)',
                                  style: const TextStyle(
                                    color: Color(0xFFFF8A65),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: template.badgeColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _addQuest(template),
                              icon: Icon(existing != null ? Icons.check_circle_rounded : Icons.bookmark_add_rounded, size: 16),
                              label: Text(
                                existing != null ? 'Add Again +' : 'Add Quest',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
