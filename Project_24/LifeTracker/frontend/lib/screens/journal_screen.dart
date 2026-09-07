import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/journal_entry_model.dart';
import '../providers/journal_provider.dart';
import '../providers/local_auth_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/house_theme.dart';
import '../widgets/chronicle_card.dart';
import '../widgets/glass_card.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().loadEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEntryEditor({JournalEntryModel? entryToEdit}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _JournalEntryEditorSheet(entryToEdit: entryToEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final auth = context.watch<LocalAuthProvider>();
    final journal = context.watch<JournalProvider>();
    final house = auth.house;
    const gold = Color(0xFFC4B28B);

    final entries = journal.filteredEntries;
    final pinned = journal.pinnedEntries;
    final unpinned = journal.unpinnedEntries;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('White Book'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu_rounded),
            tooltip: 'Record Chronicle',
            onPressed: () => _openEntryEditor(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryEditor(),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('New Chronicle'),
        backgroundColor: gold,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async => journal.loadEntries(),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            // ── Banner Header ──────────────────────────────────────────────
            _HeroBanner(
              house: house,
              totalEntries: journal.totalEntriesCount,
              totalImages: journal.totalImagesCount,
              onCompose: () => _openEntryEditor(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Search & Filters ───────────────────────────────────────────
            _SearchAndFilterSection(
              searchController: _searchController,
              journal: journal,
              theme: theme,
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Entries List ───────────────────────────────────────────────
            if (journal.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (entries.isEmpty)
              _EmptyChronicleView(
                hasFilters: journal.selectedCategory != 'ALL' ||
                    journal.selectedMood != 'ALL' ||
                    journal.searchQuery.isNotEmpty,
                onClearFilters: () {
                  _searchController.clear();
                  journal.clearFilters();
                },
                onCompose: () => _openEntryEditor(),
                theme: theme,
              )
            else ...[
              // Pinned Entries Section
              if (pinned.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.push_pin_rounded, size: 18, color: gold),
                    const SizedBox(width: 6),
                    Text(
                      'Sealed Chronicles',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...pinned.map(
                  (e) => _JournalEntryCard(
                    entry: e,
                    theme: theme,
                    house: house,
                    onEdit: () => _openEntryEditor(entryToEdit: e),
                    onTogglePin: () => journal.togglePin(e.id),
                    onDelete: () => _confirmDelete(e.id),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Unpinned Entries Section
              if (unpinned.isNotEmpty) ...[
                if (pinned.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'All Chronicles',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ...unpinned.map(
                  (e) => _JournalEntryCard(
                    entry: e,
                    theme: theme,
                    house: house,
                    onEdit: () => _openEntryEditor(entryToEdit: e),
                    onTogglePin: () => journal.togglePin(e.id),
                    onDelete: () => _confirmDelete(e.id),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 80), // Fab spacing
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Burn Chronicle?'),
        content: const Text(
          'This entry will be permanently removed from The White Book.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<JournalProvider>().deleteEntry(id);
            },
            child: const Text('Burn Entry'),
          ),
        ],
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.house,
    required this.totalEntries,
    required this.totalImages,
    required this.onCompose,
  });

  final HouseTheme house;
  final int totalEntries;
  final int totalImages;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gold = Color(0xFFC4B28B);

    return GlassCard(
      borderRadius: 24,
      borderColor: gold.withValues(alpha: 0.35),
      borderWidth: 1.2,
      backgroundColor: Colors.black.withValues(alpha: 0.28),
      gradient: LinearGradient(
        colors: house.bannerGradient.map((c) => c.withValues(alpha: 0.38)).toList(),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories_rounded, color: gold, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'White Book',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'The Annals & Chronicles of Your House',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: gold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  house.sigil,
                  style: const TextStyle(fontSize: 32, color: Colors.white24),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StatBadge(
                  icon: Icons.book_rounded,
                  label: '$totalEntries Chronicles',
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatBadge(
                  icon: Icons.photo_library_rounded,
                  label: '$totalImages Memories',
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFC4B28B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search & Filter Bar ────────────────────────────────────────────────────────

class _SearchAndFilterSection extends StatelessWidget {
  const _SearchAndFilterSection({
    required this.searchController,
    required this.journal,
    required this.theme,
  });

  final TextEditingController searchController;
  final JournalProvider journal;
  final ThemeData theme;

  static const categories = [
    'ALL',
    'Interview Prep 💻',
    'Mistake Notebook 📓',
    'Personal Chronicle',
    'Battle Log',
    'Wisdom & Musings',
    'Journey',
    'House Matters',
  ];

  static const moods = [
    {'key': 'ALL', 'label': 'All Seals', 'icon': Icons.tune_rounded},
    {'key': 'TRIUMPHANT', 'label': '⚔️ Triumphant', 'icon': Icons.shield_rounded},
    {'key': 'STEADFAST', 'label': '🛡️ Steadfast', 'icon': Icons.security_rounded},
    {'key': 'FIERCE', 'label': '🐉 Fierce', 'icon': Icons.local_fire_department_rounded},
    {'key': 'CONTEMPLATIVE', 'label': '❄️ Calm', 'icon': Icons.ac_unit_rounded},
    {'key': 'TURBULENT', 'label': '⚡ Turbulent', 'icon': Icons.flash_on_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field
        TextField(
          controller: searchController,
          onChanged: (val) => journal.setSearchQuery(val),
          decoration: InputDecoration(
            hintText: 'Search White Book…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      searchController.clear();
                      journal.setSearchQuery('');
                    },
                  )
                : null,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final selected = journal.selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat == 'ALL' ? 'All Tags' : cat),
                  selected: selected,
                  onSelected: (_) => journal.setCategoryFilter(cat),
                  selectedColor: const Color(0xFFC4B28B).withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 6),

        // Date Filter Row
        Row(
          children: [
            ActionChip(
              avatar: Icon(
                journal.selectedDate != null ? Icons.event_available_rounded : Icons.calendar_month_rounded,
                size: 16,
                color: journal.selectedDate != null ? const Color(0xFFC4B28B) : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(
                journal.selectedDate != null
                    ? DateFormat('EEE, MMM d, yyyy').format(journal.selectedDate!)
                    : 'Filter by Date',
                style: TextStyle(
                  fontWeight: journal.selectedDate != null ? FontWeight.bold : FontWeight.normal,
                  color: journal.selectedDate != null ? const Color(0xFFC4B28B) : null,
                ),
              ),
              backgroundColor: journal.selectedDate != null
                  ? const Color(0xFFC4B28B).withValues(alpha: 0.2)
                  : null,
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: journal.selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  journal.setDateFilter(picked);
                }
              },
            ),
            if (journal.selectedDate != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () => journal.setDateFilter(null),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Entry Card ─────────────────────────────────────────────────────────────────

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.entry,
    required this.theme,
    required this.house,
    required this.onEdit,
    required this.onTogglePin,
    required this.onDelete,
  });

  final JournalEntryModel entry;
  final ThemeData theme;
  final HouseTheme house;
  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  static final _dateFormat = DateFormat('EEE, MMM d, yyyy · h:mm a');

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC4B28B);
    final moodInfo = _getMoodInfo(entry.mood);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ChronicleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Mood Seal, Category, Pinned Seal & Options Menu
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Mood Seal Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: moodInfo.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: moodInfo.color.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(moodInfo.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              moodInfo.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: moodInfo.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.category,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Pin Button
                IconButton(
                  icon: Icon(
                    entry.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 20,
                    color: entry.isPinned ? gold : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onTogglePin,
                  tooltip: entry.isPinned ? 'Unseal' : 'Seal with Gold',
                ),

                // Popup Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Entry'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Burn Entry', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              entry.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 4),

            // Date
            Text(
              _dateFormat.format(entry.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Content
            Text(
              entry.content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),

            // Attached Images Grid
            if (entry.imagePaths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _ImageGalleryGrid(imagePaths: entry.imagePaths),
            ],
          ],
        ),
      ),
    );
  }

  static _MoodInfo _getMoodInfo(String moodKey) {
    switch (moodKey.toUpperCase()) {
      case 'TRIUMPHANT':
        return _MoodInfo('⚔️', 'Triumphant', const Color(0xFFC4B28B));
      case 'STEADFAST':
        return _MoodInfo('🛡️', 'Steadfast', Colors.blue.shade400);
      case 'FIERCE':
        return _MoodInfo('🐉', 'Fierce', Colors.red.shade400);
      case 'CONTEMPLATIVE':
        return _MoodInfo('❄️', 'Calm', Colors.teal.shade300);
      case 'TURBULENT':
        return _MoodInfo('⚡', 'Turbulent', Colors.amber.shade400);
      default:
        return _MoodInfo('📜', 'Steadfast', const Color(0xFFC4B28B));
    }
  }
}

class _MoodInfo {
  const _MoodInfo(this.emoji, this.label, this.color);
  final String emoji;
  final String label;
  final Color color;
}

// ── Image Gallery Grid ─────────────────────────────────────────────────────────

class _ImageGalleryGrid extends StatelessWidget {
  const _ImageGalleryGrid({required this.imagePaths});
  final List<String> imagePaths;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final count = imagePaths.length;
        if (count == 1) {
          return _SingleImageTile(path: imagePaths.first);
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: imagePaths.map((path) {
            return _SingleImageTile(
              path: path,
              width: (constraints.maxWidth - 8) / 2,
              height: 120,
            );
          }).toList(),
        );
      },
    );
  }
}

class _SingleImageTile extends StatelessWidget {
  const _SingleImageTile({required this.path, this.width, this.height = 180});
  final String path;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final exists = file.existsSync();

    return GestureDetector(
      onTap: () {
        if (!exists) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: width,
          height: height,
          child: exists
              ? Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _errorPlaceholder(),
                )
              : _errorPlaceholder(),
        ),
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white54),
      ),
    );
  }
}

// ── Empty State View ───────────────────────────────────────────────────────────

class _EmptyChronicleView extends StatelessWidget {
  const _EmptyChronicleView({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onCompose,
    required this.theme,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onCompose;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 64,
            color: Color(0xFFC4B28B),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No Chronicles Match Your Search' : 'White Book is Empty',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try clearing your search query or seal filters.'
                : 'Every great house must record its history. Tap below to write your first entry.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasFilters)
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Clear Filters'),
            )
          else
            FilledButton.icon(
              onPressed: onCompose,
              icon: const Icon(Icons.history_edu_rounded),
              label: const Text('Record First Chronicle'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC4B28B),
                foregroundColor: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Entry Editor Sheet (Compose / Edit) ────────────────────────────────────────

class _JournalEntryEditorSheet extends StatefulWidget {
  const _JournalEntryEditorSheet({this.entryToEdit});
  final JournalEntryModel? entryToEdit;

  @override
  State<_JournalEntryEditorSheet> createState() => _JournalEntryEditorSheetState();
}

class _JournalEntryEditorSheetState extends State<_JournalEntryEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _selectedDate;
  late String _selectedMood;
  late String _selectedCategory;
  late List<String> _attachedImagePaths;
  bool _isPinned = false;

  final ImagePicker _picker = ImagePicker();

  static const categories = [
    'Personal Chronicle',
    'Battle Log',
    'Wisdom & Musings',
    'Journey',
    'House Matters',
  ];

  static const moods = [
    {'key': 'TRIUMPHANT', 'label': '⚔️ Triumphant'},
    {'key': 'STEADFAST', 'label': '🛡️ Steadfast'},
    {'key': 'FIERCE', 'label': '🐉 Fierce'},
    {'key': 'CONTEMPLATIVE', 'label': '❄️ Calm'},
    {'key': 'TURBULENT', 'label': '⚡ Turbulent'},
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.entryToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _contentController = TextEditingController(text: edit?.content ?? '');
    _selectedDate = edit?.date ?? DateTime.now();
    _selectedMood = edit?.mood ?? 'STEADFAST';
    _selectedCategory = edit?.category ?? 'Personal Chronicle';
    _attachedImagePaths = List.from(edit?.imagePaths ?? []);
    _isPinned = edit?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() {
          _attachedImagePaths.add(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for your chronicle.')),
      );
      return;
    }

    final provider = context.read<JournalProvider>();

    if (widget.entryToEdit != null) {
      provider.updateEntry(
        id: widget.entryToEdit!.id,
        title: title,
        content: content,
        date: _selectedDate,
        mood: _selectedMood,
        category: _selectedCategory,
        rawImagePaths: _attachedImagePaths,
        isPinned: _isPinned,
      );
    } else {
      provider.createEntry(
        title: title,
        content: content,
        date: _selectedDate,
        mood: _selectedMood,
        category: _selectedCategory,
        rawImagePaths: _attachedImagePaths,
        isPinned: _isPinned,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gold = Color(0xFFC4B28B);
    final isEditing = widget.entryToEdit != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Chronicle' : 'Record Chronicle',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(isEditing ? 'Update' : 'Seal'),
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Title Field
                TextField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Chronicle Title…',
                    border: InputBorder.none,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Mood Seal Selector
                Text(
                  'State of Mind (Seal)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: moods.map((m) {
                      final selected = _selectedMood == m['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(m['label'] as String),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedMood = m['key'] as String),
                          selectedColor: gold.withValues(alpha: 0.3),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Category Tag Selector
                Text(
                  'Chapter Tag',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          selectedColor: gold.withValues(alpha: 0.3),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Photo Attachments Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Memories (Photos)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.photo_library_outlined, size: 20),
                          tooltip: 'Gallery',
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.camera_alt_outlined, size: 20),
                          tooltip: 'Camera',
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_attachedImagePaths.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _attachedImagePaths.length,
                      itemBuilder: (ctx, i) {
                        final path = _attachedImagePaths[i];
                        final file = File(path);
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: file.existsSync()
                                    ? DecorationImage(
                                        image: FileImage(file),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _attachedImagePaths.removeAt(i);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Content Field
                TextField(
                  controller: _contentController,
                  maxLines: 10,
                  minLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Write your chronicle entry here…',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
