import 'dart:async';
import 'dart:io';
import '../models/system_info.dart';

class LocalSystemService {
  // Cache static info
  OsInfo? _cachedOsInfo;
  SysInfo? _cachedSysInfo;
  CpuInfo? _cachedCpuInfo;

  Future<SystemInfo> getSystemInfo() async {
    if (Platform.isWindows) {
      return _getWindowsSystemInfo();
    }
    return SystemInfo.empty();
  }

  Future<SystemInfo> _getWindowsSystemInfo() async {
    double cpuUsage = 0;
    int memTotal = 0;
    int memFree = 0;
    int diskTotal = 0;
    int diskFree = 0;
    String diskLabel = '';

    try {
      // CPU Usage
      final cpuRes =
          await Process.run('wmic', ['cpu', 'get', 'loadpercentage', '/Value']);
      if (cpuRes.exitCode == 0) {
        final lines = cpuRes.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.trim().startsWith('LoadPercentage=')) {
            cpuUsage = double.tryParse(line.split('=')[1].trim()) ?? 0;
            break;
          }
        }
      }

      // Memory
      final memRes = await Process.run('wmic',
          ['OS', 'get', 'FreePhysicalMemory,TotalVisibleMemorySize', '/Value']);
      if (memRes.exitCode == 0) {
        final lines = memRes.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.contains('FreePhysicalMemory')) {
            memFree = (int.tryParse(line.split('=')[1].trim()) ?? 0) * 1024;
          }
          if (line.contains('TotalVisibleMemorySize')) {
            memTotal = (int.tryParse(line.split('=')[1].trim()) ?? 0) * 1024;
          }
        }
      }

      // Disk (C:)
      final diskRes = await Process.run('wmic', [
        'logicaldisk',
        'where',
        'DeviceID="C:"',
        'get',
        'FreeSpace,Size,VolumeName',
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
          if (line.contains('VolumeName')) {
            diskLabel = line.split('=')[1].trim();
          }
        }
      }

      // Static Info (fetch once)
      if (_cachedOsInfo == null) {
        await _fetchStaticInfo();
      }
    } catch (e) {
      // ignore
    }

    final memUsed = memTotal - memFree;
    final diskUsed = diskTotal - diskFree;

    return SystemInfo(
      os: _cachedOsInfo ?? OsInfo.empty(),
      sys: _cachedSysInfo ?? SysInfo.empty(),
      cpu: [_cachedCpuInfo ?? CpuInfo.empty()],
      cpuProcess: CpuProcess(usage: [cpuUsage]),
      process: ProcessInfo(count: 0, threads: 0), // Requires more complex wmic
      memory: MemoryInfo(
        total: memTotal,
        used: memUsed,
        free: memFree,
        available: memFree,
      ),
      disks: [
        DiskInfo(
          device: 'C:',
          mountpoint: 'C:',
          label: diskLabel,
          fstype: 'NTFS',
          total: diskTotal,
          used: diskUsed,
          free: diskFree,
          realTotal: diskTotal,
          realUsed: diskUsed,
          realFree: diskFree,
          isProjectDisk: true,
        ),
      ],
      network: NetworkSpeed.empty(), // Hard to get via wmic one-shot
    );
  }

  Future<void> _fetchStaticInfo() async {
    String osName = 'Windows';
    String hostname = Platform.localHostname;
    String cpuModel = 'Unknown CPU';
    int cores = Platform.numberOfProcessors;
    double maxClock = 0;
    String arch = '';
    String caption = '';

    try {
      final cpuInfoRes = await Process.run(
          'wmic', ['cpu', 'get', 'Name,MaxClockSpeed', '/Value']);
      if (cpuInfoRes.exitCode == 0) {
        final lines = cpuInfoRes.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.contains('Name=')) {
            cpuModel = line.split('=')[1].trim();
          }
          if (line.contains('MaxClockSpeed=')) {
            maxClock = double.tryParse(line.split('=')[1].trim()) ?? 0;
          }
        }
      }

      final osInfoRes = await Process.run(
          'wmic', ['os', 'get', 'Caption,OSArchitecture', '/Value']);
      if (osInfoRes.exitCode == 0) {
        final lines = osInfoRes.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.contains('Caption=')) caption = line.split('=')[1].trim();
          if (line.contains('OSArchitecture='))
            arch = line.split('=')[1].trim();
        }
        if (caption.isNotEmpty) osName = caption;
      }
    } catch (e) {
      // ignore
    }

    _cachedOsInfo = OsInfo(
      goVersion: '',
      os: osName,
      arch: arch.isNotEmpty ? arch : 'x64',
      cpuCount: cores.toString(),
    );

    _cachedSysInfo = SysInfo(
      hostname: hostname,
      os: osName,
      platform: 'windows',
      kernelArch: arch.isNotEmpty ? arch : 'x86_64',
    );

    _cachedCpuInfo = CpuInfo(
      cpu: 0,
      vendorId: '',
      family: '',
      model: '',
      stepping: 0,
      flags: [],
      modelName: cpuModel,
      mhz: maxClock,
    );
  }
}
