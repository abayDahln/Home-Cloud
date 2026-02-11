import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/server_provider.dart';
import '../services/server_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _uptimeTimer;
  static const String _fontFamily = 'Plus Jakarta Sans';

  @override
  void initState() {
    super.initState();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uptimeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverServiceProvider);
    final settings = ref.watch(serverSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 1100;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your HomeCloud server',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 14,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  children: [
                    // 1. Server Status & Cloudflare
                    if (isNarrow) ...[
                      _ServerStatusCard(server: server, settings: settings),
                      const SizedBox(height: 20),
                      _CloudflareCard(server: server),
                    ] else
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _ServerStatusCard(
                                  server: server, settings: settings),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _CloudflareCard(server: server),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // 2. App Info
                    _InfoCard(
                      title: 'App Info',
                      icon: Icons.info_outline_rounded,
                      children: [
                        if (constraints.maxWidth < 900)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                  _InfoRow(
                                    label: 'Status',
                                    value: _statusText(server.status),
                                    icon: Icons.circle,
                                    valueColor: _statusColor(server.status),
                                  ),
                                  _InfoRow(
                                    label: 'Uptime',
                                    value: server.uptime,
                                    icon: Icons.timer_rounded,
                                  ),
                                  _InfoRow(
                                    label: 'Platform',
                                    value: _platformName(),
                                    icon: Icons.computer_rounded,
                                  ),
                                  _InfoRow(
                                    label: 'Binary',
                                    value: server.serverBinaryPath
                                        .split(Platform.pathSeparator)
                                        .last,
                                    icon: Icons.terminal_rounded,
                                  ),
                                ],
                              )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _InfoRow(
                                      label: 'Status',
                                      value: _statusText(server.status),
                                      icon: Icons.circle,
                                      valueColor: _statusColor(server.status),
                                    ),
                                    _InfoRow(
                                      label: 'Platform',
                                      value: _platformName(),
                                      icon: Icons.computer_rounded,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 48),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _InfoRow(
                                      label: 'Uptime',
                                      value: server.uptime,
                                      icon: Icons.timer_rounded,
                                    ),
                                    _InfoRow(
                                      label: 'Binary',
                                      value: server.serverBinaryPath
                                          .split(Platform.pathSeparator)
                                          .last,
                                      icon: Icons.terminal_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. Config & Network Row
                    if (isNarrow) ...[
                      _InfoCard(
                        title: 'Server Configuration',
                        icon: Icons.dns_rounded,
                        children: [
                          _InfoRow(
                            label: 'Port',
                            value: settings.port,
                            icon: Icons.lan_rounded,
                          ),
                          _InfoRow(
                            label: 'Password',
                            value: '••••••••',
                            icon: Icons.lock_rounded,
                          ),
                          _InfoRow(
                            label: 'Storage Quota',
                            value: '${settings.storageQuotaGB} GB',
                            icon: Icons.storage_rounded,
                          ),
                          _InfoRow(
                            label: 'Storage Path',
                            value: settings.watchDir,
                            icon: Icons.folder_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _NetworkInterfacesCard(server: server),
                    ] else
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _InfoCard(
                                title: 'Server Configuration',
                                icon: Icons.dns_rounded,
                                children: [
                                  if (constraints.maxWidth < 900)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _InfoRow(
                                          label: 'Port',
                                          value: settings.port,
                                          icon: Icons.lan_rounded,
                                        ),
                                        _InfoRow(
                                          label: 'Password',
                                          value: '••••••••',
                                          icon: Icons.lock_rounded,
                                        ),
                                        _InfoRow(
                                          label: 'Storage Quota',
                                          value: '${settings.storageQuotaGB} GB',
                                          icon: Icons.storage_rounded,
                                        ),
                                        _InfoRow(
                                          label: 'Storage Path',
                                          value: settings.watchDir,
                                          icon: Icons.folder_rounded,
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _InfoRow(
                                                label: 'Port',
                                                value: settings.port,
                                                icon: Icons.lan_rounded,
                                              ),
                                              _InfoRow(
                                                label: 'Password',
                                                value: '••••••••',
                                                icon: Icons.lock_rounded,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 48),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _InfoRow(
                                                label: 'Storage Quota',
                                                value:
                                                    '${settings.storageQuotaGB} GB',
                                                icon: Icons.storage_rounded,
                                              ),
                                              _InfoRow(
                                                label: 'Storage Path',
                                                value: settings.watchDir,
                                                icon: Icons.folder_rounded,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _NetworkInterfacesCard(server: server),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusText(ServerStatus status) {
    if (status == ServerStatus.running) return 'Running';
    if (status == ServerStatus.starting) return 'Starting...';
    if (status == ServerStatus.stopping) return 'Stopping...';
    if (status == ServerStatus.error) return 'Error';
    return 'Stopped';
  }

  Color _statusColor(ServerStatus status) {
    if (status == ServerStatus.running) return AppColors.usageGreen;
    if (status == ServerStatus.error) return AppColors.usageRed;
    if (status == ServerStatus.stopped) return AppColors.gray;
    return AppColors.usageOrange;
  }

  String _platformName() {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  static const String _fontFamily = 'Plus Jakarta Sans';

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F4F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  static const String _fontFamily = 'Plus Jakarta Sans';

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 14,
                color: AppColors.gray,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textBlack,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudflareCard extends StatelessWidget {
  final ServerService server;
  static const String _fontFamily = 'Plus Jakarta Sans';
  const _CloudflareCard({required this.server});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F4F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF48120).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_rounded,
                    color: Color(0xFFF48120), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Cloudflare Tunnel',
                    style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack)),
              ),
              Switch(
                value: server.isCloudflaredRunning,
                onChanged: (val) {
                  if (val) {
                    server.startCloudflared();
                  } else {
                    server.stopCloudflared();
                  }
                },
                activeColor: const Color(0xFFF48120),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (server.isCloudflaredRunning) ...[
            if (server.cloudflaredUrl != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        server.cloudflaredUrl!,
                        style: const TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9A3412)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          size: 16, color: Color(0xFF9A3412)),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: server.cloudflaredUrl!));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied URL')));
                      },
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text('Generating URL...',
                      style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 13,
                          color: AppColors.gray)),
                ],
              )
          ] else
            Text(
                'Expose your local server to the internet using Cloudflare Tunnel.',
                style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    color: AppColors.gray)),
        ],
      ),
    );
  }
}

class _NetworkInterfacesCard extends StatefulWidget {
  final ServerService server;
  const _NetworkInterfacesCard({required this.server});

  @override
  State<_NetworkInterfacesCard> createState() => _NetworkInterfacesCardState();
}

class _NetworkInterfacesCardState extends State<_NetworkInterfacesCard> {
  Map<String, List<String>> _interfaces = {};
  static const String _fontFamily = 'Plus Jakarta Sans';

  @override
  void initState() {
    super.initState();
    _loadInterfaces();
  }

  void _loadInterfaces() async {
    final ips = await widget.server.getNetworkInterfaces();

    // Sort logic
    final sortedKeys = ips.keys.toList()
      ..sort((a, b) {
        // Priority 1: Wi-Fi / Wireless
        final aWifi = a.toLowerCase().contains('wi-fi') ||
            a.toLowerCase().contains('wireless');
        final bWifi = b.toLowerCase().contains('wi-fi') ||
            b.toLowerCase().contains('wireless');
        if (aWifi && !bWifi) return -1;
        if (!aWifi && bWifi) return 1;

        // Priority 2: Avoid VM/Virtual
        final aVm = a.toLowerCase().contains('vmware') ||
            a.toLowerCase().contains('virtual') ||
            a.toLowerCase().contains('pseudo');
        final bVm = b.toLowerCase().contains('vmware') ||
            b.toLowerCase().contains('virtual') ||
            b.toLowerCase().contains('pseudo');
        if (aVm && !bVm) return 1;
        if (!aVm && bVm) return -1;

        return a.compareTo(b);
      });

    final Map<String, List<String>> sortedMap = {};
    for (var key in sortedKeys) {
      sortedMap[key] = ips[key]!;
    }

    if (mounted) setState(() => _interfaces = sortedMap);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F4F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings_ethernet_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Network IPs',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    size: 16, color: AppColors.gray),
                onPressed: _loadInterfaces,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_interfaces.isEmpty)
            Text('Scanning...',
                style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    color: AppColors.gray))
          else
            Column(
              children: _interfaces.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.language_rounded, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 14,
                              color: AppColors.gray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: entry.value
                                .map((ip) => SelectableText(
                                      ip,
                                      style: const TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textBlack,
                                      ),
                                      textAlign: TextAlign.right,
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ServerStatusCard extends StatelessWidget {
  final ServerService server;
  final dynamic settings;
  static const String _fontFamily = 'Plus Jakarta Sans';

  const _ServerStatusCard({required this.server, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isRunning = server.status == ServerStatus.running;
    final isBusy = server.status == ServerStatus.starting ||
        server.status == ServerStatus.stopping;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRunning
              ? [const Color(0xFF4A6FA5), const Color(0xFF38547C)]
              : [const Color(0xFF555555), const Color(0xFF333333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isRunning ? const Color(0xFF4A6FA5) : Colors.grey)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status indicator
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: isBusy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(
                      isRunning
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 20),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center, // Vertically centered
              children: [
                Text(
                  isRunning ? 'Server is Running' : 'Server is Stopped',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRunning
                      ? 'Listening on port ${settings.port} • Uptime: ${server.uptime}'
                      : 'Click Start to launch the server',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              if (!isRunning)
                _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Start',
                  color: AppColors.usageGreen,
                  onTap: isBusy ? null : () => server.start(),
                ),
              if (isRunning) ...[
                _ActionButton(
                  icon: Icons.restart_alt_rounded,
                  label: 'Restart',
                  color: AppColors.usageOrange,
                  onTap: isBusy ? null : () => server.restart(),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.stop_rounded,
                  label: 'Stop',
                  color: AppColors.usageRed,
                  onTap: isBusy ? null : () => server.stop(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  static const String _fontFamily = 'Plus Jakarta Sans';
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color:
                _hovering ? widget.color : widget.color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
