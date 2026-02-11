class ServerSettings {
  final String port;
  final String authToken;
  final int storageQuotaGB;
  final int maxUploadSize;
  final String watchDir;

  const ServerSettings({
    this.port = '8090',
    this.authToken = '123',
    this.storageQuotaGB = 50,
    this.maxUploadSize = 1073741824,
    this.watchDir = './uploads',
  });

  String get maxUploadSizeDisplay {
    if (maxUploadSize >= 1073741824) {
      return '${(maxUploadSize / 1073741824).toStringAsFixed(1)} GB';
    } else if (maxUploadSize >= 1048576) {
      return '${(maxUploadSize / 1048576).toStringAsFixed(0)} MB';
    } else if (maxUploadSize >= 1024) {
      return '${(maxUploadSize / 1024).toStringAsFixed(0)} KB';
    }
    return '$maxUploadSize B';
  }

  ServerSettings copyWith({
    String? port,
    String? authToken,
    int? storageQuotaGB,
    int? maxUploadSize,
    String? watchDir,
  }) {
    return ServerSettings(
      port: port ?? this.port,
      authToken: authToken ?? this.authToken,
      storageQuotaGB: storageQuotaGB ?? this.storageQuotaGB,
      maxUploadSize: maxUploadSize ?? this.maxUploadSize,
      watchDir: watchDir ?? this.watchDir,
    );
  }

  Map<String, String> toEnvMap() {
    return {
      'PORT': port,
      'AUTH_TOKEN': authToken,
      'STORAGE_QUOTA_GB': storageQuotaGB.toString(),
      'MAX_UPLOAD_SIZE': maxUploadSize.toString(),
      'WATCH_DIR': watchDir,
    };
  }

  factory ServerSettings.fromEnvMap(Map<String, String> map) {
    return ServerSettings(
      port: map['PORT'] ?? '8080',
      authToken: map['AUTH_TOKEN'] ?? '123',
      storageQuotaGB: int.tryParse(map['STORAGE_QUOTA_GB'] ?? '') ?? 50,
      maxUploadSize: int.tryParse(map['MAX_UPLOAD_SIZE'] ?? '') ?? 1073741824,
      watchDir: map['WATCH_DIR'] ?? './uploads',
    );
  }
}
