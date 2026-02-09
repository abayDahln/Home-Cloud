import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import '../models/backup_config.dart';
import '../models/system_info.dart';
import '../../../core/network/retry_interceptor.dart';
import '../../auth/providers/auth_provider.dart';

final backupSettingsProvider =
    StateNotifierProvider<BackupSettingsNotifier, BackupSettings>((ref) {
  return BackupSettingsNotifier();
});

class BackupSettingsNotifier extends StateNotifier<BackupSettings> {
  static const _key = 'backup_settings';

  BackupSettingsNotifier() : super(BackupSettings(folders: [])) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      state = BackupSettings.fromJson(jsonDecode(jsonStr));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void updateSettings(BackupSettings settings) {
    state = settings;
    _save();
  }

  void addFolder(BackupFolder folder) {
    state = state.copyWith(folders: [...state.folders, folder]);
    _save();
  }

  void removeFolder(int index) {
    final newFolders = List<BackupFolder>.from(state.folders)..removeAt(index);
    state = state.copyWith(folders: newFolders);
    _save();
  }

  void toggleFolder(int index, bool enabled) {
    final newFolders = List<BackupFolder>.from(state.folders);
    newFolders[index] = BackupFolder(
      localPath: newFolders[index].localPath,
      serverPath: newFolders[index].serverPath,
      isEnabled: enabled,
    );
    state = state.copyWith(folders: newFolders);
    _save();
  }

  void reset() {
    state = BackupSettings(folders: []);
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final service = BackupService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

final syncStatusProvider = StateProvider<bool>((ref) => false);

class BackupService {
  final Ref _ref;
  final Map<String, StreamSubscription> _subscriptions = {};
  CancelToken? _currentSyncToken;
  final Dio _backupDio;
  final Map<String, String> _syncHistory = {};
  static const _historyKey = 'sync_history';

  bool get isSyncing => _ref.read(syncStatusProvider);

  BackupService(this._ref) : _backupDio = _createBackupDio(_ref) {
    _loadHistory().then((_) {
      // On Android, foreground service handles background sync
      // Only use file watcher on desktop platforms
      if (!Platform.isAndroid && !Platform.isIOS) {
        _init();
      }
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    for (final s in list) {
      final parts = s.split('|');
      if (parts.length >= 2) {
        _syncHistory[parts[0]] = parts[1];
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list =
        _syncHistory.entries.map((e) => '${e.key}|${e.value}').toList();
    await prefs.setStringList(_historyKey, list);
  }

  static Dio _createBackupDio(Ref ref) {
    // We can't easily get the options from ApiClient if it's not exposed,
    // but we can create a similar one.
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(minutes: 2),
    ));

    // Get the base configuration from shared preferences or auth state
    // For simplicity, we'll let the interceptor or the first request handle it,
    // but better to set it now if available.

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final auth = ref.read(authProvider);
        if (auth.serverUrl != null) {
          options.baseUrl = auth.serverUrl!;
        }
        if (auth.password != null) {
          options.headers['Authorization'] = 'Bearer ${auth.password}';
          options.headers['x-auth-token'] = auth.password;
        }
        return handler.next(options);
      },
    ));

    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: (message) => debugPrint(message),
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 3),
        Duration(seconds: 5),
      ],
    ));

    return dio;
  }

  void _init() {
    _ref.listen<BackupSettings>(backupSettingsProvider, (previous, next) {
      _syncWatchers(next);
    }, fireImmediately: true);
  }

  void _syncWatchers(BackupSettings settings) {
    final activePaths = settings.folders
        .where((f) => f.isEnabled)
        .map((f) => f.localPath)
        .toSet();

    // Stop watchers and clear queue for removed/disabled folders
    final toStop = _subscriptions.keys
        .where((path) => !activePaths.contains(path))
        .toList();
    for (final path in toStop) {
      _subscriptions[path]?.cancel();
      _subscriptions.remove(path);
      // Clear pending uploads for this folder
      _uploadQueue.removeWhere((task) => task.folder.localPath == path);
      debugPrint(
          '🛑 [BackupService] Stopped watching and cleared queue: $path');
    }

    // Start watchers for new/enabled folders (watch only, no initial sync)
    for (final folder in settings.folders) {
      if (folder.isEnabled && !_subscriptions.containsKey(folder.localPath)) {
        _startWatcher(folder);
        // DO NOT auto-sync all files - only watch for NEW files
      }
    }
  }

  void _startWatcher(BackupFolder folder) {
    final directory = Directory(folder.localPath);
    if (!directory.existsSync()) {
      debugPrint(
          '⚠️ [BackupService] Folder does not exist: ${folder.localPath}');
      return;
    }

    debugPrint('🔭 [BackupService] Started watching: ${folder.localPath}');
    final watcher = DirectoryWatcher(folder.localPath);

    _subscriptions[folder.localPath] = watcher.events.listen((event) {
      if (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY) {
        _handleFileChange(event.path, folder);
      }
    });
  }

  bool _isExcluded(String filePath) {
    final fileName = p.basename(filePath).toLowerCase();

    // Check for temporary/system files
    if (fileName.startsWith('.') ||
        fileName.startsWith('~') ||
        fileName.contains('.pending-') || // Android MediaStore temp
        fileName.endsWith('.tmp') ||
        fileName.endsWith('.lock') ||
        fileName.endsWith('.crdownload') ||
        fileName.endsWith('.part')) {
      return true;
    }

    final parts = p.split(filePath);

    const excludedFolders = {
      '.git',
      '.dart_tool',
      'node_modules',
      'build',
      '.idea',
      '.vscode',
      'bin',
      'obj',
      'backend',
    };

    for (final part in parts) {
      if (excludedFolders.contains(part)) {
        return true;
      }
    }

    return false;
  }

  Future<void> syncAllFiles(BackupFolder folder, {bool silent = false}) async {
    if (isSyncing && !silent) {
      debugPrint('ℹ️ [BackupService] Sync already in progress');
      return;
    }

    final directory = Directory(folder.localPath);
    if (!directory.existsSync()) {
      if (!silent) {
        debugPrint('⚠️ [BackupService] Sync failed: Folder not found');
      }
      return;
    }

    if (!silent) {
      _ref.read(syncStatusProvider.notifier).state = true;
    }
    _currentSyncToken = CancelToken();

    debugPrint(
        '🚀 [BackupService] Starting FULL sync (manual): ${folder.localPath}');

    // Collect all files first, then sort by newest
    final List<File> allFiles = [];
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (_currentSyncToken?.isCancelled ?? false) {
          debugPrint('⏹️ [BackupService] Full sync cancelled by user');
          break;
        }

        if (entity is File) {
          if (!_isExcluded(entity.path)) {
            allFiles.add(entity);
          }
        }
      }

      // Sort by modification time, newest first
      allFiles.sort((a, b) {
        try {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        } catch (_) {
          return 0;
        }
      });

      debugPrint(
          '📁 [BackupService] Found ${allFiles.length} files to sync (sorted by newest)');

      int count = 0;
      for (final file in allFiles) {
        if (_currentSyncToken?.isCancelled ?? false) {
          debugPrint('⏹️ [BackupService] Full sync cancelled by user');
          break;
        }
        await _handleFileChange(file.path, folder,
            cancelToken: _currentSyncToken, bypassHistory: true);
        count++;
      }
      debugPrint('✅ [BackupService] Full sync completed: $count files queued');
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('⏹️ [BackupService] Full sync cancelled during upload');
      } else {
        debugPrint('❌ [BackupService] Full sync error: $e');
      }
    } finally {
      _ref.read(syncStatusProvider.notifier).state = false;
      _currentSyncToken = null;
    }
  }

  void cancelSync() {
    _currentSyncToken?.cancel('User cancelled full sync');
    _ref.read(syncStatusProvider.notifier).state = false;
  }

  final List<_BackupTask> _uploadQueue = [];
  bool _isProcessingQueue = false;

  Future<void> _handleFileChange(String filePath, BackupFolder folder,
      {CancelToken? cancelToken, bool bypassHistory = false}) async {
    // On Android/iOS, ForegroundSyncService handles uploads - don't queue here
    if (Platform.isAndroid || Platform.isIOS) return;

    if (_isExcluded(filePath)) {
      return;
    }

    final file = File(filePath);
    if (!file.existsSync()) return;

    final modTime = file.lastModifiedSync().millisecondsSinceEpoch.toString();
    if (!bypassHistory && _syncHistory[filePath] == modTime) {
      // Already synced
      return;
    }

    final fileName = p.basename(filePath);
    _uploadQueue
        .add(_BackupTask(filePath, folder, fileName, modTime, cancelToken));
    _processQueue();
  }

  Future<void> _processQueue() async {
    // On Android/iOS, ForegroundSyncService handles uploads - skip queue processing
    if (Platform.isAndroid || Platform.isIOS) {
      _uploadQueue.clear();
      return;
    }

    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_uploadQueue.isNotEmpty) {
      final task = _uploadQueue.first;

      try {
        final file = File(task.filePath);
        if (!file.existsSync()) {
          _uploadQueue.removeAt(0);
          continue;
        }

        // Cek ukuran file sebelum upload (Skip if > 1GB as per earlier rule or user's 100MB?)
        // The user suggested 100MB in the snippet. Let's use 1000MB as per previous max file size rule.
        // Actually the user's snippet said 100MB. I'll follow the user's request.
        final fileSize = await file.length();
        if (fileSize > 100 * 1024 * 1024) {
          debugPrint(
              '⚠️ [BackupService] File too large (>${100}MB), skipping: ${task.fileName}');
          _uploadQueue.removeAt(0);
          continue;
        }

        debugPrint('🔄 [BackupService] Processing queue: ${task.fileName}');

        final success = await _backgroundUpload(
          task.folder.serverPath,
          task.filePath,
          task.fileName,
          cancelToken: task.cancelToken,
        );

        if (success) {
          _uploadQueue.removeAt(0);
          _syncHistory[task.filePath] = task.modTime;
          _saveHistory(); // Async save but no need to wait for queue
          debugPrint('✅ [BackupService] Completed: ${task.fileName}');
        } else {
          // Move to end of queue for retry
          final retryTask = _uploadQueue.removeAt(0);
          _uploadQueue.add(retryTask);
          debugPrint('⏸️ [BackupService] Will retry later: ${task.fileName}');

          // Break to avoid infinite loop if it's the only one and keep failing
          if (_uploadQueue.length == 1) {
            await Future.delayed(const Duration(seconds: 10));
          }
        }

        // Dynamic delay based on file size
        final delay =
            Duration(milliseconds: 500 + (fileSize ~/ (1024 * 1024) * 10));
        await Future.delayed(delay);
      } catch (e) {
        debugPrint('❌ [BackupService] Queue error for ${task.filePath}: $e');
        if (_uploadQueue.isNotEmpty) {
          _uploadQueue.removeAt(0);
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    _isProcessingQueue = false;
  }

  Future<bool> _backgroundUpload(
    String serverPath,
    String localFilePath,
    String fileName, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _backupDio.get('/info');
      final info = SystemInfo.fromJson(response.data);
      final projectDisk = info.projectDisk;

      if (projectDisk != null) {
        final freeGb = projectDisk.free / (1024 * 1024 * 1024);
        if (freeGb < 0.1) {
          debugPrint(
              '⚠️ [BackupService] Storage limit reached. Skipping $fileName');
          return false;
        }
      }

      if (!await File(localFilePath).exists()) {
        return false;
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          localFilePath,
          filename: fileName,
        ),
      });

      final query = serverPath.isNotEmpty ? '?path=$serverPath' : '';
      await _backupDio.post(
        '/upload$query',
        data: formData,
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      debugPrint('✅ [BackupService] Successfully backed up: $fileName');
      return true;
    } catch (e) {
      debugPrint('❌ [BackupService] Failed to backup $fileName: $e');
      return false;
    }
  }

  void dispose() {
    cancelSync();
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}

class _BackupTask {
  final String filePath;
  final BackupFolder folder;
  final String fileName;
  final String modTime;
  final CancelToken? cancelToken;

  _BackupTask(this.filePath, this.folder, this.fileName, this.modTime,
      this.cancelToken);
}
