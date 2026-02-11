import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/system_info.dart';
import '../../settings/models/server_settings.dart';
import '../../dashboard/providers/server_provider.dart';

final systemInfoServiceProvider = Provider((ref) {
  final settings = ref.watch(serverSettingsProvider);
  return SystemInfoService(settings);
});

final liveSystemInfoProvider = StreamProvider.autoDispose<SystemInfo>((ref) {
  final service = ref.watch(systemInfoServiceProvider);
  final server = ref.watch(serverServiceProvider);

  if (!server.isRunning) {
    return const Stream.empty();
  }

  return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
    try {
      return await service.fetchSystemInfo();
    } catch (e) {
      throw e;
    }
  });
});

class SystemInfoService {
  final ServerSettings settings;
  final Dio _dio = Dio();

  SystemInfoService(this.settings) {
    _dio.options.connectTimeout = const Duration(seconds: 2);
    _dio.options.receiveTimeout = const Duration(seconds: 2);
  }

  Future<SystemInfo> fetchSystemInfo() async {
    try {
      final response = await _dio.get(
        'http://localhost:${settings.port}/info',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${settings.authToken}',
          },
        ),
      );
      return SystemInfo.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch system info: $e');
    }
  }
}
