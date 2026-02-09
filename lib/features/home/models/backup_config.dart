class BackupFolder {
  final String localPath;
  final String serverPath;
  final bool isEnabled;

  BackupFolder({
    required this.localPath,
    required this.serverPath,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'localPath': localPath,
        'serverPath': serverPath,
        'isEnabled': isEnabled,
      };

  factory BackupFolder.fromJson(Map<String, dynamic> json) => BackupFolder(
        localPath: json['localPath'],
        serverPath: json['serverPath'],
        isEnabled: json['isEnabled'] ?? true,
      );
}

class BackupSettings {
  final List<BackupFolder> folders;
  final bool launchAtStartup;
  final bool minimizeToTray;

  BackupSettings({
    required this.folders,
    this.launchAtStartup = false,
    this.minimizeToTray = true,
  });

  Map<String, dynamic> toJson() => {
        'folders': folders.map((f) => f.toJson()).toList(),
        'launchAtStartup': launchAtStartup,
        'minimizeToTray': minimizeToTray,
      };

  factory BackupSettings.fromJson(Map<String, dynamic> json) => BackupSettings(
        folders: (json['folders'] as List?)
                ?.map((f) => BackupFolder.fromJson(f))
                .toList() ??
            [],
        launchAtStartup: json['launchAtStartup'] ?? false,
        minimizeToTray: json['minimizeToTray'] ?? true,
      );

  BackupSettings copyWith({
    List<BackupFolder>? folders,
    bool? launchAtStartup,
    bool? minimizeToTray,
  }) {
    return BackupSettings(
      folders: folders ?? this.folders,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
    );
  }
}
