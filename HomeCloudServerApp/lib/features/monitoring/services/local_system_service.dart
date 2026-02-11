import 'dart:async';
import 'dart:io';

class SystemUsage {
  final double cpuPercent;
  final double memoryPercent;
  final int memoryUsed;
  final int memoryTotal;
  final double diskPercent;
  final int diskUsed;
  final int diskTotal;

  SystemUsage({
    required this.cpuPercent,
    required this.memoryPercent,
    required this.memoryUsed,
    required this.memoryTotal,
    required this.diskPercent,
    required this.diskUsed,
    required this.diskTotal,
  });

  factory SystemUsage.empty() {
    return SystemUsage(
      cpuPercent: 0,
      memoryPercent: 0,
      memoryUsed: 0,
      memoryTotal: 1,
      diskPercent: 0,
      diskUsed: 0,
      diskTotal: 1,
    );
  }
}

class LocalSystemService {
  Future<SystemUsage> getSystemUsage() async {
    if (Platform.isWindows) {
      return _getWindowsUsage();
    }
    // Fallback or implement other OS
    return SystemUsage.empty();
  }

  Future<SystemUsage> _getWindowsUsage() async {
    double cpu = 0;
    int memTotal = 0;
    int memFree = 0;
    int diskTotal = 0;
    int diskFree = 0;

    try {
      // CPU
      // wmic cpu get loadpercentage
      final cpuRes =
          await Process.run('wmic', ['cpu', 'get', 'loadpercentage']);
      if (cpuRes.exitCode == 0) {
        final lines = cpuRes.stdout.toString().split('\n');
        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && int.tryParse(trimmed) != null) {
            cpu = double.parse(trimmed);
            break;
          }
        }
      }

      // Safer Memory Fetch
      // wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Value
      final memResSafe = await Process.run('wmic',
          ['OS', 'get', 'FreePhysicalMemory,TotalVisibleMemorySize', '/Value']);
      if (memResSafe.exitCode == 0) {
        final lines = memResSafe.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.contains('FreePhysicalMemory')) {
            memFree = int.tryParse(line.split('=')[1].trim()) ?? 0;
          }
          if (line.contains('TotalVisibleMemorySize')) {
            memTotal = int.tryParse(line.split('=')[1].trim()) ?? 0;
          }
        }
      }
      // Info from wmic is in Kilobytes
      memFree *= 1024;
      memTotal *= 1024;

      // Disk (Current Drive, usually C:)
      // wmic logicaldisk where "DeviceID='C:'" get FreeSpace,Size /Value
      final diskRes = await Process.run('wmic', [
        'logicaldisk',
        'where',
        'DeviceID="C:"',
        'get',
        'FreeSpace,Size',
        '/Value'
      ]);
      if (diskRes.exitCode == 0) {
        final lines = diskRes.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.contains('FreeSpace')) {
            diskFree = int.tryParse(line.split('=')[1].trim()) ?? 0;
          }
          if (line.contains('Size')) {
            diskTotal = int.tryParse(line.split('=')[1].trim()) ?? 0;
          }
        }
      }
    } catch (e) {
      // ignore
    }

    final memUsed = memTotal - memFree;
    final diskUsed = diskTotal - diskFree;

    return SystemUsage(
      cpuPercent: cpu,
      memoryPercent: memTotal > 0 ? (memUsed / memTotal) * 100 : 0,
      memoryUsed: memUsed,
      memoryTotal: memTotal,
      diskPercent: diskTotal > 0 ? (diskUsed / diskTotal) * 100 : 0,
      diskUsed: diskUsed,
      diskTotal: diskTotal,
    );
  }
}
