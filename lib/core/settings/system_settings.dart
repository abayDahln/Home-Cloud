import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/providers/auth_provider.dart';

class SystemSettings {
  final double minFreeSpaceGb;

  SystemSettings({
    this.minFreeSpaceGb = 50.0,
  });

  Map<String, dynamic> toJson() => {
        'minFreeSpaceGb': minFreeSpaceGb,
      };

  factory SystemSettings.fromJson(Map<String, dynamic> json) => SystemSettings(
        minFreeSpaceGb: (json['minFreeSpaceGb'] as num?)?.toDouble() ?? 50.0,
      );

  SystemSettings copyWith({
    double? minFreeSpaceGb,
  }) {
    return SystemSettings(
      minFreeSpaceGb: minFreeSpaceGb ?? this.minFreeSpaceGb,
    );
  }
}

final systemSettingsProvider =
    StateNotifierProvider<SystemSettingsNotifier, SystemSettings>((ref) {
  return SystemSettingsNotifier();
});

class SystemSettingsNotifier extends StateNotifier<SystemSettings> {
  static const _key = 'system_settings';

  SystemSettingsNotifier() : super(SystemSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      state = SystemSettings.fromJson(jsonDecode(jsonStr));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void updateMinFreeSpace(double value, [WidgetRef? ref]) {
    state = state.copyWith(minFreeSpaceGb: value);
    _save();


    if (ref != null) {
      final client = ref.read(apiClientProvider);
      client.dio.post('/settings', data: {
        'storage_quota_gb': value.toInt(),
      }).then((_) {
        print(
            '✅ [SystemSettings] Synced quota to backend: ${value.toInt()} GB');
      }).catchError((e) {
        print('❌ [SystemSettings] Failed to sync quota: $e');
      });
    }
  }
}
