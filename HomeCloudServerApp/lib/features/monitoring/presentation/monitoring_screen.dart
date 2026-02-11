import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../services/local_system_service.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final _service = LocalSystemService();
  SystemUsage? _usage;
  Timer? _timer;
  static const String _fontFamily = 'Plus Jakarta Sans';

  @override
  void initState() {
    super.initState();
    _fetchUsage();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchUsage());
  }

  void _fetchUsage() async {
    final usage = await _service.getSystemUsage();
    if (mounted) setState(() => _usage = usage);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_usage == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Monitoring',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time system resource usage',
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
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'CPU Usage',
                        value: '${_usage!.cpuPercent.toStringAsFixed(1)}%',
                        percent: _usage!.cpuPercent / 100,
                        color: AppColors.primary,
                        icon: Icons.memory_rounded,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _StatCard(
                        title: 'RAM Usage',
                        value: '${_usage!.memoryPercent.toStringAsFixed(1)}%',
                        percent: _usage!.memoryPercent / 100,
                        color: const Color(0xFF8E44AD),
                        icon: Icons.storage_rounded,
                        subtitle:
                            '${(_usage!.memoryUsed / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB / ${(_usage!.memoryTotal / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Disk (C:)',
                        value: '${_usage!.diskPercent.toStringAsFixed(1)}%',
                        percent: _usage!.diskPercent / 100,
                        color: const Color(0xFFE67E22),
                        icon: Icons.disc_full_rounded,
                        subtitle:
                            '${(_usage!.diskUsed / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB / ${(_usage!.diskTotal / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Expanded(
                        child: SizedBox()), // Placeholder for balance
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final double percent;
  final Color color;
  final IconData icon;
  final String? subtitle;
  static const String _fontFamily = 'Plus Jakarta Sans';

  const _StatCard({
    required this.title,
    required this.value,
    required this.percent,
    required this.color,
    required this.icon,
    this.subtitle,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 16,
                      color: AppColors.textBlack,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Text(value,
              style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!,
                style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    color: AppColors.gray),
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 8,
            percent: percent.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF1F4F9),
            progressColor: color,
            barRadius: const Radius.circular(4),
          ),
        ],
      ),
    );
  }
}
