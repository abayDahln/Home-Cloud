import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'api_client.dart';

final serverConnectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  final api = ref.watch(apiClientProvider);
  final authNotifier = ref.watch(authProvider.notifier);
  return ConnectivityNotifier(api, authNotifier, ref);
});

class ConnectivityState {
  final bool isServerDown;
  final bool isRetrying;
  final DateTime? lastCheck;

  ConnectivityState({
    this.isServerDown = false,
    this.isRetrying = false,
    this.lastCheck,
  });

  ConnectivityState copyWith({
    bool? isServerDown,
    bool? isRetrying,
    DateTime? lastCheck,
  }) {
    return ConnectivityState(
      isServerDown: isServerDown ?? this.isServerDown,
      isRetrying: isRetrying ?? this.isRetrying,
      lastCheck: lastCheck ?? this.lastCheck,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ApiClient _api;
  final AuthNotifier _auth;
  final Ref _ref;
  Timer? _heartbeatTimer;
  StreamSubscription? _errorSubscription;
  int _failureCount = 0;

  ConnectivityNotifier(this._api, this._auth, this._ref)
      : super(ConnectivityState()) {
    // Start monitoring when authenticated
    _ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        _startMonitoring();
      } else {
        _stopMonitoring();
      }
    }, fireImmediately: true);
  }

  void _startMonitoring() {
    _stopMonitoring(); // Ensure clean start

    // 1. Start Heartbeat
    _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _checkConnectivity());

    // 2. Listen to API Errors for realtime reaction
    _errorSubscription = _api.errorStream.listen((e) {
      _handleApiError(e);
    });

    // Initial check
    _checkConnectivity();
  }

  void _stopMonitoring() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _errorSubscription?.cancel();
    _errorSubscription = null;
    _failureCount = 0;
  }

  void _handleApiError(DioException e) {
    // Ignore if not authenticated (should be handled by _stopMonitoring, but to be safe)
    if (!_ref.read(authProvider).isAuthenticated) return;

    if (e.response?.statusCode == 401) {
      debugPrint('🚫 [Connectivity] 401 Unauthorized detected. Logging out.');
      _auth.logout();
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      debugPrint('⚡ [Connectivity] Realtime connection error detected.');
      _handleFailure();
    }
  }

  Future<void> _checkConnectivity() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    try {
      final response = await _api.dio.get('/info',
          options: Options(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ));

      if (response.statusCode == 200) {
        _failureCount = 0;
        if (state.isServerDown) {
          state = state.copyWith(isServerDown: false);
        }
        state = state.copyWith(lastCheck: DateTime.now());
      } else {
        _handleFailure();
      }
    } catch (e) {
      debugPrint('💓 [Connectivity] Heartbeat failed: $e');
      _handleFailure();
    }
  }

  void _handleFailure() {
    _failureCount++;
    if (_failureCount >= 2) {
      debugPrint('🚨 [Connectivity] Server unreachable after 2 failures.');
      // Update state to show "Server Down" UI, but DO NOT logout automatically
      state = state.copyWith(isServerDown: true, lastCheck: DateTime.now());
    }
  }

  Future<void> retryConnection() async {
    state = state.copyWith(isRetrying: true);
    await Future.delayed(const Duration(seconds: 1)); // Minimal delay for UX

    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) {
      state = state.copyWith(isRetrying: false);
      return;
    }

    try {
      final response = await _api.dio.get('/info',
          options: Options(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ));

      if (response.statusCode == 200) {
        _failureCount = 0;
        state = state.copyWith(
          isServerDown: false,
          isRetrying: false,
          lastCheck: DateTime.now(),
        );
        debugPrint('✅ [Connectivity] Connection restored!');
      } else {
        // Still down
        state = state.copyWith(isRetrying: false);
      }
    } catch (e) {
      debugPrint('❌ [Connectivity] Retry failed: $e');
      state = state.copyWith(isRetrying: false);
      // Keep isServerDown = true
    }
  }

  void resetServerDown() {
    state = state.copyWith(isServerDown: false);
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }
}

