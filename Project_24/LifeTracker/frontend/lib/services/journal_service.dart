import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/journal_entry_model.dart';

class JournalService {
  static const _fileName = 'white_book_entries.json';
  static const _imagesDirName = 'journal_images';

  List<JournalEntryModel> _entries = [];
  bool _isLoaded = false;

  Future<List<JournalEntryModel>> getEntries() async {
    if (!_isLoaded) {
      await _loadFromDisk();
    }
    return List.unmodifiable(_entries);
  }

  Future<List<JournalEntryModel>> reloadFromDisk() async {
    _isLoaded = false;
    await _loadFromDisk();
    return List.unmodifiable(_entries);
  }

  Future<JournalEntryModel> createEntry({
    required String title,
    required String content,
    required DateTime date,
    required String mood,
    required String category,
    List<String> rawImagePaths = const [],
    bool isPinned = false,
  }) async {
    if (!_isLoaded) await _loadFromDisk();

    // Copy attached images to permanent local storage
    final savedImagePaths = await _copyImagesToLocalDir(rawImagePaths);

    final now = DateTime.now();
    final newEntry = JournalEntryModel(
      id: const Uuid().v4(),
      title: title.trim(),
      content: content.trim(),
      date: date,
      mood: mood,
      category: category,
      imagePaths: savedImagePaths,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );

    _entries.insert(0, newEntry);
    await _saveToDisk();
    return newEntry;
  }

  Future<JournalEntryModel?> updateEntry({
    required String id,
    String? title,
    String? content,
    DateTime? date,
    String? mood,
    String? category,
    List<String>? rawImagePaths,
    bool? isPinned,
  }) async {
    if (!_isLoaded) await _loadFromDisk();

    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return null;

    final existing = _entries[index];
    List<String>? newImagePaths;
    if (rawImagePaths != null) {
      newImagePaths = await _copyImagesToLocalDir(rawImagePaths);
    }

    final updated = existing.copyWith(
      title: title?.trim(),
      content: content?.trim(),
      date: date,
      mood: mood,
      category: category,
      imagePaths: newImagePaths,
      isPinned: isPinned,
      updatedAt: DateTime.now(),
    );

    _entries[index] = updated;
    await _saveToDisk();
    return updated;
  }

  Future<bool> deleteEntry(String id) async {
    if (!_isLoaded) await _loadFromDisk();

    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final entry = _entries.removeAt(index);
    // Delete associated image files
    for (final path in entry.imagePaths) {
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }

    await _saveToDisk();
    return true;
  }

  Future<JournalEntryModel?> togglePin(String id) async {
    if (!_isLoaded) await _loadFromDisk();
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return null;

    final existing = _entries[index];
    final updated = existing.copyWith(isPinned: !existing.isPinned);
    _entries[index] = updated;
    await _saveToDisk();
    return updated;
  }

  // ── Helper Disk Persistence ──────────────────────────────────────────────────

  Future<void> _loadFromDisk() async {
    try {
      final file = await _getJsonFile();
      if (!file.existsSync()) {
        _entries = _defaultSeedEntries();
        await _saveToDisk();
        _isLoaded = true;
        return;
      }

      final jsonStr = await file.readAsString();
      if (jsonStr.trim().isEmpty) {
        _entries = _defaultSeedEntries();
        await _saveToDisk();
        _isLoaded = true;
        return;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesFolder = Directory('${docsDir.path}/$_imagesDirName');

      final list = jsonDecode(jsonStr) as List<dynamic>;
      _entries = list
          .map((item) => JournalEntryModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .map((entry) {
            if (entry.imagePaths.isEmpty) return entry;
            final resolvedPaths = entry.imagePaths.map((p) {
              if (File(p).existsSync()) return p;
              final fileName = p.split('/').last;
              final candidate = File('${imagesFolder.path}/$fileName');
              if (candidate.existsSync()) return candidate.path;
              return p;
            }).toList();
            return entry.copyWith(imagePaths: resolvedPaths);
          })
          .toList();
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading journal entries: $e');
      _entries = _defaultSeedEntries();
      _isLoaded = true;
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final file = await _getJsonFile();
      final jsonList = _entries.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving journal entries: $e');
    }
  }

  Future<File> _getJsonFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<String>> _copyImagesToLocalDir(List<String> sourcePaths) async {
    final resultPaths = <String>[];
    final dir = await getApplicationDocumentsDirectory();
    final imagesFolder = Directory('${dir.path}/$_imagesDirName');
    if (!imagesFolder.existsSync()) {
      imagesFolder.createSync(recursive: true);
    }

    for (final src in sourcePaths) {
      final srcFile = File(src);
      if (!srcFile.existsSync()) {
        // If it's already inside local dir, keep it
        if (src.contains(_imagesDirName)) {
          resultPaths.add(src);
        }
        continue;
      }
      if (src.contains(imagesFolder.path)) {
        resultPaths.add(src);
        continue;
      }

      final ext = src.split('.').last;
      final fileName = '${const Uuid().v4()}.$ext';
      final destFile = File('${imagesFolder.path}/$fileName');
      await srcFile.copy(destFile.path);
      resultPaths.add(destFile.path);
    }

    return resultPaths;
  }

  /// Initial sample entries in GoT style so the journal isn't empty on first open!
  List<JournalEntryModel> _defaultSeedEntries() {
    final now = DateTime.now();
    return [
      JournalEntryModel(
        id: const Uuid().v4(),
        title: 'Oath of the White Book',
        content: 'I take my seat in the Great Hall. Today marks the start of a new chapter. No trial shall break my spirit, no shadow weaken my resolve. Winter may come, but my duty remains absolute.',
        date: now,
        mood: 'TRIUMPHANT',
        category: 'Personal Chronicle',
        isPinned: true,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      JournalEntryModel(
        id: const Uuid().v4(),
        title: 'The Great Training Feat',
        content: 'Conquered the morning routine. Pushed through the heavy sets and mastered the mental grind. Victory belongs to those who persevere.',
        date: now.subtract(const Duration(days: 1)),
        mood: 'FIERCE',
        category: 'Battle Log',
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
