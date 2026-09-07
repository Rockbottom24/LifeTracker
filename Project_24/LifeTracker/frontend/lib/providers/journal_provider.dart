import 'package:flutter/foundation.dart';

import '../models/journal_entry_model.dart';
import '../services/journal_service.dart';

class JournalProvider extends ChangeNotifier {
  JournalProvider(this._service);

  final JournalService _service;

  bool isLoading = false;
  String? errorMessage;
  List<JournalEntryModel> _entries = [];
  String selectedCategory = 'ALL';
  String selectedMood = 'ALL';
  String searchQuery = '';
  DateTime? selectedDate;

  List<JournalEntryModel> get allEntries => _entries;

  List<JournalEntryModel> get filteredEntries {
    return _entries.where((entry) {
      if (selectedCategory != 'ALL' && entry.category != selectedCategory) {
        return false;
      }
      if (selectedMood != 'ALL' && entry.mood != selectedMood) {
        return false;
      }
      if (selectedDate != null) {
        if (entry.date.year != selectedDate!.year ||
            entry.date.month != selectedDate!.month ||
            entry.date.day != selectedDate!.day) {
          return false;
        }
      }
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final inTitle = entry.title.toLowerCase().contains(query);
        final inContent = entry.content.toLowerCase().contains(query);
        final inCategory = entry.category.toLowerCase().contains(query);
        if (!inTitle && !inContent && !inCategory) return false;
      }
      return true;
    }).toList();
  }

  List<JournalEntryModel> get pinnedEntries =>
      filteredEntries.where((e) => e.isPinned).toList();

  List<JournalEntryModel> get unpinnedEntries =>
      filteredEntries.where((e) => !e.isPinned).toList();

  int get totalEntriesCount => _entries.length;

  int get totalImagesCount =>
      _entries.fold(0, (sum, entry) => sum + entry.imagePaths.length);

  Future<void> loadEntries() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _entries = await _service.getEntries();
    } catch (e) {
      errorMessage = 'Failed to load White Book chronicles: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadFromDisk() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _entries = await _service.reloadFromDisk();
    } catch (e) {
      errorMessage = 'Failed to reload White Book chronicles: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createEntry({
    required String title,
    required String content,
    required DateTime date,
    required String mood,
    required String category,
    List<String> rawImagePaths = const [],
    bool isPinned = false,
  }) async {
    try {
      final entry = await _service.createEntry(
        title: title,
        content: content,
        date: date,
        mood: mood,
        category: category,
        rawImagePaths: rawImagePaths,
        isPinned: isPinned,
      );
      _entries = [entry, ..._entries];
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to record chronicle: $e';
      notifyListeners();
    }
  }

  Future<void> updateEntry({
    required String id,
    String? title,
    String? content,
    DateTime? date,
    String? mood,
    String? category,
    List<String>? rawImagePaths,
    bool? isPinned,
  }) async {
    try {
      final updated = await _service.updateEntry(
        id: id,
        title: title,
        content: content,
        date: date,
        mood: mood,
        category: category,
        rawImagePaths: rawImagePaths,
        isPinned: isPinned,
      );
      if (updated != null) {
        final index = _entries.indexWhere((e) => e.id == id);
        if (index != -1) {
          _entries[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      errorMessage = 'Failed to update chronicle: $e';
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final success = await _service.deleteEntry(id);
      if (success) {
        _entries.removeWhere((e) => e.id == id);
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to delete entry: $e';
      notifyListeners();
    }
  }

  Future<void> togglePin(String id) async {
    try {
      final updated = await _service.togglePin(id);
      if (updated != null) {
        final index = _entries.indexWhere((e) => e.id == id);
        if (index != -1) {
          _entries[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      errorMessage = 'Failed to toggle seal: $e';
      notifyListeners();
    }
  }

  void setCategoryFilter(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setMoodFilter(String mood) {
    selectedMood = mood;
    notifyListeners();
  }

  void setDateFilter(DateTime? date) {
    selectedDate = date;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    selectedCategory = 'ALL';
    selectedMood = 'ALL';
    searchQuery = '';
    selectedDate = null;
    notifyListeners();
  }
}
