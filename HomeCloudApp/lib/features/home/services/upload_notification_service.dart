import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UploadNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Function(String?)? onCancelUpload;

  static const String _channelId = 'upload_progress';
  static const String _channelName = 'Upload Progress';
  static const String _channelDesc = 'Shows file upload progress';
  static const int _notificationId = 1001;

  // Only use notifications on mobile platforms
  static bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (_initialized || !_isMobilePlatform) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'cancel_all') {
          onCancelUpload?.call(null);
        } else if (response.actionId?.startsWith('cancel_') == true) {
          final uploadId = response.actionId!.replaceFirst('cancel_', '');
          onCancelUpload?.call(uploadId);
        }
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.low,
          showBadge: false,
          playSound: false,
          enableVibration: false,
        ),
      );
    }

    _initialized = true;
  }

  static Future<void> showUploadProgress({
    required int totalFiles,
    required int completedFiles,
    required double overallProgress,
    required String currentFileName,
  }) async {
    if (!_initialized || !_isMobilePlatform) return;

    final progressPercent = (overallProgress * 100).toInt();
    final remaining = totalFiles - completedFiles;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      actions: [
        const AndroidNotificationAction(
          'cancel_all',
          'Cancel All',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _notificationId,
      'Uploading $remaining file${remaining > 1 ? 's' : ''}',
      '$currentFileName • $progressPercent%',
      details,
    );
  }

  static Future<void> showUploadComplete({
    required int successCount,
    required int totalCount,
  }) async {
    if (!_initialized || !_isMobilePlatform) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title =
        successCount == totalCount ? 'Upload Complete' : 'Upload Finished';
    final body = successCount == totalCount
        ? '$successCount file${successCount > 1 ? 's' : ''} uploaded successfully'
        : '$successCount of $totalCount files uploaded';

    await _notifications.show(
      _notificationId,
      title,
      body,
      details,
    );
  }

  static Future<void> showUploadCancelled() async {
    if (!_initialized || !_isMobilePlatform) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      autoCancel: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _notificationId,
      'Upload Cancelled',
      'File upload was cancelled',
      details,
    );

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      dismiss();
    });
  }

  static Future<void> dismiss() async {
    if (!_initialized || !_isMobilePlatform) return;
    await _notifications.cancel(_notificationId);
  }
}
