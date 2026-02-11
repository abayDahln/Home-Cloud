import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/network/connectivity_service.dart';
import 'features/home/providers/backup_provider.dart';
import 'features/home/providers/file_provider.dart';
import 'features/home/models/backup_config.dart';
import 'features/home/services/foreground_sync_service.dart';
import 'features/home/services/upload_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isWindows) {
    MediaKit.ensureInitialized();
  }

  // Initialize upload notification service for mobile
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await UploadNotificationService.init();
  }

  // Initialize foreground sync service for Android
  if (!kIsWeb && Platform.isAndroid) {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('backup_settings');
    if (jsonStr != null) {
      final settings = BackupSettings.fromJson(jsonDecode(jsonStr));
      final hasEnabledFolders = settings.folders.any((f) => f.isEnabled);
      if (hasEnabledFolders) {
        await ForegroundSyncService.init();
        await ForegroundSyncService.start();
        debugPrint('🚀 [Main] Foreground sync service started on launch');
      }
    }
  }

  if (!kIsWeb && Platform.isWindows) {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
      );
    } catch (e) {
      debugPrint('Launch at startup setup failed: $e');
    }
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    try {
      // Tray is now initialized in _HomeCloudAppState
    } catch (e) {
      debugPrint('Tray icon initialization failed: $e');
    }

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Home Cloud',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: HomeCloudApp()));
}

class HomeCloudApp extends ConsumerStatefulWidget {
  const HomeCloudApp({super.key});

  @override
  ConsumerState<HomeCloudApp> createState() => _HomeCloudAppState();
}

class _HomeCloudAppState extends ConsumerState<HomeCloudApp>
    with TrayListener, WindowListener, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    _initTray();

    // Setup notification cancel callback
    UploadNotificationService.onCancelUpload = (uploadId) {
      if (uploadId == null) {
        // Cancel all uploads
        ref.read(fileOpsProvider.notifier).cancelAllUploads(ref);
      } else {
        // Cancel specific upload
        ref.read(fileOpsProvider.notifier).cancelUpload(uploadId, ref);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStartup();
    });

    ref.listenManual(backupSettingsProvider, (previous, next) {
      // Re-register background task when settings change
      final prevHasFolders = previous?.folders.any((f) => f.isEnabled) ?? false;
      final nextHasFolders = next.folders.any((f) => f.isEnabled);

      if (previous?.launchAtStartup != next.launchAtStartup ||
          prevHasFolders != nextHasFolders) {
        _initStartup();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backup watcher will handle new files automatically
    // No auto-sync on resume - only watch for NEW files
  }

  void _initStartup() async {
    final settings = ref.read(backupSettingsProvider);

    if (kIsWeb) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (settings.launchAtStartup) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } else if (Platform.isAndroid) {
      // Start/stop foreground service based on backup folders
      final hasEnabledFolders = settings.folders.any((f) => f.isEnabled);

      if (hasEnabledFolders) {
        // Initialize and start foreground service for real-time sync
        await ForegroundSyncService.init();
        await ForegroundSyncService.start();
        debugPrint('🚀 [Main] Foreground sync service started');
      } else {
        // Stop foreground service
        await ForegroundSyncService.stop();
        debugPrint('⏹️ [Main] Foreground sync service stopped (no folders)');
      }
    }
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (kIsWeb) return;
    final settings = ref.read(backupSettingsProvider);
    if (settings.minimizeToTray) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayMenuItemClick(MenuItem item) async {
    final backupService = ref.read(backupServiceProvider);

    switch (item.key) {
      case 'pause_backup':
        backupService.togglePause();
        // Update menu label (Pause/Resume)
        // Note: tray_manager doesn't support dynamic label updates easily without resetting the menu.
        // For now, we'll just toggle the state.
        _updateTrayMenu();
        break;
      case 'sync_all':
        final settings = ref.read(backupSettingsProvider);
        for (final folder in settings.folders) {
          if (folder.isEnabled) {
            backupService.syncAllFiles(folder);
          }
        }
        break;
      case 'open_app':
        windowManager.show();
        break;
      case 'exit_app':
        windowManager.destroy();
        break;
    }
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/icon/app_logo.png'
          : 'assets/icon/app_logo.png',
    );
    await _updateTrayMenu();
  }

  Future<void> _updateTrayMenu() async {
    final backupService = ref.read(backupServiceProvider);
    final isPaused = backupService.isPaused;

    final Menu menu = Menu(
      items: [
        MenuItem(
          key: 'pause_backup',
          label: isPaused ? 'Resume Backup' : 'Pause Backup',
        ),
        MenuItem(
          key: 'sync_all',
          label: 'Sync All Files',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'open_app',
          label: 'Open App',
        ),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    ref.watch(backupServiceProvider);

    // Monitor server connectivity
    ref.listen<ConnectivityState>(serverConnectivityProvider, (previous, next) {
      if (next.isServerDown && !(previous?.isServerDown ?? false)) {
        _showStyledDialog(
          context: context,
          title: 'Connection Lost',
          child: const Text(
            'The connection to the HomeCloud server has been lost. You have been logged out for security.',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
          ),
          confirmText: 'OK',
          onConfirm: () {
            ref.read(serverConnectivityProvider.notifier).resetServerDown();
          },
        );
      }
    });

    return MaterialApp.router(
      title: 'Home Cloud',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  void _showStyledDialog({
    required BuildContext context,
    required String title,
    required Widget child,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: child,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              confirmText,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
