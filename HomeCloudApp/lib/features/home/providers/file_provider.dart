import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/settings/system_settings.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/system_info.dart';
import '../services/upload_notification_service.dart';

class FileItem {
  final String name;
  final String path;
  final String? fullPath;
  final bool isDir;
  final int size;
  final DateTime modTime;

  FileItem({
    required this.name,
    required this.path,
    this.fullPath,
    required this.isDir,
    required this.size,
    required this.modTime,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'],
      path: json['path'],
      fullPath: json['full_path'],
      isDir: json['is_dir'],
      size: json['size'],
      modTime: json['mod_time'] != null
          ? DateTime.parse(json['mod_time'])
          : DateTime.now(),
    );
  }
}

enum FileSortType { nameAZ, nameZA, sizeAsc, sizeDesc, dateNewest, dateOldest }

class UploadStatus {
  final String fileName;
  final double progress;
  final bool isComplete;
  final bool isError;
  final bool isCancelled;
  final String? errorMessage;

  UploadStatus({
    required this.fileName,
    required this.progress,
    this.isComplete = false,
    this.isError = false,
    this.isCancelled = false,
    this.errorMessage,
  });

  UploadStatus copyWith({
    double? progress,
    bool? isComplete,
    bool? isError,
    bool? isCancelled,
    String? errorMessage,
  }) {
    return UploadStatus(
      fileName: fileName,
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      isError: isError ?? this.isError,
      isCancelled: isCancelled ?? this.isCancelled,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class UploadStatusNotifier extends StateNotifier<Map<String, UploadStatus>> {
  UploadStatusNotifier() : super({});

  void updateProgress(String id, UploadStatus status) {
    state = {...state, id: status};
  }

  void remove(String id) {
    final newState = Map<String, UploadStatus>.from(state);
    newState.remove(id);
    state = newState;
  }

  void clearCompleted() {
    final newState = Map<String, UploadStatus>.from(state);
    newState.removeWhere((key, value) => value.isComplete);
    state = newState;
  }
}

final uploadStatusProvider =
    StateNotifierProvider<UploadStatusNotifier, Map<String, UploadStatus>>(
        (ref) {
  return UploadStatusNotifier();
});

final uploadMinimizedProvider = StateProvider<bool>((ref) => false);

// Controls whether the in-app upload toast is visible
// It will auto-hide after a few seconds and upload continues in background
final uploadOverlayVisibleProvider = StateProvider<bool>((ref) => true);

final cancelTokensProvider = Provider((ref) => <String, CancelToken>{});

class FileOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _apiClient;
  final Ref _ref;

  FileOperationsNotifier(this._apiClient, this._ref)
      : super(const AsyncData(null));

  void _invalidateProviders(String? path) {
    if (path != null) {
      _ref.invalidate(fileListProvider(path));
      // Also invalidate parent if possible, but at least invalidate current
      if (path.contains('/')) {
        final parentPath = path.substring(0, path.lastIndexOf('/'));
        _ref.invalidate(fileListProvider(parentPath));
      }
    } else {
      _ref.invalidate(fileListProvider(""));
    }
    _ref.invalidate(liveSystemInfoProvider);
  }

  Future<void> cancelUpload(String uploadId, WidgetRef ref) async {
    final tokens = ref.read(cancelTokensProvider);
    if (tokens.containsKey(uploadId)) {
      print('⏹️ [FileOpsNotifier] Cancelling upload: $uploadId');
      tokens[uploadId]!.cancel('User cancelled upload');
      tokens.remove(uploadId);

      final uploadNotifier = ref.read(uploadStatusProvider.notifier);
      final current = uploadNotifier.state[uploadId];
      if (current != null) {
        uploadNotifier.updateProgress(
          uploadId,
          current.copyWith(isCancelled: true, isError: false, progress: 0.0),
        );

        Future.delayed(const Duration(seconds: 2), () {
          uploadNotifier.remove(uploadId);
        });
      }
    }
  }

  Future<void> cancelAllUploads(WidgetRef ref) async {
    final tokens = ref.read(cancelTokensProvider);
    final uploadIds = tokens.keys.toList();
    print('⏹️ [FileOpsNotifier] Cancelling all uploads: $uploadIds');

    for (var id in uploadIds) {
      tokens[id]?.cancel('User cancelled all uploads');
    }
    tokens.clear();

    final uploadNotifier = ref.read(uploadStatusProvider.notifier);
    final newState = {...uploadNotifier.state};
    for (var id in uploadIds) {
      if (newState.containsKey(id)) {
        newState[id] = newState[id]!.copyWith(isCancelled: true, progress: 0.0);
      }
    }
    uploadNotifier.state = newState;

    // Show cancelled notification
    UploadNotificationService.showUploadCancelled();

    Future.delayed(const Duration(seconds: 2), () {
      uploadNotifier.state = {};
    });
  }

  Future<bool> uploadFile(
    String path,
    String filePath,
    String fileName, {
    required String uploadId,
    required WidgetRef ref,
    double? minFreeSpaceGb,
  }) async {
    final settings = ref.read(systemSettingsProvider);
    final limit = minFreeSpaceGb ?? settings.minFreeSpaceGb;
    final systemInfo = ref.read(liveSystemInfoProvider).valueOrNull;

    if (systemInfo != null) {
      final projectDisk = systemInfo.projectDisk;
      if (projectDisk != null) {
        final freeGb = projectDisk.free / (1024 * 1024 * 1024);
        if (freeGb < 0.1) {
          print(
              '⚠️ [FileOpsNotifier] Upload blocked: Storage quota reached ($freeGb GB left)');
          ref.read(uploadStatusProvider.notifier).updateProgress(
                uploadId,
                UploadStatus(
                  fileName: fileName,
                  progress: 0.0,
                  isError: true,
                  errorMessage:
                      'Insufficient server storage space (Min: ${limit.toStringAsFixed(0)} GB required)',
                ),
              );
          return false;
        }
      }
    }

    final cancelToken = CancelToken();
    ref.read(cancelTokensProvider)[uploadId] = cancelToken;

    print(
        '📤 [FileOpsNotifier.uploadFile] uploadId: $uploadId, fileName: $fileName');

    try {
      final uploadNotifier = ref.read(uploadStatusProvider.notifier);
      uploadNotifier.updateProgress(
        uploadId,
        UploadStatus(fileName: fileName, progress: 0.0),
      );

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final query = path.isNotEmpty ? '?path=$path' : '';

      await _apiClient.dio.post(
        '/upload$query',
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            uploadNotifier.updateProgress(
              uploadId,
              UploadStatus(fileName: fileName, progress: progress),
            );

            // Update system notification
            final uploads = ref.read(uploadStatusProvider);
            final activeUploads = uploads.values
                .where((s) => !s.isComplete && !s.isError && !s.isCancelled);
            final completedUploads = uploads.values.where((s) => s.isComplete);
            final overallProgress = activeUploads.isEmpty
                ? 1.0
                : activeUploads.map((s) => s.progress).reduce((a, b) => a + b) /
                    activeUploads.length;

            UploadNotificationService.showUploadProgress(
              totalFiles: uploads.length,
              completedFiles: completedUploads.length,
              overallProgress: overallProgress,
              currentFileName: fileName,
            );
          }
        },
      );

      uploadNotifier.updateProgress(
        uploadId,
        UploadStatus(fileName: fileName, progress: 1.0, isComplete: true),
      );

      ref.read(cancelTokensProvider).remove(uploadId);

      // Invalidate providers to show new file and updated storage
      _invalidateProviders(path);

      // Check if all uploads are complete
      Future.delayed(const Duration(milliseconds: 500), () {
        final uploads = ref.read(uploadStatusProvider);
        final allComplete = uploads.values.every((s) => s.isComplete);
        final hasActive = uploads.values
            .any((s) => !s.isComplete && !s.isError && !s.isCancelled);

        if (allComplete && uploads.isNotEmpty) {
          UploadNotificationService.showUploadComplete(
            successCount: uploads.length,
            totalCount: uploads.length,
          );
        } else if (!hasActive && uploads.isNotEmpty) {
          // Mixed results
          final successCount = uploads.values.where((s) => s.isComplete).length;
          UploadNotificationService.showUploadComplete(
            successCount: successCount,
            totalCount: uploads.length,
          );
        }
      });

      Future.delayed(const Duration(seconds: 3), () {
        uploadNotifier.remove(uploadId);
      });

      return true;
    } catch (e) {
      ref.read(cancelTokensProvider).remove(uploadId);

      if (e is DioException && CancelToken.isCancel(e)) {
        print('ℹ️ [FileOpsNotifier.uploadFile] Upload was cancelled');
        return false;
      }

      print('❌ [FileOpsNotifier.uploadFile] Error: $e');
      ref.read(uploadStatusProvider.notifier).updateProgress(
            uploadId,
            UploadStatus(
              fileName: fileName,
              progress: 0.0,
              isError: true,
              errorMessage: e.toString(),
            ),
          );
      return false;
    }
  }

  Future<bool> backgroundUpload(
    String serverPath,
    String localFilePath,
    String fileName,
    double minFreeSpaceGb, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _apiClient.dio.get('/info');
      final info = SystemInfo.fromJson(response.data);
      final projectDisk = info.projectDisk;

      if (projectDisk != null) {
        final freeGb = projectDisk.free / (1024 * 1024 * 1024);
        if (freeGb < 0.1) {
          print(
              '⚠️ [BackupService] Storage limit reached ($freeGb GB left). Skipping $fileName');
          return false;
        }
      }

      if (!await File(localFilePath).exists()) {
        print('ℹ️ [BackupService] File no longer exists, skipping: $fileName');
        return false;
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(localFilePath, filename: fileName),
      });

      final query = serverPath.isNotEmpty ? '?path=$serverPath' : '';
      await _apiClient.dio.post(
        '/upload$query',
        data: formData,
        cancelToken: cancelToken,
      );

      print('✅ [BackupService] Successfully backed up: $fileName');

      // Invalidate to update storage/file list
      _invalidateProviders(serverPath);

      return true;
    } catch (e) {
      print('❌ [BackupService] Failed to backup $fileName: $e');
      return false;
    }
  }

  Future<bool> createFolder(String currentPath, String folderName) async {
    state = const AsyncLoading();
    try {
      final fullPath =
          currentPath.isEmpty ? folderName : '$currentPath/$folderName';
      await _apiClient.dio.post('/mkdir', data: {'path': fullPath});

      _invalidateProviders(currentPath);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteItem(String path) async {
    state = const AsyncLoading();
    try {
      await _apiClient.dio.delete('/delete', queryParameters: {'path': path});

      final parentPath =
          path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : "";
      _invalidateProviders(parentPath);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteMultipleItems(List<String> paths) async {
    state = const AsyncLoading();
    try {
      await Future.wait(paths.map((path) =>
          _apiClient.dio.delete('/delete', queryParameters: {'path': path})));

      String? parentPath;
      if (paths.isNotEmpty) {
        final firstPath = paths.first;
        parentPath = firstPath.contains('/')
            ? firstPath.substring(0, firstPath.lastIndexOf('/'))
            : "";
      }
      _invalidateProviders(parentPath);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> renameItem(String oldPath, String newPath) async {
    state = const AsyncLoading();
    try {
      await _apiClient.dio.post('/rename', data: {
        'old': oldPath,
        'new': newPath,
      });

      final parentPath = oldPath.contains('/')
          ? oldPath.substring(0, oldPath.lastIndexOf('/'))
          : "";
      _invalidateProviders(parentPath);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> moveItem(String source, String dest) async {
    state = const AsyncLoading();
    try {
      await _apiClient.dio.post('/move', data: {
        'source': source,
        'dest': dest,
      });

      final sourceParent = source.contains('/')
          ? source.substring(0, source.lastIndexOf('/'))
          : "";
      final destParent =
          dest.contains('/') ? dest.substring(0, dest.lastIndexOf('/')) : "";

      _invalidateProviders(sourceParent);
      if (sourceParent != destParent) {
        _invalidateProviders(destParent);
      }

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> moveMultipleItems(
      List<String> sources, String destFolder) async {
    state = const AsyncLoading();
    try {
      await Future.wait(sources.map((src) {
        final fileName = src.split('/').last;
        final finalDest =
            destFolder.isEmpty ? fileName : '$destFolder/$fileName';
        return _apiClient.dio
            .post('/move', data: {'source': src, 'dest': finalDest});
      }));

      String? sourceParent;
      if (sources.isNotEmpty) {
        final firstSrc = sources.first;
        sourceParent = firstSrc.contains('/')
            ? firstSrc.substring(0, firstSrc.lastIndexOf('/'))
            : "";
      }

      _invalidateProviders(sourceParent);
      if (sourceParent != destFolder) {
        _invalidateProviders(destFolder);
      }

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> downloadFile(String remotePath, String localPath,
      {ProgressCallback? onProgress}) async {
    try {
      final endpoint = '/download/$remotePath';
      await _apiClient.dio.download(
        endpoint,
        localPath,
        onReceiveProgress: onProgress,
      );
      return true;
    } catch (e) {
      print('❌ [FileOpsNotifier.downloadFile] Error: $e');
      return false;
    }
  }
}

final fileOpsProvider =
    StateNotifierProvider<FileOperationsNotifier, AsyncValue<void>>((ref) {
  final client = ref.watch(apiClientProvider);
  return FileOperationsNotifier(client, ref);
});

class CurrentPathNotifier extends StateNotifier<String> {
  CurrentPathNotifier() : super("");

  void navigateTo(String path) {
    state = path;
  }

  void navigateUp() {
    if (state.isEmpty) return;
    final parts = state.split('/');
    if (parts.length <= 1) {
      state = "";
    } else {
      state = parts.sublist(0, parts.length - 1).join('/');
    }
  }
}

final currentPathProvider =
    StateNotifierProvider<CurrentPathNotifier, String>((ref) {
  return CurrentPathNotifier();
});

final movingItemsProvider = StateProvider<List<FileItem>?>((ref) => null);

final fileListProvider =
    StreamProvider.family.autoDispose<List<FileItem>, String>((ref, path) {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated) {
    return const Stream.empty();
  }

  final controller = StreamController<List<FileItem>>();
  Timer? timer;

  Future<void> fetch() async {
    try {
      if (controller.isClosed) return;
      final files = await _fetchFiles(apiClient, path,
          cancelToken: apiClient.cancelToken);
      if (!controller.isClosed) {
        controller.add(files);
      }
    } catch (e) {
      // If folder not found (404), stop retrying to avoid flooding logs
      if (e is DioException && e.response?.statusCode == 404) {
        debugPrint('🚫 [FileListProvider] Path not found: $path. Stopping poll.');
        controller.add([]); // Add empty list
        return; // Exit without scheduling next timer
      }
      // Ignore other errors but keep retrying
    } finally {
      if (!controller.isClosed) {
        timer = Timer(const Duration(seconds: 5), fetch);
      }
    }
  }

  fetch();

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});

final searchQueryProvider = StateProvider<String>((ref) => "");
final sortTypeProvider =
    StateProvider<FileSortType>((ref) => FileSortType.nameAZ);

final selectedItemsProvider = StateProvider<Set<String>>((ref) => {});
final isSelectionModeProvider = Provider<bool>((ref) {
  return ref.watch(selectedItemsProvider).isNotEmpty;
});

final filteredFilesProvider =
    Provider.family<AsyncValue<List<FileItem>>, String>((ref, path) {
  final fileListAsync = ref.watch(fileListProvider(path));
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final sortType = ref.watch(sortTypeProvider);

  return fileListAsync.whenData((files) {
    var filtered = files.where((f) {
      return f.name.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      if (a.isDir && !b.isDir) return -1;
      if (!a.isDir && b.isDir) return 1;

      switch (sortType) {
        case FileSortType.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case FileSortType.nameZA:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case FileSortType.sizeAsc:
          return a.size.compareTo(b.size);
        case FileSortType.sizeDesc:
          return b.size.compareTo(a.size);
        case FileSortType.dateNewest:
          return b.modTime.compareTo(a.modTime);
        case FileSortType.dateOldest:
          return a.modTime.compareTo(b.modTime);
      }
    });

    return filtered;
  });
});

Future<List<FileItem>> _fetchFiles(ApiClient client, String path,
    {CancelToken? cancelToken}) async {
  try {
    final endpoint = path.isEmpty ? '/list' : '/list/$path';
    final response = await client.dio.get(endpoint, cancelToken: cancelToken);

    if (response.data is List) {
      return (response.data as List).map((e) => FileItem.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    if (e is DioException && CancelToken.isCancel(e)) {
      rethrow;
    }
    rethrow;
  }
}

final systemInfoProvider = FutureProvider.autoDispose<SystemInfo>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return _fetchSystemInfo(apiClient, cancelToken: apiClient.cancelToken);
});

final liveSystemInfoProvider = StreamProvider.autoDispose<SystemInfo>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated) {
    return const Stream.empty();
  }

  final controller = StreamController<SystemInfo>();
  Timer? timer;

  Future<void> fetch() async {
    try {
      if (controller.isClosed) return;
      final info =
          await _fetchSystemInfo(apiClient, cancelToken: apiClient.cancelToken);
      if (!controller.isClosed) controller.add(info);
    } catch (e) {
      // Ignore errors but retry
    } finally {
      if (!controller.isClosed) {
        timer = Timer(
            const Duration(seconds: 1), fetch); // Faster polling for live graph
      }
    }
  }

  fetch();

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});

Future<SystemInfo> _fetchSystemInfo(ApiClient client,
    {CancelToken? cancelToken}) async {
  try {
    final response = await client.dio.get('/info', cancelToken: cancelToken);
    return SystemInfo.fromJson(response.data);
  } catch (e) {
    if (e is DioException && CancelToken.isCancel(e)) {
      rethrow;
    }
    rethrow;
  }
}
