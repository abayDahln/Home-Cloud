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
  final DateTime? lastCheck;

  ConnectivityState({this.isServerDown = false, this.lastCheck});

  ConnectivityState copyWith({bool? isServerDown, DateTime? lastCheck}) {
    return ConnectivityState(
      isServerDown: isServerDown ?? this.isServerDown,
      lastCheck: lastCheck ?? this.lastCheck,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ApiClient _api;
  final AuthNotifier _auth;
  final Ref _ref;
  Timer? _heartbeatTimer;
  int _failureCount = 0;

  ConnectivityNotifier(this._api, this._auth, this._ref)
      : super(ConnectivityState()) {
    // Start monitoring when authenticated
    _ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        _startHeartbeat();
      } else {
        _stopHeartbeat();
      }
    }, fireImmediately: true);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _checkConnectivity());
    // Initial check
    _checkConnectivity();
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _failureCount = 0;
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
        state = state.copyWith(isServerDown: false, lastCheck: DateTime.now());
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
      debugPrint(
          '🚨 [Connectivity] Server unreachable after 2 pings. Logging out.');
      state = state.copyWith(isServerDown: true, lastCheck: DateTime.now());
      _auth.logout();
    }
  }

  void resetServerDown() {
    state = state.copyWith(isServerDown: false);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
