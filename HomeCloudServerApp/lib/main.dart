import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/dashboard/providers/server_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
      );
    } catch (e) {
      debugPrint('Launch at startup setup failed: $e');
    }

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Home Cloud Server',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: HomeCloudServerApp()));
}

class HomeCloudServerApp extends ConsumerStatefulWidget {
  const HomeCloudServerApp({super.key});

  @override
  ConsumerState<HomeCloudServerApp> createState() => _HomeCloudServerAppState();
}

class _HomeCloudServerAppState extends ConsumerState<HomeCloudServerApp>
    with TrayListener, WindowListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    _initTray();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Minimize to tray instead of destroying
    await windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem item) async {
    final serverService = ref.read(serverServiceProvider);

    switch (item.key) {
      case 'start_server':
        await serverService.start();
        break;
      case 'stop_server':
        await serverService.stop();
        break;
      case 'restart_server':
        await serverService.restart();
        break;
      case 'open_app':
        windowManager.show();
        break;
      case 'exit_app':
        await serverService.stop();
        windowManager.destroy();
        break;
    }
  }

  Future<void> _initTray() async {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final iconName = Platform.isWindows ? 'app_logo.ico' : 'app_logo.png';
    final iconPath =
        p.join(exeDir, 'data', 'flutter_assets', 'assets', 'icon', iconName);
    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('Home Cloud Server');

    final Menu menu = Menu(
      items: [
        MenuItem(
          key: 'start_server',
          label: 'Start Server',
        ),
        MenuItem(
          key: 'stop_server',
          label: 'Stop Server',
        ),
        MenuItem(
          key: 'restart_server',
          label: 'Restart Server',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'open_app',
          label: 'Open App',
        ),
        MenuItem(
          key: 'exit_app',
          label: 'Exit Tray',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Home Cloud Server',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
