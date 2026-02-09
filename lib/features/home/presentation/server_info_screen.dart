import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../models/system_info.dart';
import '../providers/file_provider.dart';
import 'dart:math' as math;

class ServerInfoScreen extends ConsumerStatefulWidget {
  const ServerInfoScreen({super.key});

  @override
  ConsumerState<ServerInfoScreen> createState() => _ServerInfoScreenState();
}

class _ServerInfoScreenState extends ConsumerState<ServerInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<double> cpuHistory = [];
  List<double> memoryHistory = [];
  static const int historyLength = 60;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    cpuHistory = List.filled(historyLength, 0.0);
    memoryHistory = List.filled(historyLength, 0.0);

    print('📊 [ServerInfo] Chart initialized with $historyLength points');
  }

  void _updateHistory(double cpu, double memory) {
    if (!mounted) return;

    print(
        '📊 [ServerInfo] Updating history - CPU: ${cpu.toStringAsFixed(1)}%, Memory: ${memory.toStringAsFixed(1)}%');

    List<double> newCpuHistory = List.from(cpuHistory);
    List<double> newMemoryHistory = List.from(memoryHistory);

    newCpuHistory.removeAt(0);
    newCpuHistory.add(cpu.clamp(0, 100));

    newMemoryHistory.removeAt(0);
    newMemoryHistory.add(memory.clamp(0, 100));

    setState(() {
      cpuHistory = newCpuHistory;
      memoryHistory = newMemoryHistory;
    });

    print(
        '📊 [ServerInfo] History updated - CPU last 5: ${cpuHistory.sublist(math.max(0, cpuHistory.length - 5))}');
  }

  @override
  void dispose() {
    cpuHistory.clear();
    memoryHistory.clear();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final systemInfoAsync = ref.watch(liveSystemInfoProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    ref.listen<AsyncValue<SystemInfo>>(liveSystemInfoProvider,
        (previous, next) {
      next.whenData((info) {
        final currentCpu = info.cpuProcess.usagePercent;
        final currentMemory = info.memory.usagePercent;

        if (cpuHistory.isNotEmpty) {
          _updateHistory(currentCpu, currentMemory);
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Server Status',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: systemInfoAsync.when(
        data: (systemInfo) {
          if (isDesktop) {
            return _buildDesktopLayout(systemInfo);
          }
          return _buildMobileLayout(systemInfo);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDesktopLayout(SystemInfo systemInfo) {
    final tabs = [
      _DesktopTabItem(
        icon: Icons.memory_rounded,
        label: 'CPU',
        subtitle: '${systemInfo.cpuProcess.usagePercent.toStringAsFixed(0)}%',
      ),
      _DesktopTabItem(
        icon: Icons.storage_rounded,
        label: 'Memory',
        subtitle: '${systemInfo.memory.usagePercent.toStringAsFixed(0)}%',
      ),
      _DesktopTabItem(
        icon: Icons.disc_full_rounded,
        label: 'Disk',
        subtitle: '${systemInfo.disks.length} drives',
      ),
      _DesktopTabItem(
        icon: Icons.wifi_rounded,
        label: 'Network',
        subtitle: '${systemInfo.network.downloadMbps.toStringAsFixed(0)} Mbps',
      ),
    ];

    return Row(
      children: [
        // Left sidebar with tabs
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            border: Border(
              right: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            children: [
              // Server info header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.computer_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            systemInfo.sys.hostname,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            systemInfo.sys.os,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Tab list
              Expanded(
                child: ListView.builder(
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    final isSelected = _tabController.index == index;
                    return InkWell(
                      onTap: () => setState(() => _tabController.index = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.white : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tabs[index].icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.gray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tabs[index].label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.textBlack
                                          : AppColors.gray,
                                    ),
                                  ),
                                  Text(
                                    tabs[index].subtitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.gray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Right content area
        Expanded(
          child: Container(
            color: AppColors.white,
            child: IndexedStack(
              index: _tabController.index,
              children: [
                _ProcessorTab(systemInfo: systemInfo, history: cpuHistory),
                _MemoryTab(systemInfo: systemInfo, history: memoryHistory),
                _StorageTab(systemInfo: systemInfo),
                _NetworkTab(systemInfo: systemInfo),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(SystemInfo systemInfo) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.computer_rounded,
                      color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        systemInfo.sys.hostname,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${systemInfo.sys.os} • ${systemInfo.sys.platform}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.gray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 50,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.textBlack,
              unselectedLabelColor: AppColors.gray,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'CPU'),
                Tab(text: 'RAM'),
                Tab(text: 'Disk'),
                Tab(text: 'Net'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ProcessorTab(systemInfo: systemInfo, history: cpuHistory),
              _MemoryTab(systemInfo: systemInfo, history: memoryHistory),
              _StorageTab(systemInfo: systemInfo),
              _NetworkTab(systemInfo: systemInfo),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopTabItem {
  final IconData icon;
  final String label;
  final String subtitle;

  _DesktopTabItem({
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}

class _ProcessorTab extends StatelessWidget {
  final SystemInfo systemInfo;
  final List<double> history;
  const _ProcessorTab({required this.systemInfo, required this.history});

  @override
  Widget build(BuildContext context) {
    final cpuInfo = systemInfo.cpu.isNotEmpty ? systemInfo.cpu[0] : null;
    final usage = systemInfo.cpuProcess.usagePercent;

    print(
        '📊 [_ProcessorTab] Building with ${history.length} history points, current: $usage%');
    print(
        '📊 [_ProcessorTab] Last 10 values: ${history.sublist(math.max(0, history.length - 10))}');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(title: 'Processor Details'),
        const SizedBox(height: 12),
        _ModernInfoCard(
          child: Column(
            children: [
              _ModernInfoRow(
                  label: 'Model',
                  value: cpuInfo?.modelName ?? 'Unknown',
                  isBold: true),
              const _ModernDivider(),
              _ModernInfoRow(label: 'Cores', value: systemInfo.os.cpuCount),
              const _ModernDivider(),
              _ModernInfoRow(
                label: 'Base Speed',
                value: '${((cpuInfo?.mhz ?? 0) / 1000).toStringAsFixed(2)} GHz',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Performance'),
        const SizedBox(height: 12),
        _ChartContainer(
          label: 'Utilization',
          value: '${usage.toStringAsFixed(0)}%',
          usage: usage / 100,
          history: history,
          color: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatItem(
                      label: 'Processes', value: '${systemInfo.process.count}'),
                  const Spacer(),
                  _StatItem(
                      label: 'Threads', value: '${systemInfo.process.threads}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemoryTab extends StatelessWidget {
  final SystemInfo systemInfo;
  final List<double> history;
  const _MemoryTab({required this.systemInfo, required this.history});

  @override
  Widget build(BuildContext context) {
    final memory = systemInfo.memory;
    final usagePercent = memory.usagePercent;
    final usedGB = memory.used / (1024 * 1024 * 1024);
    final freeGB = memory.free / (1024 * 1024 * 1024);
    final totalGB = memory.total / (1024 * 1024 * 1024);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(title: 'Memory Usage'),
        const SizedBox(height: 12),
        _ChartContainer(
          label: 'Memory',
          value: '${usagePercent.toStringAsFixed(1)}%',
          usage: usagePercent / 100,
          history: history,
          color: const Color(0xFF8E44AD),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _LegendItem(
                      color: const Color(0xFF8E44AD),
                      label: 'Used',
                      value: '${usedGB.toStringAsFixed(2)} GB'),
                  _LegendItem(
                      color: const Color(0xFFF1F4F9),
                      label: 'Free',
                      value: '${freeGB.toStringAsFixed(2)} GB'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Detailed Stats'),
        const SizedBox(height: 12),
        _ModernInfoCard(
          child: Column(
            children: [
              _ModernInfoRow(
                  label: 'Total', value: '${totalGB.toStringAsFixed(2)} GB'),
              const _ModernDivider(),
              _ModernInfoRow(
                  label: 'Used', value: '${usedGB.toStringAsFixed(2)} GB'),
              const _ModernDivider(),
              _ModernInfoRow(
                  label: 'Free', value: '${freeGB.toStringAsFixed(2)} GB'),
              const _ModernDivider(),
              _ModernInfoRow(
                  label: 'Usage', value: '${usagePercent.toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StorageTab extends ConsumerWidget {
  final SystemInfo systemInfo;
  const _StorageTab({required this.systemInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(title: 'Disks'),
        const SizedBox(height: 12),
        ...systemInfo.disks.map((disk) {
          final isProj = disk.isProjectDisk;
          final usagePercent =
              isProj ? disk.usagePercentReal : disk.usagePercent;
          final usedGB =
              (isProj ? disk.realUsed : disk.used) / (1024 * 1024 * 1024);
          final freeGB =
              (isProj ? disk.realFree : disk.free) / (1024 * 1024 * 1024);
          final totalGB =
              (isProj ? disk.realTotal : disk.total) / (1024 * 1024 * 1024);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ModernInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(disk.label.isNotEmpty ? disk.label : disk.mountpoint,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (isProj) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('SERVER DISK',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  Text(disk.mountpoint,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.gray,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('${usagePercent.toStringAsFixed(1)}%',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('used',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.gray,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 10,
                    percent: (usagePercent / 100).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFF1F4F9),
                    progressColor: AppColors.primary,
                    barRadius: const Radius.circular(5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StorageDetailChip(
                          label: 'Used',
                          value: '${usedGB.toStringAsFixed(2)} GB',
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      _StorageDetailChip(
                          label: 'Free',
                          value: '${freeGB.toStringAsFixed(2)} GB',
                          color: AppColors.usageGreen),
                      const SizedBox(width: 8),
                      _StorageDetailChip(
                          label: 'Total',
                          value: '${totalGB.toStringAsFixed(2)} GB',
                          color: AppColors.gray),
                    ],
                  ),
                  if (isProj) ...[
                    const SizedBox(height: 24),
                    const _ModernDivider(),
                    const SizedBox(height: 16),
                    Text('Cloud Quota (Home Screen)',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _SmallQuotaItem(
                          label: 'Used / Quota',
                          value:
                              '${(disk.used / (1024 * 1024 * 1024)).toStringAsFixed(1)} / ${(disk.total / (1024 * 1024 * 1024)).toStringAsFixed(0)} GB',
                        ),
                        const SizedBox(width: 8),
                        _SmallQuotaItem(
                          label: 'Free Quota',
                          value:
                              '${(disk.free / (1024 * 1024 * 1024)).toStringAsFixed(0)} GB',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StorageDetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StorageDetailChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _NetworkTab extends StatelessWidget {
  final SystemInfo systemInfo;
  const _NetworkTab({required this.systemInfo});

  @override
  Widget build(BuildContext context) {
    final network = systemInfo.network;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(title: 'Network Gauges'),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F4F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SpeedGauge(
                      value: network.downloadMbps,
                      label: 'Mbps',
                      title: 'Download',
                      gradientColors: const [
                        Color(0xFF4ACFAC),
                        Color(0xFF7EF29D)
                      ],
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SpeedGauge(
                      value: network.uploadMbps,
                      label: 'Mbps',
                      title: 'Upload',
                      gradientColors: const [
                        Color(0xFF3249CF),
                        Color(0xFFBD66CC)
                      ],
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Data Transmission'),
        const SizedBox(height: 12),
        _ModernInfoCard(
          child: Column(
            children: [
              _ModernInfoRow(
                label: 'Download Speed',
                value: '${network.downloadMBps.toStringAsFixed(2)} MB/s',
              ),
              const _ModernDivider(),
              _ModernInfoRow(
                label: 'Upload Speed',
                value: '${network.uploadMBps.toStringAsFixed(2)} MB/s',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final String label;
  final String value;
  final double usage;
  final List<double> history;
  final Color color;
  final Widget child;

  const _ChartContainer({
    required this.label,
    required this.value,
    required this.usage,
    required this.history,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    print('📊 [_ChartContainer] Building chart with ${history.length} points');
    print(
        '📊 [_ChartContainer] Min: ${history.reduce(math.min)}, Max: ${history.reduce(math.max)}');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F4F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textBlack)),
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F4F9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _AxisLabel(label: '100'),
                      _AxisLabel(label: '75'),
                      _AxisLabel(label: '50'),
                      _AxisLabel(label: '25'),
                      _AxisLabel(label: '0'),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _ChartPainter(
                      history: history,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> history;
  final Color color;

  _ChartPainter({required this.history, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    print(
        '📊 [_ChartPainter] Painting chart with size: $size, points: ${history.length}');

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    const cols = 15;
    final cellWidth = size.width / cols;
    for (var i = 1; i < cols; i++) {
      canvas.drawLine(Offset(i * cellWidth, 0),
          Offset(i * cellWidth, size.height), gridPaint);
    }

    const rows = 6;
    final cellHeight = size.height / rows;
    for (var i = 1; i < rows; i++) {
      canvas.drawLine(Offset(0, i * cellHeight),
          Offset(size.width, i * cellHeight), gridPaint);
    }

    if (history.isEmpty || history.length < 2) {
      print('⚠️ [_ChartPainter] Not enough data points');
      return;
    }

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (history.length - 1);

    for (var i = 0; i < history.length; i++) {
      final x = i * stepX;

      final y = size.height - (history[i] / 100 * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == history.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    print('✅ [_ChartPainter] Chart painted successfully');
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    final shouldRepaint = oldDelegate.history != history;
    print('📊 [_ChartPainter] shouldRepaint: $shouldRepaint');
    return shouldRepaint;
  }
}

class _SpeedGauge extends StatelessWidget {
  final double value;
  final String label;
  final String title;
  final List<Color> gradientColors;
  final IconData icon;

  const _SpeedGauge({
    required this.value,
    required this.label,
    required this.title,
    required this.gradientColors,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.gray,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 200),
                painter: _GaugePainter(
                  value: value,
                  max: 100,
                  gradientColors: gradientColors,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 30),
                  Icon(icon, color: AppColors.textBlack, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    value.toStringAsFixed(0),
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textBlack,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.gray,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double max;
  final List<Color> gradientColors;

  _GaugePainter({
    required this.value,
    required this.max,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const startAngle = 3 * math.pi / 4;
    const sweepAngle = 3 * math.pi / 2;

    final trackPaint = Paint()
      ..color = const Color(0xFFF1F4F9)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    final currentSweep = (value / max).clamp(0.0, 1.0) * sweepAngle;
    final fillPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        transform: const GradientRotation(startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      fillPaint,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final scalePoints = [0, 1, 5, 10, 20, 30, 50, 75, 100];
    for (final point in scalePoints) {
      final ratio = point / 100;
      final angle = startAngle + ratio * sweepAngle;

      final dotPaint = Paint()
        ..color = ratio <= (value / 100)
            ? gradientColors[0]
            : const Color(0xFFC1C7D0).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final dotPos = Offset(
        center.dx + (radius - 20) * math.cos(angle),
        center.dy + (radius - 20) * math.sin(angle),
      );
      canvas.drawCircle(dotPos, 2, dotPaint);

      if (point == 0 || point == 100 || point == 50) {
        textPainter.text = TextSpan(
          text: '$point',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.gray,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        final textPos = Offset(
          center.dx + (radius - 35) * math.cos(angle) - textPainter.width / 2,
          center.dy + (radius - 35) * math.sin(angle) - textPainter.height / 2,
        );
        textPainter.paint(canvas, textPos);
      }
    }

    final needleAngle = startAngle + (value / max).clamp(0.0, 1.0) * sweepAngle;
    final needlePaint = Paint()
      ..color = AppColors.textBlack.withValues(alpha: 0.8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx + 10 * math.cos(needleAngle),
          center.dy + 10 * math.sin(needleAngle)),
      Offset(center.dx + (radius - 15) * math.cos(needleAngle),
          center.dy + (radius - 15) * math.sin(needleAngle)),
      needlePaint,
    );

    canvas.drawCircle(center, 6, Paint()..color = AppColors.textBlack);
    canvas.drawCircle(center, 3, Paint()..color = gradientColors[0]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.gray,
            letterSpacing: 1.2));
  }
}

class _ModernInfoCard extends StatelessWidget {
  final Widget child;
  const _ModernInfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F4F9)),
      ),
      child: child,
    );
  }
}

class _ModernInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _ModernInfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align to top for wrapping
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.gray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textBlack,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
              overflow: TextOverflow.visible, // Allow wrapping
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDivider extends StatelessWidget {
  const _ModernDivider();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Color(0xFFF1F4F9)),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String label;
  const _AxisLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.plusJakartaSans(
            color: AppColors.gray.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.bold));
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.gray,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendItem(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.gray,
                    fontWeight: FontWeight.bold,
                    fontSize: 10)),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (math.log(bytes) / math.log(1024)).floor();
  return '${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
}

class _SmallQuotaItem extends StatelessWidget {
  final String label;
  final String value;
  const _SmallQuotaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.gray,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
