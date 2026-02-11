import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/providers/server_provider.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  static const String _fontFamily = 'Plus Jakarta Sans';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverServiceProvider);
    final logs = server.logs;

    // Auto scroll when new logs arrive
    if (_autoScroll && logs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Logs',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${logs.length} log entries',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 14,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Auto-scroll toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F4F9)),
                  ),
                  child: Row(
                    children: [
                      _ToolbarButton(
                        icon: Icons.vertical_align_bottom_rounded,
                        label: 'Auto-scroll',
                        isActive: _autoScroll,
                        onTap: () {
                          setState(() => _autoScroll = !_autoScroll);
                          if (_autoScroll) _scrollToBottom();
                        },
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: const Color(0xFFF1F4F9),
                      ),
                      _ToolbarButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Clear',
                        onTap: () => server.clearLogs(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Log viewer
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2D2D3F),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      // Terminal header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16161F),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFF2D2D3F)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5F56),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFBD2E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF27C93F),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'HomeCloud Server — Terminal',
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 12,
                                color: const Color(0xFF888899),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Log content
                      Expanded(
                        child: logs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.terminal_rounded,
                                      size: 48,
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No logs yet',
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 14,
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Start the server to see logs',
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 12,
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SelectionArea(
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: logs.length,
                                  itemBuilder: (context, index) {
                                    return _LogLine(
                                      text: logs[index],
                                      lineNumber: index + 1,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  static const String _fontFamily = 'Plus Jakarta Sans';
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : _hovering
                    ? const Color(0xFFF5F5F5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive ? AppColors.primary : AppColors.gray,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isActive ? AppColors.primary : AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  final String text;
  final int lineNumber;
  static const String _fontFamily = 'Plus Jakarta Sans';

  const _LogLine({required this.text, required this.lineNumber});

  Color _getLogColor() {
    if (text.contains('[ERROR]')) {
      return const Color(0xFFFF6B6B);
    }
    if (text.contains('[STDERR]')) {
      if (text.toLowerCase().contains('error') ||
          text.toLowerCase().contains('fail')) {
        return const Color(0xFFFF6B6B);
      }
      return const Color(0xFF62AEEF);
    }
    if (text.contains('[WARN]')) {
      return const Color(0xFFFFD93D);
    }
    if (text.contains('[INFO]')) {
      if (text.contains('Server running') || text.contains('Serving stream')) {
        return const Color(0xFF6BCB77);
      }
      return const Color(0xFF62AEEF);
    }
    return const Color(0xFFCDD6F4);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              lineNumber.toString(),
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12,
                color: Color(0xFF444466),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12,
                color: _getLogColor(),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
