import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/server_settings.dart';

class EnvService {
  final String envPath;

  EnvService(this.envPath);

  Future<ServerSettings> loadSettings(String baseDir) async {
    final file = File(envPath);
    final defaultWatchDir = p.join(baseDir, 'uploads');

    if (!await file.exists()) {
      final settings = ServerSettings(watchDir: defaultWatchDir);
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

    var settings = ServerSettings.fromEnvMap(map);
    // If it's the old relative default or empty, convert to absolute
    if (settings.watchDir == './uploads' || settings.watchDir.isEmpty) {
      settings = settings.copyWith(watchDir: defaultWatchDir);
      // Save the resolved absolute path back to .env
      await saveSettings(settings);
    }
    return settings;
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
