import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/providers/backup_provider.dart';
import '../../../features/home/services/foreground_sync_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';

class AuthState {
  final String? serverUrl;
  final String? password;
  final bool isAuthenticated;

  AuthState({
    this.serverUrl,
    this.password,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    String? serverUrl,
    String? password,
    bool? isAuthenticated,
  }) {
    return AuthState(
      serverUrl: serverUrl ?? this.serverUrl,
      password: password ?? this.password,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final StorageService _storage;
  final Ref ref;

  AuthNotifier(this._apiClient, this._storage, this.ref) : super(AuthState()) {
    _loadStoredCredentials();
  }

  Future<void> _loadStoredCredentials() async {
    if (_storage.hasCredentials()) {
      final serverUrl = _storage.getServerUrl();
      final password = _storage.getPassword();

      if (serverUrl != null && password != null) {
        await login(serverUrl, password, saveCredentials: false);
      }
    }
  }

  Future<String?> login(String serverUrl, String password,
      {bool saveCredentials = true}) async {
    try {
      String formattedUrl = serverUrl.trim();

      // 1. Ensure scheme
      if (!formattedUrl.startsWith('http://') &&
          !formattedUrl.startsWith('https://')) {
        formattedUrl = 'http://$formattedUrl';
      }

      // 2. Auto-fix for localhost in Android Emulator
      if (Platform.isAndroid &&
          (formattedUrl.contains('localhost') ||
              formattedUrl.contains('127.0.0.1'))) {
        formattedUrl = formattedUrl
            .replaceFirst('localhost', '10.0.2.2')
            .replaceFirst('127.0.0.1', '10.0.2.2');
        print(
            '🔧 [AuthNotifier] Android detected: mapped localhost to 10.0.2.2');
      }

      // 3. Auto-add port 8080 ONLY if it's not HTTPS and not a Cloudflare Tunnel
      Uri uri = Uri.parse(formattedUrl);
      if (!uri.hasPort &&
          !formattedUrl.startsWith('https://') &&
          !formattedUrl.contains('trycloudflare.com')) {
        if (formattedUrl.endsWith('/')) {
          formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
        }
        formattedUrl = '$formattedUrl:8080';
        print('🔧 [AuthNotifier] No port detected, defaulted to :8080');
      }

      // 4. Final cleaning
      if (formattedUrl.endsWith('/')) {
        formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
      }

      _apiClient.setBaseUrl(formattedUrl);
      _apiClient.setToken(password);

      print('🌐 [AuthNotifier] Connecting to: $formattedUrl');

      final response = await _apiClient.dio.post(
        '/login',
        data: {'password': password},
        options: Options(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        if (saveCredentials) {
          await _storage.saveServerUrl(formattedUrl);
          await _storage.savePassword(password);
        }

        state = AuthState(
          serverUrl: formattedUrl,
          password: password,
          isAuthenticated: true,
        );
        return null; // Success
      }
      return 'Incorrect password. Please try again.';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Server not reaching. Please check your URL/IP and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        return 'Could not connect to server. Check your internet or server URL.';
      }
      return 'Failed to connect: ${e.message}';
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  Future<void> logout() async {
    // Stop and clear foreground service on logout
    if (Platform.isAndroid) {
      await ForegroundSyncService.stop();
      await ForegroundSyncService.clearState();
    }

    // Reset local state providers
    ref.read(backupSettingsProvider.notifier).reset();

    _apiClient.cancelAllRequests();
    await _storage.clearAll();

    // Also clear backup_settings from prefs to be safe
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backup_settings');
    await prefs.remove('foreground_sync_start_time');
    await prefs.remove('sync_history');

    _apiClient.setToken('');
    state = AuthState();
  }
}

final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return StorageService(prefs);
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  final storageAsync = ref.watch(storageServiceProvider);

  return storageAsync.maybeWhen(
    data: (storage) => AuthNotifier(client, storage, ref),
    orElse: () =>
        AuthNotifier(client, StorageService(null), ref), // Fallback or wait
  );
});
