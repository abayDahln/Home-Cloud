import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/logs/presentation/log_screen.dart';
import '../../features/monitoring/presentation/monitoring_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return _ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/logs',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LogScreen(),
            ),
          ),
          GoRoute(
            path: '/monitoring',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MonitoringScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

class _ShellScaffold extends StatelessWidget {
  final Widget child;
  const _ShellScaffold({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/settings') return 1;
    if (location == '/logs') return 2;
    if (location == '/monitoring') return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: Row(
        children: [
          _SideBar(currentIndex: index),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SideBar extends StatelessWidget {
  final int currentIndex;
  static const String _fontFamily = 'Plus Jakarta Sans';
  const _SideBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // App branding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/icon/app_logo.png',
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.cloud_rounded,
                                color: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Home Cloud Server',
                                style: TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 16),
                  // Navigation items
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: currentIndex == 0,
                    onTap: () => context.go('/'),
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    isActive: currentIndex == 1,
                    onTap: () => context.go('/settings'),
                  ),
                  _NavItem(
                    icon: Icons.terminal_rounded,
                    label: 'Logs',
                    isActive: currentIndex == 2,
                    onTap: () => context.go('/logs'),
                  ),
                  _NavItem(
                    icon: Icons.monitor_heart_rounded,
                    label: 'Monitoring',
                    isActive: currentIndex == 3,
                    onTap: () => context.go('/monitoring'),
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.grey.shade500, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  static const String _fontFamily = 'Plus Jakarta Sans';
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isActive || _hovering;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? const Color(0xFF4A6FA5).withValues(alpha: 0.1)
                  : _hovering
                      ? const Color(0xFFF1F4F9)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: isHighlighted
                      ? const Color(0xFF4A6FA5)
                      : const Color(0xFF888888),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isHighlighted
                        ? const Color(0xFF4A6FA5)
                        : const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
