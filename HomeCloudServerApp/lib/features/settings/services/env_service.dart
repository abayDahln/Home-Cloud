import 'dart:io';
import '../models/server_settings.dart';

class EnvService {
  final String envPath;

  EnvService(this.envPath);

  Future<ServerSettings> loadSettings() async {
    final file = File(envPath);
    if (!await file.exists()) {
      final settings = const ServerSettings();
      await saveSettings(settings);
      return settings;
    }

    final lines = await file.readAsLines();
    final map = <String, String>{};
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx > 0) {
        final key = trimmed.substring(0, idx).trim();
        final value = trimmed.substring(idx + 1).trim();
        map[key] = value;
      }
    }
    return ServerSettings.fromEnvMap(map);
  }

  Future<void> saveSettings(ServerSettings settings) async {
    final file = File(envPath);
    final envMap = settings.toEnvMap();
    final buffer = StringBuffer();
    envMap.forEach((key, value) {
      buffer.writeln('$key=$value');
    });
    await file.writeAsString(buffer.toString());
  }
}
