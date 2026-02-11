import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../services/server_service.dart';
import '../../settings/services/env_service.dart';
import '../../settings/models/server_settings.dart';

// Server directory - path to where the backend binary lives
final serverDirProvider = StateProvider<String>((ref) {
  // Default to the backend directory relative to the app executable
  final exeDir = p.dirname(Platform.resolvedExecutable);
  // In development, use the backend directory
  final devBackendDir =
      p.normalize(p.join(exeDir, '..', '..', '..', '..', '..', 'backend'));
  if (Directory(devBackendDir).existsSync()) {
    return devBackendDir;
  }
  // In production, the server binary is next to the executable
  final prodServerDir = p.join(exeDir, 'server');
  if (Directory(prodServerDir).existsSync()) {
    return prodServerDir;
  }
  return exeDir;
});

// Env service provider
final envServiceProvider = Provider<EnvService>((ref) {
  final serverDir = ref.watch(serverDirProvider);
  return EnvService(p.join(serverDir, '.env'));
});

// Server settings provider
final serverSettingsProvider =
    StateNotifierProvider<ServerSettingsNotifier, ServerSettings>((ref) {
  final envService = ref.watch(envServiceProvider);
  return ServerSettingsNotifier(envService);
});

class ServerSettingsNotifier extends StateNotifier<ServerSettings> {
  final EnvService _envService;

  ServerSettingsNotifier(this._envService) : super(const ServerSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _envService.loadSettings();
  }

  Future<void> reload() async {
    state = await _envService.loadSettings();
  }

  Future<void> update(ServerSettings settings) async {
    await _envService.saveSettings(settings);
    state = settings;
  }
}

// Server service provider (singleton)
final serverServiceProvider = ChangeNotifierProvider<ServerService>((ref) {
  final serverDir = ref.watch(serverDirProvider);
  final service = ServerService();
  service.setServerDir(serverDir);
  return service;
});
