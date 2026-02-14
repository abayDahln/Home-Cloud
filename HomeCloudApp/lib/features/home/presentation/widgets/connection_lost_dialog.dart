import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cloud/core/theme/app_colors.dart';
import 'package:home_cloud/core/network/connectivity_service.dart';
import 'package:home_cloud/features/auth/providers/auth_provider.dart';

class ConnectionLostDialog extends ConsumerWidget {
  const ConnectionLostDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auto-close when connection is restored
    ref.listen<ConnectivityState>(serverConnectivityProvider, (previous, next) {
      if (!next.isServerDown) {
        Navigator.of(context).pop();
      }
    });

    final connectivityState = ref.watch(serverConnectivityProvider);
    final isRetrying = connectivityState.isRetrying;

    return PopScope(
      canPop: false, // Prevent back button
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.usageRed),
            const SizedBox(width: 12),
            const Text(
              'Connection Lost',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not reach the server. Please check your connection or ensuring the server is running.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.textBlack,
              ),
            ),
            if (isRetrying) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reconnecting...',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: AppColors.gray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: isRetrying
                ? null
                : () {
                    // Start retry logic
                    ref
                        .read(serverConnectivityProvider.notifier)
                        .retryConnection();
                  },
            child: Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: isRetrying ? AppColors.gray : AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Reset connectivity state so dialog doesn't pop up again immediately
              ref.read(serverConnectivityProvider.notifier).resetServerDown();
              Navigator.of(context).pop();
              // Logout user
              ref.read(authProvider.notifier).logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: AppColors.usageRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
