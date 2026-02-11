import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../models/backup_config.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SyncTaskHandler());
}

class SyncTaskHandler extends TaskHandler {
  bool _isScanning = false;
  Dio? _dio;
  late DateTime _monitoringStartTime;
  final Set<String> _processedFiles = {};

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Reset monitoring start time on every service start to ensure we only
    // backup NEW files created FROM NOW ON, as requested by the user.
    _monitoringStartTime = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('foreground_sync_start_time',
        _monitoringStartTime.millisecondsSinceEpoch);

    debugPrint(
        '🚀 [ForegroundSync] Service started. Monitoring NEW files from $_monitoringStartTime');
  }

  Future<void> _initDio() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    var serverUrl = prefs.getString('server_url');
    final password = prefs.getString('password');

    if (serverUrl == null || password == null) return;

    // Support both http and https for Cloudflare Tunnel
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'http://$serverUrl';
    }

    Uri uri = Uri.parse(serverUrl);

    // Auto-add port 8080 ONLY if:
    // 1. Not using HTTPS (Cloudflare/modern web handles 443)
    // 2. Not already having a port specified
    // 3. Not a Cloudflare Tunnel domain
    if (!uri.hasPort &&
        !serverUrl.startsWith('https://') &&
        !serverUrl.contains('trycloudflare.com')) {
      serverUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;
      serverUrl = '$serverUrl:8080';
    }

    _dio = Dio(BaseOptions(
      baseUrl: serverUrl,
      headers: {
        'Authorization': 'Bearer $password',
        'x-auth-token': password,
      },
      connectTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 5),
    ));
  }

  Future<void> _scanAndUpload() async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final jsonStr = prefs.getString('backup_settings');
      if (jsonStr == null) return;

      await _initDio();
      if (_dio == null) return;

      final settings = BackupSettings.fromJson(jsonDecode(jsonStr));

      final syncHistory = prefs.getStringList('sync_history') ?? [];
      final historyMap = Map<String, String>.fromEntries(syncHistory.map((s) {
        final parts = s.split('|');
        if (parts.length >= 2) return MapEntry(parts[0], parts[1]);
        return const MapEntry('', '');
      }).where((e) => e.key.isNotEmpty));

      bool filesFound = false;

      for (var folder in settings.folders) {
        if (!folder.isEnabled) continue;

        final dir = Directory(folder.localPath);
        if (!dir.existsSync()) continue;

        await for (final entity in dir.list(recursive: true)) {
          if (entity is! File) continue;
          final filePath = entity.path;

          if (_isExcluded(filePath)) continue;
          if (_processedFiles.contains(filePath)) continue;

          try {
            final stat = entity.statSync();
            final modTime = stat.modified;
            final modTimeStr = modTime.millisecondsSinceEpoch.toString();

            if (modTime.isBefore(_monitoringStartTime)) continue;
            if (historyMap[filePath] == modTimeStr) continue;

            // Limit background upload size to 100MB for stability
            if (stat.size > 100 * 1024 * 1024) continue;

            filesFound = true;
            _processedFiles.add(filePath);
            _updateStatus('Uploading: ${p.basename(filePath)}');

            final formData = FormData.fromMap({
              'file': await MultipartFile.fromFile(filePath,
                  filename: p.basename(filePath)),
            });

            final query = folder.serverPath.isNotEmpty
                ? '?path=${folder.serverPath}'
                : '';

            await _dio!.post(
              '/upload$query',
              data: formData,
              onSendProgress: (sent, total) {
                if (total != -1) {
                  final progress = (sent / total * 100).toStringAsFixed(0);
                  _updateStatus(
                      'Uploading: ${p.basename(filePath)} ($progress%)');
                }
              },
            );

            historyMap[filePath] = modTimeStr;
            final newList =
                historyMap.entries.map((e) => '${e.key}|${e.value}').toList();
            await prefs.setStringList('sync_history', newList);

            debugPrint('✅ [ForegroundSync] Synced: ${p.basename(filePath)}');
          } catch (e) {
            _processedFiles.remove(filePath);
            debugPrint(
                '❌ [ForegroundSync] Error uploading ${p.basename(filePath)}: $e');
          }
        }
      }

      if (!filesFound) {
        final now = DateTime.now();
        final timeStr =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        _updateStatus('Idle - Last scan: $timeStr');
      }
    } catch (e) {
      debugPrint('❌ [ForegroundSync] Scan loop error: $e');
    } finally {
      _isScanning = false;
    }
  }

  void _updateStatus(String text) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Home Cloud Sync',
      notificationText: text,
    );
  }

  bool _isExcluded(String path) {
    final name = p.basename(path).toLowerCase();
    return name.startsWith('.') ||
        name.startsWith('~') ||
        name.contains('.pending-') ||
        name.endsWith('.tmp') ||
        name.endsWith('.lock') ||
        name.endsWith('.part') ||
        name.contains('thumbnail');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _scanAndUpload();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isIntentionalStop) async {
    _dio?.close();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}

class ForegroundSyncService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'homecloud_sync',
        channelName: 'Home Cloud Sync',
        channelDescription: 'Real-time background file sync',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions:
          const IOSNotificationOptions(showNotification: true),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(10000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    // Request battery optimization ignore for true background work
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
    }

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Home Cloud Sync',
      notificationText: 'Monitoring for new files',
      callback: startCallback,
    );
    return true;
  }

  static Future<ServiceRequestResult> stop() async {
    return FlutterForegroundTask.stopService();
  }

  static Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('foreground_sync_start_time');
    await prefs.remove('sync_history');
    debugPrint('🧹 [ForegroundSync] State cleared');
  }
}
