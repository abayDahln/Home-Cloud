class SystemInfo {
  final OsInfo os;
  final SysInfo sys;
  final List<CpuInfo> cpu;
  final CpuProcess cpuProcess;
  final ProcessInfo process;
  final MemoryInfo memory;
  final List<DiskInfo> disks;
  final NetworkSpeed network;

  SystemInfo({
    required this.os,
    required this.sys,
    required this.cpu,
    required this.cpuProcess,
    required this.process,
    required this.memory,
    required this.disks,
    required this.network,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    return SystemInfo(
      os: OsInfo.fromJson(json['os']),
      sys: SysInfo.fromJson(json['sys']),
      cpu: (json['cpu'] as List).map((e) => CpuInfo.fromJson(e)).toList(),
      cpuProcess: CpuProcess.fromJson(json['cpu_process']),
      process: ProcessInfo.fromJson(json['process']),
      memory: MemoryInfo.fromJson(json['memory']),
      disks: (json['disks'] as List).map((e) => DiskInfo.fromJson(e)).toList(),
      network: NetworkSpeed.fromJson(json['network']),
    );
  }


  DiskInfo? get projectDisk {
    try {
      return disks.firstWhere((disk) => disk.isProjectDisk);
    } catch (e) {
      return disks.isNotEmpty ? disks.first : null;
    }
  }
}

class OsInfo {
  final String goVersion;
  final String os;
  final String arch;
  final String cpuCount;

  OsInfo({
    required this.goVersion,
    required this.os,
    required this.arch,
    required this.cpuCount,
  });

  factory OsInfo.fromJson(Map<String, dynamic> json) {
    return OsInfo(
      goVersion: json['go_version'] ?? '',
      os: json['os'] ?? '',
      arch: json['arch'] ?? '',
      cpuCount: json['cpu_count'] ?? '0',
    );
  }
}

class SysInfo {
  final String hostname;
  final String os;
  final String platform;
  final String kernelArch;

  SysInfo({
    required this.hostname,
    required this.os,
    required this.platform,
    required this.kernelArch,
  });

  factory SysInfo.fromJson(Map<String, dynamic> json) {
    return SysInfo(
      hostname: json['Hostname'] ?? '',
      os: json['OS'] ?? '',
      platform: json['Platform'] ?? '',
      kernelArch: json['KernelArch'] ?? '',
    );
  }
}

class CpuInfo {
  final int cpu;
  final String vendorId;
  final String family;
  final String model;
  final int stepping;
  final List<dynamic> flags;
  final String modelName;
  final double mhz;

  CpuInfo({
    required this.cpu,
    required this.vendorId,
    required this.family,
    required this.model,
    required this.stepping,
    required this.flags,
    required this.modelName,
    required this.mhz,
  });

  factory CpuInfo.fromJson(Map<String, dynamic> json) {
    return CpuInfo(
      cpu: json['cpu'] ?? 0,
      vendorId: json['vendorId'] ?? '',
      family: json['family'] ?? '',
      model: json['model'] ?? '',
      stepping: json['stepping'] ?? 0,
      flags: json['flags'] ?? [],
      modelName: json['modelName'] ?? '',
      mhz: (json['mhz'] ?? 0).toDouble(),
    );
  }
}

class CpuProcess {
  final List<dynamic> usage;

  CpuProcess({required this.usage});

  factory CpuProcess.fromJson(Map<String, dynamic> json) {
    return CpuProcess(
      usage: json['usage'] ?? [0],
    );
  }

  double get usagePercent {
    if (usage.isEmpty) return 0;
    return (usage[0] as num).toDouble();
  }
}

class ProcessInfo {
  final int count;
  final int threads;

  ProcessInfo({required this.count, required this.threads});

  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      count: json['count'] ?? 0,
      threads: json['threads'] ?? 0,
    );
  }
}

class MemoryInfo {
  final int total;
  final int used;
  final int available;
  final int free;

  MemoryInfo({
    required this.total,
    required this.used,
    required this.available,
    required this.free,
  });

  factory MemoryInfo.fromJson(Map<String, dynamic> json) {
    return MemoryInfo(
      total: json['total'] ?? 0,
      used: json['used'] ?? 0,
      available: json['available'] ?? 0,
      free: json['free'] ?? 0,
    );
  }

  double get usagePercent {
    if (total == 0) return 0;
    return (used / total) * 100;
  }
}

class DiskInfo {
  final String device;
  final String mountpoint;
  final String label;
  final String fstype;
  final int total;
  final int used;
  final int free;
  final int realTotal;
  final int realUsed;
  final int realFree;
  final bool isProjectDisk;

  DiskInfo({
    required this.device,
    required this.mountpoint,
    required this.label,
    required this.fstype,
    required this.total,
    required this.used,
    required this.free,
    required this.realTotal,
    required this.realUsed,
    required this.realFree,
    required this.isProjectDisk,
  });

  factory DiskInfo.fromJson(Map<String, dynamic> json) {
    return DiskInfo(
      device: json['device'] ?? '',
      mountpoint: json['mountpoint'] ?? '',
      label: json['label'] ?? '',
      fstype: json['fstype'] ?? '',
      total: json['total'] ?? 0,
      used: json['used'] ?? 0,
      free: json['free'] ?? 0,
      realTotal: json['real_total'] ?? json['total'] ?? 0,
      realUsed: json['real_used'] ?? json['used'] ?? 0,
      realFree: json['real_free'] ?? json['free'] ?? 0,
      isProjectDisk: json['is_project_disk'] ?? false,
    );
  }

  double get usagePercent {
    if (total == 0) return 0;
    return (used / total) * 100;
  }

  double get usagePercentReal {
    if (realTotal == 0) return 0;
    return (realUsed / realTotal) * 100;
  }
}

class NetworkSpeed {
  final double downloadMBps;
  final double uploadMBps;
  final double downloadMbps;
  final double uploadMbps;

  NetworkSpeed({
    required this.downloadMBps,
    required this.uploadMBps,
    required this.downloadMbps,
    required this.uploadMbps,
  });

  factory NetworkSpeed.fromJson(Map<String, dynamic> json) {
    return NetworkSpeed(
      downloadMBps: (json['download_MBps'] ?? 0).toDouble(),
      uploadMBps: (json['upload_MBps'] ?? 0).toDouble(),
      downloadMbps: (json['download_Mbps'] ?? 0).toDouble(),
      uploadMbps: (json['upload_Mbps'] ?? 0).toDouble(),
    );
  }
}
