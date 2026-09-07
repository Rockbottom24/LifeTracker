import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/local_cache_store.dart';
import 'google_auth_service.dart';

/// Handles complete Google Drive backup and restore operations for all app data:
/// - SQLite Database (habits, quests, workouts, nutrition goals, expenses, profile)
/// - White Book / Journals JSON
/// - Journal Attached Photos / Images
/// - Meals & SharedPreferences
/// - Hive Local Cache Store
class DriveBackupService {
  DriveBackupService({required this.googleAuthService});

  final GoogleAuthService googleAuthService;

  static const _dbFileName = 'lifetracker_local.sqlite';
  static const _backupFileName = 'lifetracker_backup.sqlite';
  static const _masterBackupFileName = 'lifetracker_master_backup.json';
  static const _visibleMasterFileName = 'LifeTracker_Full_Backup.json';
  static const _metaFileName = 'backup_meta.json';
  static const _lastBackupKey = 'drive_last_backup_ts';

  /// Returns the last backup timestamp stored locally, or null.
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_lastBackupKey);
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  /// Automatically triggers a weekly backup every Sunday
  static Future<void> checkSundayAutoBackup(GoogleAuthService googleAuthService) async {
    try {
      final now = DateTime.now();
      if (now.weekday != DateTime.sunday) return;

      final prefs = await SharedPreferences.getInstance();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lastAutoBackup = prefs.getString('last_sunday_auto_backup_date');

      if (lastAutoBackup == todayKey) return;

      final driveService = DriveBackupService(googleAuthService: googleAuthService);
      final result = await driveService.backup();
      if (result.success) {
        await prefs.setString('last_sunday_auto_backup_date', todayKey);
        debugPrint('Weekly Sunday auto-backup completed successfully: $todayKey');
      }
    } catch (e) {
      debugPrint('Sunday auto-backup error: $e');
    }
  }

  /// Master Backup: Bundles SQLite DB, Journals, Photos, Meals, Hive Cache, and Prefs
  Future<DriveBackupResult> backup() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return DriveBackupResult.error('Not signed in to Google.');
      }

      final docsDir = await getApplicationDocumentsDirectory();

      // 1. Read SQLite DB file bytes
      String sqliteDbBase64 = '';
      final dbFile = await _getLocalDbFile();
      if (dbFile != null && dbFile.existsSync()) {
        final dbBytes = await dbFile.readAsBytes();
        sqliteDbBase64 = base64Encode(dbBytes);
      }

      // 2. Read Journals JSON
      String journalsJson = '';
      final journalFile = File('${docsDir.path}/white_book_entries.json');
      if (journalFile.existsSync()) {
        journalsJson = await journalFile.readAsString();
      }

      // 3. Read Attached Journal Photos
      final journalImagesMap = <String, String>{};
      final imagesFolder = Directory('${docsDir.path}/journal_images');
      if (imagesFolder.existsSync()) {
        final photoFiles = imagesFolder.listSync().whereType<File>().toList();
        for (final photo in photoFiles) {
          try {
            final filename = photo.path.split('/').last;
            final photoBytes = await photo.readAsBytes();
            journalImagesMap[filename] = base64Encode(photoBytes);
          } catch (e) {
            debugPrint('Failed to encode photo ${photo.path}: $e');
          }
        }
      }

      // 4. Read Meals & Habits Stores
      final prefs = await SharedPreferences.getInstance();
      final mealsJson = prefs.getString('offline_user_meals_store_v1') ?? '';
      final habitsJson = prefs.getString('offline_user_habits_store_v1') ?? '';

      // 5. Read Hive Cache Map
      final hiveCacheMap = _exportHiveCache();

      // 6. Read SharedPreferences Export
      final sharedPrefsMap = <String, dynamic>{};
      for (final key in prefs.getKeys()) {
        sharedPrefsMap[key] = prefs.get(key);
      }

      // Construct Master Backup Payload
      final masterPayloadMap = {
        'version': 2,
        'backedUpAt': DateTime.now().toIso8601String(),
        'sqliteDbBase64': sqliteDbBase64,
        'journalsJson': journalsJson,
        'journalImages': journalImagesMap,
        'mealsJson': mealsJson,
        'habitsJson': habitsJson,
        'hiveCache': hiveCacheMap,
        'sharedPrefs': sharedPrefsMap,
      };

      final masterJsonStr = jsonEncode(masterPayloadMap);
      final masterBytes = utf8.encode(masterJsonStr);

      // Upload Master JSON to App Data folder
      await _upsertAppDataFile(
        driveApi,
        _masterBackupFileName,
        Stream.fromIterable([masterBytes]),
        'application/json',
      );

      // Upload Metadata JSON
      final metaJson = jsonEncode({
        'backedUpAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'fileSize': masterBytes.length,
      });
      await _upsertAppDataFile(
        driveApi,
        _metaFileName,
        Stream.fromIterable([utf8.encode(metaJson)]),
        'application/json',
      );

      // Upload Visible Master Backup JSON to User's Root Drive Folder
      try {
        final rootFileList = await driveApi.files.list(
          spaces: 'drive',
          q: "name = '$_visibleMasterFileName' and 'root' in parents and trashed = false",
          $fields: 'files(id)',
        );
        final media = gd.Media(Stream.fromIterable([masterBytes]), masterBytes.length);

        if (rootFileList.files != null && rootFileList.files!.isNotEmpty) {
          await driveApi.files.update(
            gd.File(),
            rootFileList.files!.first.id!,
            uploadMedia: media,
          );
        } else {
          final visibleFileMeta = gd.File()
            ..name = _visibleMasterFileName
            ..parents = ['root'];
          await driveApi.files.create(visibleFileMeta, uploadMedia: media);
        }
      } catch (e) {
        debugPrint('Notice: Root Drive master upload skipped: $e');
      }

      // Also upload raw SQLite DB for backward compatibility if present
      if (dbFile != null && dbFile.existsSync()) {
        try {
          await _upsertAppDataFile(
            driveApi,
            _backupFileName,
            dbFile.openRead(),
            'application/octet-stream',
          );
        } catch (_) {}
      }

      // Save timestamp locally
      final now = DateTime.now();
      await prefs.setString(_lastBackupKey, now.toIso8601String());

      return DriveBackupResult.success(now);
    } catch (e) {
      debugPrint('Drive backup error: $e');
      return DriveBackupResult.error('Backup failed: $e');
    }
  }

  /// Master Restore: Restores SQLite DB, Journals, Photos, Meals, Hive Cache & Prefs
  Future<DriveRestoreResult> restore() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return DriveRestoreResult.error('Not signed in to Google.');
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final suppDir = await getApplicationSupportDirectory();

      // Check for Master Backup JSON in App Data or Root folder
      var masterFileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_masterBackupFileName'",
        $fields: 'files(id, name, modifiedTime)',
      );

      gd.File? masterFile;
      if (masterFileList.files != null && masterFileList.files!.isNotEmpty) {
        masterFile = masterFileList.files!.first;
      } else {
        masterFileList = await driveApi.files.list(
          spaces: 'drive',
          q: "name = '$_visibleMasterFileName' and 'root' in parents and trashed = false",
          $fields: 'files(id, name, modifiedTime)',
        );
        if (masterFileList.files != null && masterFileList.files!.isNotEmpty) {
          masterFile = masterFileList.files!.first;
        }
      }

      if (masterFile != null) {
        // Download Master JSON Stream
        final media = await driveApi.files.get(
          masterFile.id!,
          downloadOptions: gd.DownloadOptions.fullMedia,
        ) as gd.Media;

        final bytes = await _readStream(media.stream);
        final jsonStr = utf8.decode(bytes);
        if (jsonStr.isNotEmpty) {
          final masterMap = jsonDecode(jsonStr) as Map<String, dynamic>;

          // 1. Restore SQLite DB
          final sqliteDbBase64 = masterMap['sqliteDbBase64']?.toString() ?? '';
          if (sqliteDbBase64.isNotEmpty) {
            final dbBytes = base64Decode(sqliteDbBase64);
            final candidatePaths = [
              File('${suppDir.path}/$_dbFileName'),
              File('${docsDir.path}/$_dbFileName'),
              File('${suppDir.path}/drift/$_dbFileName'),
              File('${docsDir.path}/drift/$_dbFileName'),
            ];
            for (final dest in candidatePaths) {
              try {
                if (!dest.parent.existsSync()) {
                  dest.parent.createSync(recursive: true);
                }
                _cleanWalFiles(dest);
                await dest.writeAsBytes(dbBytes, flush: true);
                _cleanWalFiles(dest);
              } catch (e) {
                debugPrint('Failed writing DB to ${dest.path}: $e');
              }
            }
          }

          // 2. Restore Journals JSON
          final journalsJson = masterMap['journalsJson']?.toString() ?? '';
          if (journalsJson.isNotEmpty) {
            final journalFile = File('${docsDir.path}/white_book_entries.json');
            await journalFile.writeAsString(journalsJson);
          }

          // 3. Restore Attached Journal Photos / Images
          final journalImagesMap = masterMap['journalImages'];
          if (journalImagesMap is Map) {
            final imagesFolder = Directory('${docsDir.path}/journal_images');
            if (!imagesFolder.existsSync()) {
              imagesFolder.createSync(recursive: true);
            }
            for (final entry in journalImagesMap.entries) {
              try {
                final filename = entry.key.toString();
                final base64Str = entry.value.toString();
                if (filename.isNotEmpty && base64Str.isNotEmpty) {
                  final photoFile = File('${imagesFolder.path}/$filename');
                  await photoFile.writeAsBytes(base64Decode(base64Str), flush: true);
                }
              } catch (e) {
                debugPrint('Failed restoring photo ${entry.key}: $e');
              }
            }
          }

          // 4. Restore Meals & Habits JSON
          final mealsJson = masterMap['mealsJson']?.toString() ?? '';
          final habitsJson = masterMap['habitsJson']?.toString() ?? '';
          final prefs = await SharedPreferences.getInstance();
          if (mealsJson.isNotEmpty) {
            await prefs.setString('offline_user_meals_store_v1', mealsJson);
          }
          if (habitsJson.isNotEmpty) {
            await prefs.setString('offline_user_habits_store_v1', habitsJson);
          }

          // 5. Restore Hive Cache Map
          final hiveMap = masterMap['hiveCache'];
          if (hiveMap is Map) {
            await _importHiveCache(Map<String, dynamic>.from(hiveMap));
          }

          // 6. Restore SharedPreferences
          final sharedPrefsMap = masterMap['sharedPrefs'];
          if (sharedPrefsMap is Map) {
            for (final entry in sharedPrefsMap.entries) {
              final key = entry.key.toString();
              final val = entry.value;
              if (val is String) await prefs.setString(key, val);
              if (val is bool) await prefs.setBool(key, val);
              if (val is int) await prefs.setInt(key, val);
              if (val is double) await prefs.setDouble(key, val);
              if (val is List) await prefs.setStringList(key, val.map((e) => e.toString()).toList());
            }
          }

          final backupTime = DateTime.tryParse(masterMap['backedUpAt']?.toString() ?? '') ??
              masterFile.modifiedTime ??
              DateTime.now();
          return DriveRestoreResult.success(backupTime);
        }
      }

      // Fallback to legacy SQLite DB restore if Master JSON was not found
      return await _fallbackLegacyRestore(driveApi);
    } catch (e) {
      debugPrint('Drive restore error: $e');
      return DriveRestoreResult.error('Restore failed: $e');
    }
  }

  Future<DriveRestoreResult> _fallbackLegacyRestore(gd.DriveApi driveApi) async {
    try {
      var fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, name, modifiedTime)',
      );

      gd.File? backupFile;
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        backupFile = fileList.files!.first;
      } else {
        fileList = await driveApi.files.list(
          spaces: 'drive',
          q: "name = 'LifeTracker_Backup.sqlite' and 'root' in parents and trashed = false",
          $fields: 'files(id, name, modifiedTime)',
        );
        if (fileList.files != null && fileList.files!.isNotEmpty) {
          backupFile = fileList.files!.first;
        }
      }

      if (backupFile == null) {
        return DriveRestoreResult.error('No backup found in Google Drive.');
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final suppDir = await getApplicationSupportDirectory();

      final media = await driveApi.files.get(
        backupFile.id!,
        downloadOptions: gd.DownloadOptions.fullMedia,
      ) as gd.Media;

      final tempFile = File('${docsDir.path}/restore_temp.sqlite');
      final sink = tempFile.openWrite();
      await media.stream.pipe(sink);
      await sink.flush();
      await sink.close();

      final candidatePaths = [
        File('${suppDir.path}/$_dbFileName'),
        File('${docsDir.path}/$_dbFileName'),
      ];

      for (final dest in candidatePaths) {
        try {
          if (!dest.parent.existsSync()) {
            dest.parent.createSync(recursive: true);
          }
          await tempFile.copy(dest.path);
        } catch (_) {}
      }
      await tempFile.delete().catchError((_) => tempFile);

      return DriveRestoreResult.success(backupFile.modifiedTime ?? DateTime.now());
    } catch (e) {
      return DriveRestoreResult.error('Fallback restore failed: $e');
    }
  }

  /// Checks if a backup exists in Drive and returns remote info.
  Future<DriveBackupMeta?> getRemoteBackupInfo() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_metaFileName'",
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) return null;

      final metaFile = fileList.files!.first;
      final media = await driveApi.files.get(
        metaFile.id!,
        downloadOptions: gd.DownloadOptions.fullMedia,
      ) as gd.Media;

      final bytes = await _readStream(media.stream);
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      return DriveBackupMeta(
        backedUpAt: DateTime.tryParse(json['backedUpAt']?.toString() ?? '') ??
            metaFile.modifiedTime ??
            DateTime.now(),
        fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('Failed to get backup info: $e');
      return null;
    }
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  void _cleanWalFiles(File dbFile) {
    try {
      final wal = File('${dbFile.path}-wal');
      if (wal.existsSync()) wal.deleteSync();
      final shm = File('${dbFile.path}-shm');
      if (shm.existsSync()) shm.deleteSync();
    } catch (_) {}
  }

  Map<String, dynamic> _exportHiveCache() {
    final map = <String, dynamic>{};
    try {
      final box = LocalCacheStore.instance.box;
      for (final key in box.keys) {
        map[key.toString()] = box.get(key);
      }
    } catch (e) {
      debugPrint('Hive export warning: $e');
    }
    return map;
  }

  Future<void> _importHiveCache(Map<String, dynamic> hiveMap) async {
    try {
      final box = LocalCacheStore.instance.box;
      for (final entry in hiveMap.entries) {
        await box.put(entry.key, entry.value);
      }
    } catch (e) {
      debugPrint('Hive import warning: $e');
    }
  }

  Future<gd.DriveApi?> _getDriveApi() async {
    final token = await googleAuthService.getAccessToken();
    if (token == null) return null;
    final client = _AuthenticatedClient(token);
    return gd.DriveApi(client);
  }

  Future<File?> _getLocalDbFile() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final suppDir = await getApplicationSupportDirectory();

      final candidatePaths = [
        '${suppDir.path}/$_dbFileName',
        '${docsDir.path}/$_dbFileName',
        '${suppDir.path}/drift/$_dbFileName',
        '${docsDir.path}/drift/$_dbFileName',
        '${suppDir.path}/../databases/$_dbFileName',
        '${docsDir.path}/../databases/$_dbFileName',
      ];
      for (final p in candidatePaths) {
        final f = File(p);
        if (f.existsSync()) return f;
      }

      for (final dir in [suppDir, docsDir]) {
        if (!dir.existsSync()) continue;
        final dbSearch = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.sqlite') || f.path.endsWith('.db'))
            .toList();
        if (dbSearch.isNotEmpty) return dbSearch.first;
      }

      return File('${suppDir.path}/$_dbFileName');
    } catch (e) {
      debugPrint('Failed to locate DB: $e');
      return null;
    }
  }

  Future<void> _upsertAppDataFile(
    gd.DriveApi driveApi,
    String fileName,
    Stream<List<int>> content,
    String mimeType,
  ) async {
    final existing = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$fileName'",
      $fields: 'files(id)',
    );

    final bytes = await _readStream(content);
    final media = gd.Media(Stream.fromIterable([bytes]), bytes.length);

    if (existing.files != null && existing.files!.isNotEmpty) {
      await driveApi.files.update(
        gd.File(),
        existing.files!.first.id!,
        uploadMedia: media,
      );
    } else {
      final fileMetadata = gd.File()
        ..name = fileName
        ..parents = ['appDataFolder'];
      await driveApi.files.create(fileMetadata, uploadMedia: media);
    }
  }

  Future<List<int>> _readStream(Stream<List<int>> stream) async {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return chunks;
  }
}

class _AuthenticatedClient extends http.BaseClient {
  _AuthenticatedClient(this._token);
  final String _token;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class DriveBackupResult {
  const DriveBackupResult._({required this.success, this.timestamp, this.errorMessage});

  factory DriveBackupResult.success(DateTime timestamp) =>
      DriveBackupResult._(success: true, timestamp: timestamp);

  factory DriveBackupResult.error(String message) =>
      DriveBackupResult._(success: false, errorMessage: message);

  final bool success;
  final DateTime? timestamp;
  final String? errorMessage;
}

class DriveRestoreResult {
  const DriveRestoreResult._({required this.success, this.backupDate, this.errorMessage});

  factory DriveRestoreResult.success(DateTime backupDate) =>
      DriveRestoreResult._(success: true, backupDate: backupDate);

  factory DriveRestoreResult.error(String message) =>
      DriveRestoreResult._(success: false, errorMessage: message);

  final bool success;
  final DateTime? backupDate;
  final String? errorMessage;
}

class DriveBackupMeta {
  const DriveBackupMeta({required this.backedUpAt, required this.fileSize});
  final DateTime backedUpAt;
  final int fileSize;

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
