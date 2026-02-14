import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/backup_provider.dart';
import '../providers/backup_picker_provider.dart';
import '../models/backup_config.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() =>
      _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  final _serverPathController = TextEditingController(text: '');

  @override
  void dispose() {
    _serverPathController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    try {
      String? result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        if (!mounted) return;

        final folderName = result.split(Platform.pathSeparator).last.toLowerCase();
        final dangerousFolders = {
          'backend',
          'node_modules',
          '.git',
          'build',
          'windows',
          'program files',
          'appdata'
        };

        bool isDangerous = dangerousFolders.any((d) => folderName.contains(d));

        if (isDangerous) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Warning', style: TextStyle(color: Colors.white, fontFamily: 'Plus Jakarta Sans')),
                ],
              ),
              content: Text(
                'The folder "$folderName" may contain system files or backend data that could cause infinite loops or slow performance. Are you sure you want to add it?',
                style: const TextStyle(color: Colors.white70, fontFamily: 'Plus Jakarta Sans', fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, Add it', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (confirm != true) return;
        }

        ref.read(backupPickerProvider.notifier).state = BackupPickerState(
          localPath: result,
          isPicking: true,
        );

        if (mounted) {
          context.push('/');
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('zenity')) {
          _showLinuxDependencyError(context, 'zenity');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Picker error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showLinuxDependencyError(BuildContext context, String dependency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orangeAccent),
            const SizedBox(width: 12),
            const Text('Linux Error',
                style: TextStyle(color: Colors.white, fontFamily: 'Plus Jakarta Sans')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The folder picker requires "$dependency" to be installed on your Linux system/WSL.',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, fontFamily: 'Plus Jakarta Sans'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Run this command in your terminal:',
              style: TextStyle(
                  color: Colors.white54, fontSize: 12, fontFamily: 'Plus Jakarta Sans'),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'sudo apt update && sudo apt install -y $dependency',
                style: const TextStyle(
                    color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Colors.white54, fontFamily: 'Plus Jakarta Sans')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(backupSettingsProvider);

    ref.read(backupServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('Auto Backup Settings',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('System Options'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildToggleRow(
                        'Launch at Startup',
                        'Automatically start Home Cloud when Windows starts.',
                        settings.launchAtStartup,
                        (val) => ref
                            .read(backupSettingsProvider.notifier)
                            .updateSettings(
                                settings.copyWith(launchAtStartup: val)),
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      _buildToggleRow(
                        'Minimize to Tray',
                        'Keep the app running in the system tray when closed.',
                        settings.minimizeToTray,
                        (val) => ref
                            .read(backupSettingsProvider.notifier)
                            .updateSettings(
                                settings.copyWith(minimizeToTray: val)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Monitored Folders'),
                    IconButton(
                      onPressed: _pickFolder,
                      icon: const Icon(Icons.add_rounded,
                          color: AppColors.primary),
                      tooltip: 'Add Folder',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (settings.folders.isEmpty)
                  _buildEmptyFolders()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: settings.folders.length,
                    itemBuilder: (context, index) {
                      final folder = settings.folders[index];
                      // Wrap each folder in a slightly different card style or list
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildFolderCard(folder, index),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.black45,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildToggleRow(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                        fontSize: 12, color: AppColors.gray)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref, int index,
      BackupFolder folder, Offset tapPosition) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                  folder.isEnabled
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 20,
                  color: AppColors.textBlack),
              const SizedBox(width: 12),
              Text(folder.isEnabled ? 'Pause Backup' : 'Resume Backup',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14)),
            ],
          ),
        ),
        if (folder.isEnabled)
          ref.read(backupServiceProvider).isSyncing
              ? PopupMenuItem<String>(
                  value: 'cancel_sync',
                  child: Row(
                    children: [
                      const Icon(Icons.stop_rounded,
                          size: 20, color: AppColors.usageRed),
                      const SizedBox(width: 12),
                      Text('Cancel Syncing',
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                              fontSize: 14, color: AppColors.usageRed)),
                    ],
                  ),
                )
              : PopupMenuItem<String>(
                  value: 'sync_all',
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded,
                          size: 20, color: AppColors.textBlack),
                      const SizedBox(width: 12),
                      Text('Sync All Files Now',
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14)),
                    ],
                  ),
                ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppColors.usageRed),
              const SizedBox(width: 12),
              Text('Remove Folder',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                      fontSize: 14, color: AppColors.usageRed)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'toggle') {
        ref
            .read(backupSettingsProvider.notifier)
            .toggleFolder(index, !folder.isEnabled);
      } else if (value == 'sync_all') {
        ref.read(backupServiceProvider).syncAllFiles(folder);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Syncing all files from ${folder.localPath.split(Platform.pathSeparator).last}...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (value == 'cancel_sync') {
        ref.read(backupServiceProvider).cancelSync();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup sync cancelled.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (value == 'delete') {
        ref.read(backupSettingsProvider.notifier).removeFolder(index);
      }
    });
  }

  Widget _buildFolderCard(BackupFolder folder, int index) {
    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, ref, index, folder, details.globalPosition),
      onLongPressDown: (details) =>
          _showContextMenu(context, ref, index, folder, details.globalPosition),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: folder.isEnabled
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: folder.isEnabled
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                folder.isEnabled
                    ? Icons.folder_open_rounded
                    : Icons.folder_off_rounded,
                color: folder.isEnabled ? AppColors.primary : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.localPath,
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: folder.isEnabled
                            ? AppColors.textBlack
                            : AppColors.gray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_forward_rounded,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Server: ${folder.serverPath.isEmpty ? "Root" : folder.serverPath}',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                            fontSize: 11, color: AppColors.gray),
                      ),
                      if (!folder.isEnabled) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(Paused)',
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                              fontSize: 11,
                              color: AppColors.usageRed,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert_rounded,
                color: AppColors.gray, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFolders() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.monitor_heart_rounded,
              size: 48, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No monitored folders',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Add folders to start auto backup',
            style:
                TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
