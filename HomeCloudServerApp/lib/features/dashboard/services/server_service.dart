import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

enum ServerStatus { stopped, starting, running, stopping, error }

class ServerService extends ChangeNotifier {
  Process? _process;
  ServerStatus _status = ServerStatus.stopped;
  final List<String> _logs = [];
  String _serverDir = '';
  DateTime? _startTime;

  ServerStatus get status => _status;
  List<String> get logs => List.unmodifiable(_logs);
  bool get isRunning => _status == ServerStatus.running;
  DateTime? get startTime => _startTime;

  String get uptime {
    if (_startTime == null) return '--';
    final diff = DateTime.now().difference(_startTime!);
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
    return '${diff.inSeconds}s';
  }

  void setServerDir(String dir) {
    _serverDir = dir;
  }

  String get _serverBinaryName {
    if (Platform.isWindows) return 'server.exe';
    return 'server';
  }

  String get serverBinaryPath => p.join(_serverDir, _serverBinaryName);

  Future<bool> checkBinaryExists() async {
    return File(serverBinaryPath).existsSync();
  }

  Future<void> start() async {
    if (_status == ServerStatus.running || _status == ServerStatus.starting) {
      return;
    }

    _status = ServerStatus.starting;
    notifyListeners();

    // Check if server is already running
    try {
      final port = RegExp(r'PORT=(\d+)')
              .firstMatch(File(p.join(_serverDir, '.env')).readAsStringSync())
              ?.group(1) ??
          '8090';

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 1);
      final request =
          await client.getUrl(Uri.parse('http://localhost:$port/info'));
      final response = await request.close();

      if (response.statusCode == 200 || response.statusCode == 401) {
        // Server exists and is responding (even 401 means it's there)
        _status = ServerStatus.running;
        _startTime = DateTime.now(); // Estimate start time
        _addLog('[INFO] Found existing server instance running on port $port');
        notifyListeners();
        return;
      }
    } catch (_) {
      // Server not reachable, proceed to start
    }

    try {
      final binary = serverBinaryPath;
      if (!File(binary).existsSync()) {
        _addLog('[ERROR] Server binary not found: $binary');
        _status = ServerStatus.error;
        notifyListeners();
        return;
      }

      final envFile = File(p.join(_serverDir, '.env'));
      if (!envFile.existsSync()) {
        _addLog('[WARN] .env file not found, using defaults');
      }

      _addLog('[INFO] Starting server...');
      _addLog('[INFO] Binary: $binary');
      _addLog('[INFO] Working directory: $_serverDir');

      _process = await Process.start(
        binary,
        [],
        workingDirectory: _serverDir,
        mode: ProcessStartMode.normal,
      );

      _startTime = DateTime.now();

      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        _addLog(line);
        if (line.contains('Server running at')) {
          _status = ServerStatus.running;
          notifyListeners();
        }
      });

      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        _addLog('[STDERR] $line');
      });

      _process!.exitCode.then((code) {
        _addLog('[INFO] Server process exited with code $code');
        _status = ServerStatus.stopped;
        _startTime = null;
        _process = null;
        notifyListeners();
      });

      // Give it a moment to start
      await Future.delayed(const Duration(seconds: 1));
      if (_status == ServerStatus.starting) {
        _status = ServerStatus.running;
        notifyListeners();
      }
    } catch (e) {
      _addLog('[ERROR] Failed to start server: $e');
      _status = ServerStatus.error;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_process == null) {
      _status = ServerStatus.stopped;
      notifyListeners();
      return;
    }

    _status = ServerStatus.stopping;
    notifyListeners();
    _addLog('[INFO] Stopping server...');

    try {
      _process!.kill(ProcessSignal.sigterm);

      // Wait up to 5 seconds for graceful shutdown
      final exitCode = await _process!.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _addLog('[WARN] Force killing server...');
          _process!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      _addLog('[INFO] Server stopped (exit code: $exitCode)');
    } catch (e) {
      _addLog('[ERROR] Error stopping server: $e');
      // Force kill on Windows
      if (Platform.isWindows) {
        try {
          Process.runSync('taskkill', ['/F', '/PID', '${_process!.pid}']);
        } catch (_) {}
      }
    }

    _process = null;
    _startTime = null;
    _status = ServerStatus.stopped;
    notifyListeners();
  }

  Future<void> restart() async {
    await stop();
    await Future.delayed(const Duration(milliseconds: 500));
    await start();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logs.add('[$timestamp] $message');
    // Keep last 1000 lines
    if (_logs.length > 1000) {
      _logs.removeRange(0, _logs.length - 1000);
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _addLog('[INFO] Logs cleared');
    notifyListeners();
  }

  Process? _cloudflaredProcess;
  String? _cloudflaredUrl;
  bool get isCloudflaredRunning => _cloudflaredProcess != null;
  String? get cloudflaredUrl => _cloudflaredUrl;

  Future<void> startCloudflared() async {
    if (_cloudflaredProcess != null) return;

    _addLog('[CLOUDFLARED] Starting tunnel...');
    notifyListeners();

    try {
      String cloudflaredPath = 'cloudflared';
      final localBinaryName =
          Platform.isWindows ? 'cloudflared.exe' : 'cloudflared';

      // Check multiple possible locations for the binary
      final platformSubDir =
          Platform.isLinux ? 'linux' : (Platform.isMacOS ? 'mac' : 'windows');
      final List<String> pathsToTry = [
        p.join(_serverDir, platformSubDir, localBinaryName),
        p.join(_serverDir, localBinaryName),
      ];

      String? foundPath;
      for (final path in pathsToTry) {
        if (await File(path).exists()) {
          foundPath = path;
          break;
        }
      }

      if (foundPath != null) {
        cloudflaredPath = foundPath;
        _addLog('[CLOUDFLARED] Using local binary: $cloudflaredPath');

        // Ensure it's executable on Unix-like systems
        if (!Platform.isWindows) {
          try {
            await Process.run('chmod', ['+x', cloudflaredPath]);
          } catch (e) {
            _addLog(
                '[CLOUDFLARED] Warning: Failed to set executable permission: $e');
          }
        }
      } else {
        _addLog(
            '[CLOUDFLARED] Local binary not found at ${pathsToTry.join(' or ')}, trying system path...');
      }

      String port = '8090';
      try {
        final envFile = File(p.join(_serverDir, '.env'));
        if (envFile.existsSync()) {
          port = RegExp(r'PORT=(\d+)')
                  .firstMatch(envFile.readAsStringSync())
                  ?.group(1) ??
              '8090';
        }
      } catch (e) {
        _addLog('[WARN] Could not read .env file, defaulting to port 8090');
      }

      _cloudflaredProcess = await Process.start(
        cloudflaredPath,
        ['tunnel', '--url', 'http://localhost:$port'],
        mode: ProcessStartMode.normal,
      );

      _cloudflaredProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        _addLog('[CLOUDFLARED] $line');
        // Extract URL
        // Example: https://random-name.trycloudflare.com
        final urlMatch = RegExp(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com')
            .firstMatch(line);
        if (urlMatch != null) {
          _cloudflaredUrl = urlMatch.group(0);
          _addLog('[CLOUDFLARED] Tunnel URL: $_cloudflaredUrl');
          notifyListeners();
        }
      });

      _cloudflaredProcess!.exitCode.then((code) {
        _addLog('[CLOUDFLARED] Process exited with code $code');
        if (code != 0 && code != -1) {
          _addLog(
              '[HINT] If code is 1, ensure cloudflared is installed or in the folder.');
          _addLog('[HINT] Also check if port $port is accessible.');
        }
        _cloudflaredProcess = null;
        _cloudflaredUrl = null;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      _addLog('[CLOUDFLARED] Error starting: $e');
    }
  }

  Future<void> stopCloudflared() async {
    if (_cloudflaredProcess == null) return;
    _addLog('[CLOUDFLARED] Stopping tunnel...');
    _cloudflaredProcess?.kill();
    // _cloudflaredProcess = null; // Exit code handler will clear it
  }

  Future<Map<String, List<String>>> getNetworkInterfaces() async {
    try {
      final interfaces = await NetworkInterface.list();
      Map<String, List<String>> result = {};
      for (var interface in interfaces) {
        result[interface.name] =
            interface.addresses.map((addr) => addr.address).toList();
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  @override
  void dispose() {
    _process?.kill();
    _cloudflaredProcess?.kill();
    super.dispose();
  }
}
