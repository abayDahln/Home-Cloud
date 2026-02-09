import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import 'package:device_info_plus/device_info_plus.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/file_provider.dart';
import '../models/system_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import 'widgets/video_player_dialog.dart';
import 'widgets/audio_player_dialog.dart';
import 'widgets/image_viewer_dialog.dart';
import 'widgets/desktop_sidebar.dart';
import '../providers/backup_picker_provider.dart';
import '../providers/backup_provider.dart';
import '../models/backup_config.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

final streamApiClientProvider = Provider<ApiClient>((ref) {
  final authState = ref.watch(authProvider);
  final client = ApiClient(
    baseUrl: authState.serverUrl ?? 'http://localhost:8080',
    authToken: authState.password,
  );
  return client;
});

class HomeScreen extends ConsumerStatefulWidget {
  final String currentPath;
  const HomeScreen({super.key, this.currentPath = ''});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ requires granular permissions
        await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
          Permission.notification,
        ].request();
      } else {
        // Older Android
        await [
          Permission.storage,
        ].request();
      }

      // Important for DCIM/Camera and other root-level access on many devices
      if (androidInfo.version.sdkInt >= 30) {
        if (!await Permission.manageExternalStorage.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }

      // Ignore battery optimizations for reliable background sync
      if (!await Permission.ignoreBatteryOptimizations.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentPathProvider, (prev, next) {});

    final currentPath = widget.currentPath;
    final fileListAsync = ref.watch(filteredFilesProvider(currentPath));
    final systemInfoAsync = ref.watch(systemInfoProvider);
    final movingItems = ref.watch(movingItemsProvider);
    final backupPicker = ref.watch(backupPickerProvider);
    final selectedItems = ref.watch(selectedItemsProvider);
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600;

    Future.microtask(() {
      final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
      if (!isCurrent) return;

      if (ref.read(currentPathProvider) != currentPath) {
        ref.read(currentPathProvider.notifier).navigateTo(currentPath);

        ref.read(searchQueryProvider.notifier).state = "";
        _searchController.clear();
        if (mounted && _isSearching) {
          setState(() => _isSearching = false);
        }

        // Clear selection on directory change if not moving items
        if (ref.read(movingItemsProvider) == null) {
          ref.read(selectedItemsProvider.notifier).state = {};
        }
      }
    });

    Widget mainContent;
    if (isDesktop) {
      mainContent = Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: Row(
          children: [
            const DesktopSidebar(),
            Expanded(
              child: _buildMainContent(
                context,
                ref,
                currentPath,
                fileListAsync,
                systemInfoAsync,
                movingItems,
                backupPicker,
                isDesktop: true,
                isTablet: true,
              ),
            ),
          ],
        ),
      );
    } else {
      mainContent = Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: isSelectionMode ? AppColors.textBlack : Colors.white,
          iconTheme: IconThemeData(
              color: isSelectionMode ? Colors.white : AppColors.textBlack),
          title: isSelectionMode
              ? Text('${selectedItems.length} selected',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.bold))
              : (_isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textBlack, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Search files...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                      },
                    )
                  : Text('Home Cloud',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold))),
          centerTitle: false,
          leading: isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () =>
                      ref.read(selectedItemsProvider.notifier).state = {},
                )
              : null,
          actions: isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                    onPressed: () => _handleBulkDelete(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_outlined,
                        color: Colors.white),
                    onPressed: () => _handleBulkMove(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.select_all_rounded,
                        color: Colors.white),
                    tooltip: 'Select All',
                    onPressed: () {
                      final files =
                          ref.read(filteredFilesProvider(currentPath)).value;
                      if (files != null) {
                        ref.read(selectedItemsProvider.notifier).state =
                            files.map((f) => f.path).toSet();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ]
              : [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = "";
                        }
                      });
                    },
                  ),
                  _buildSortButton(context, ref),
                  const SizedBox(width: 8),
                ],
        ),
        drawer: _buildMobileDrawer(context, ref),
        body: _buildMainContent(
          context,
          ref,
          currentPath,
          fileListAsync,
          systemInfoAsync,
          movingItems,
          backupPicker,
          isDesktop: false,
          isTablet: isTablet,
        ),
        floatingActionButton: movingItems == null
            ? FloatingActionButton(
                onPressed: () => _showAddMenu(context, ref),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.add, color: AppColors.white, size: 28),
              )
            : null,
      );
    }

    return BackButtonListener(
      onBackButtonPressed: () async {
        // Priority 1: If in selection mode, cancel selection
        if (isSelectionMode) {
          ref.read(selectedItemsProvider.notifier).state = {};
          return true; // Consume the back button
        }

        // Priority 2: If not at root, navigate back to parent folder
        if (currentPath.isNotEmpty) {
          context.pop();
          return true; // Consume the back button
        }

        // Priority 3: At root with no selection, show exit confirmation
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Exit App',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            content: Text(
              'Are you sure you want to exit Home Cloud?',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.gray,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.usageRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Exit',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
        return true; // Always consume back button at root
      },
      child: mainContent,
    );
  }

  Widget _buildMobileDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.cloud_circle_rounded,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Text(
                    'Home Cloud',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.backup_rounded, color: AppColors.primary),
            title: Text(
              'Auto Backup',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/backup-settings');
            },
          ),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: AppColors.usageRed.withValues(alpha: 0.1),
              leading:
                  const Icon(Icons.logout_rounded, color: AppColors.usageRed),
              title: Text(
                'Logout',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppColors.usageRed,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showStyledDialog(
                  context: context,
                  title: 'Logout',
                  child: const Text('Are you sure you want to logout?'),
                  onConfirm: () => ref.read(authProvider.notifier).logout(),
                  confirmText: 'Logout',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    String currentPath,
    AsyncValue<List<FileItem>> fileListAsync,
    AsyncValue<SystemInfo> systemInfoAsync,
    List<FileItem>? movingItems,
    BackupPickerState? backupPicker, {
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(fileListProvider(currentPath));
            ref.invalidate(systemInfoProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (!isDesktop)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: systemInfoAsync.when(
                      data: (systemInfo) {
                        final projectDisk = systemInfo.projectDisk;
                        if (projectDisk == null) return const SizedBox.shrink();

                        final usagePercent = projectDisk.usagePercent;
                        final usedGB = projectDisk.used / (1024 * 1024 * 1024);
                        final freeGB = projectDisk.free / (1024 * 1024 * 1024);
                        final totalGB =
                            projectDisk.total / (1024 * 1024 * 1024);

                        return InkWell(
                          onTap: () => context.push('/server-info'),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(24),
                              border:
                                  Border.all(color: const Color(0xFFF1F4F9)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                          Icons.cloud_queue_rounded,
                                          color: AppColors.primary,
                                          size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cloud Storage',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textBlack),
                                          ),
                                          Text(
                                            systemInfo.sys.hostname,
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color: AppColors.gray,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: AppColors.gray),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${usagePercent.toStringAsFixed(1)}%',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textBlack),
                                          ),
                                          Text(
                                            'Used',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color: AppColors.gray,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF5EF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Running',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: const Color(0xFF2E7D32),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
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
                                    _StorageDetailItem(
                                        label: 'Used',
                                        value:
                                            '${usedGB.toStringAsFixed(2)} GB',
                                        color: AppColors.primary),
                                    const SizedBox(width: 16),
                                    _StorageDetailItem(
                                        label: 'Free',
                                        value:
                                            '${freeGB.toStringAsFixed(2)} GB',
                                        color: AppColors.usageGreen),
                                    const SizedBox(width: 16),
                                    _StorageDetailItem(
                                        label: 'Total',
                                        value:
                                            '${totalGB.toStringAsFixed(2)} GB',
                                        color: AppColors.gray),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => _LoadingPlaceholder(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 20,
                    vertical: isDesktop ? 16 : 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF1F4F9).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      if (currentPath.isNotEmpty) ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back_rounded,
                                            size: 20,
                                            color: AppColors.gray,
                                          ),
                                          onPressed: () => context.pop(),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      GestureDetector(
                                        onTap: () {
                                          while (context.canPop()) {
                                            context.pop();
                                          }
                                        },
                                        child: const Icon(
                                          Icons.devices_rounded,
                                          size: 20,
                                          color: AppColors.gray,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (currentPath.isEmpty) ...[
                                        const Icon(Icons.chevron_right_rounded,
                                            size: 18, color: Color(0xFFC1C7D0)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'All Files',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textBlack),
                                        ),
                                      ] else ...[
                                        Text(currentPath,
                                            style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold))
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (isDesktop) ...[
                                const SizedBox(width: 16),
                                Container(
                                  width: 250,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFE1E5EC)),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Search...',
                                      prefixIcon: Icon(Icons.search,
                                          size: 16, color: AppColors.gray),
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      ref
                                          .read(searchQueryProvider.notifier)
                                          .state = value;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildSortButton(context, ref),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isDesktop && movingItems == null) ...[
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddMenu(context, ref),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              fileListAsync.when(
                data: (files) {
                  if (files.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open_rounded,
                                size: 80, color: Color(0xFFE1E5EC)),
                            const SizedBox(height: 16),
                            Text(
                              'No items yet',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  color: AppColors.gray,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (isTablet) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final crossAxisCount = isDesktop
                        ? (screenWidth > 1400 ? 6 : 5)
                        : (screenWidth > 700 ? 4 : 3);

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 16,
                        8,
                        isDesktop ? 24 : 16,
                        120,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _FileGridCard(
                            file: files[index],
                            allFiles: files,
                          ),
                          childCount: files.length,
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _FileListCard(
                          file: files[index],
                          allFiles: files,
                        ),
                        childCount: files.length,
                      ),
                    ),
                  );
                },
                error: (err, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $err')),
                ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        ),
        if (movingItems != null && movingItems.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textBlack,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    movingItems.length == 1
                        ? (movingItems.first.isDir
                            ? Icons.folder_rounded
                            : Icons.insert_drive_file_rounded)
                        : Icons.copy_all_rounded,
                    color: AppColors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Moving ${movingItems.length} items',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          movingItems.length == 1
                              ? movingItems.first.name
                              : '${movingItems.first.name} + ${movingItems.length - 1} more',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.white60),
                    onPressed: () =>
                        ref.read(movingItemsProvider.notifier).state = null,
                    child: Text('Cancel',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final currentPath = widget.currentPath;

                      bool invalid = false;
                      for (var item in movingItems) {
                        if (item.path == currentPath ||
                            (currentPath.startsWith('${item.path}/'))) {
                          invalid = true;
                          break;
                        }
                      }

                      if (invalid) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Cannot move folder into itself')),
                          );
                        }
                        return;
                      }

                      // Get source paths before clearing movingItems
                      final sourcePaths = movingItems
                          .map((e) => e.path.contains('/')
                              ? e.path.substring(0, e.path.lastIndexOf('/'))
                              : '')
                          .toSet();

                      final success = await ref
                          .read(fileOpsProvider.notifier)
                          .moveMultipleItems(
                              movingItems.map((e) => e.path).toList(),
                              currentPath);

                      if (success) {
                        // Clear moving state
                        ref.read(movingItemsProvider.notifier).state = null;
                        // Clear selection (selection mode is derived, clears automatically)
                        ref.read(selectedItemsProvider.notifier).state = {};

                        // Invalidate destination
                        ref.invalidate(fileListProvider(currentPath));
                        // Invalidate all source paths
                        for (final path in sourcePaths) {
                          ref.invalidate(fileListProvider(path));
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Moved successfully'),
                                backgroundColor: Color(0xFF2E7D32)),
                          );
                        }
                      }
                    },
                    child: Text('Move Here',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        if (backupPicker != null && backupPicker.isPicking)
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C1E),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.backup_rounded,
                    color: AppColors.usageGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pick folder for Backup',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currentPath.isEmpty ? 'Root Storage' : currentPath,
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(backupPickerProvider.notifier).state = null;
                      if (context.mounted && context.canPop()) {
                        context.pop();
                      }
                    },
                    child: Text('Cancel',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white60,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.usageGreen,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final localPath = backupPicker.localPath;
                      if (localPath != null) {
                        ref.read(backupSettingsProvider.notifier).addFolder(
                              BackupFolder(
                                  localPath: localPath,
                                  serverPath: currentPath),
                            );
                        ref.read(backupPickerProvider.notifier).state = null;
                        if (context.mounted && context.canPop()) {
                          context.pop();
                        }
                      }
                    },
                    child: Text('Pick This Folder',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        const _UploadProgressOverlay(),
      ],
    );
  }

  Widget _buildSortButton(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(sortTypeProvider);

    return PopupMenuButton<FileSortType>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Sort by',
      onSelected: (type) {
        ref.read(sortTypeProvider.notifier).state = type;
      },
      itemBuilder: (context) => [
        _buildSortItem(FileSortType.nameAZ, 'Name (A-Z)',
            Icons.sort_by_alpha_rounded, currentSort),
        _buildSortItem(FileSortType.nameZA, 'Name (Z-A)',
            Icons.sort_by_alpha_rounded, currentSort),
        _buildSortItem(FileSortType.sizeAsc, 'Size (Smallest)',
            Icons.vertical_align_top_rounded, currentSort),
        _buildSortItem(FileSortType.sizeDesc, 'Size (Largest)',
            Icons.vertical_align_bottom_rounded, currentSort),
        _buildSortItem(FileSortType.dateNewest, 'Date (Newest)',
            Icons.calendar_today_rounded, currentSort),
        _buildSortItem(FileSortType.dateOldest, 'Date (Oldest)',
            Icons.calendar_today_rounded, currentSort),
      ],
    );
  }

  PopupMenuItem<FileSortType> _buildSortItem(FileSortType type, String label,
      IconData icon, FileSortType currentSort) {
    final isSelected = type == currentSort;
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AppColors.primary : null),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: isSelected ? FontWeight.bold : null,
              color: isSelected ? AppColors.primary : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: const Color(0xFFEDF0F5),
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 24),
            Text('Create New',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _AddOptionTile(
              icon: Icons.create_new_folder_outlined,
              title: 'New Folder',
              subtitle: 'Create a new folder',
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateFolderDialog(context, ref);
              },
            ),
            _AddOptionTile(
              icon: Icons.upload_file_outlined,
              title: 'Upload File',
              subtitle: 'Upload files from your device',
              onTap: () {
                Navigator.pop(sheetContext);
                _uploadFiles(context, ref);
              },
            ),
            _AddOptionTile(
              icon: Icons.drive_folder_upload_outlined,
              title: 'Upload Folder',
              subtitle: 'Upload an entire folder',
              onTap: () {
                Navigator.pop(sheetContext);
                _uploadFolder(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFiles(BuildContext context, WidgetRef ref) async {
    try {
      print('🔍 [_uploadFiles] Function called');
      print('🔍 [_uploadFiles] Starting file picker...');

      final result = await FilePicker.platform.pickFiles(allowMultiple: true);

      print('🔍 [_uploadFiles] File picker returned');
      print('🔍 [_uploadFiles] Result is null: ${result == null}');

      if (result == null) {
        print('⚠️ [_uploadFiles] User cancelled file picker');
        return;
      }

      print('🔍 [_uploadFiles] Files count: ${result.files.length}');

      if (result.files.isEmpty) {
        print('⚠️ [_uploadFiles] No files selected');
        return;
      }

      if (!context.mounted) {
        print('⚠️ [_uploadFiles] Context not mounted');
        return;
      }

      final currentPath = ref.read(currentPathProvider);
      print('🔍 [_uploadFiles] Current path: "$currentPath"');

      final count = result.files.length;
      print('📤 [_uploadFiles] Will upload $count file(s)');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploading $count file(s)...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      int successCount = 0;
      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        print(
            '📤 [_uploadFiles] Processing file ${i + 1}/$count: ${file.name}');

        if (file.path == null) {
          print('⚠️ [_uploadFiles] File ${i + 1} has no path');
          continue;
        }

        print('📤 [_uploadFiles] File path: ${file.path}');
        print('📤 [_uploadFiles] Calling uploadFile...');

        try {
          print('🔍 [_uploadFiles] Getting fileOpsProvider...');
          final fileOps = ref.read(fileOpsProvider.notifier);
          print('🔍 [_uploadFiles] fileOpsProvider obtained');

          print('🔍 [_uploadFiles] Calling uploadFile method...');
          final success = await fileOps.uploadFile(
            currentPath,
            file.path!,
            file.name,
            uploadId: 'upload_${DateTime.now().microsecondsSinceEpoch}_$i',
            ref: ref,
          );

          print('📤 [_uploadFiles] uploadFile returned: $success');

          if (success) {
            successCount++;
            print('✅ [_uploadFiles] File ${i + 1} uploaded successfully');
          } else {
            print('❌ [_uploadFiles] File ${i + 1} upload failed');
          }
        } catch (e, stack) {
          print('❌ [_uploadFiles] Error uploading file ${i + 1}: $e');
          print('❌ [_uploadFiles] Error type: ${e.runtimeType}');
          print('❌ [_uploadFiles] Stack trace: $stack');
        }
      }

      print('📊 [_uploadFiles] Upload summary: $successCount/$count files');

      if (!context.mounted) {
        print('⚠️ [_uploadFiles] Context not mounted after upload');
        return;
      }

      print('🔄 [_uploadFiles] Invalidating fileListProvider...');
      ref.invalidate(fileListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded $successCount of $count file(s)'),
          backgroundColor:
              successCount > 0 ? const Color(0xFF2E7D32) : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      print('✅ [_uploadFiles] Upload completed: $successCount/$count files');
    } catch (e, stack) {
      print('❌ [_uploadFiles] Fatal error: $e');
      print('❌ [_uploadFiles] Error type: ${e.runtimeType}');
      print('❌ [_uploadFiles] Stack trace: $stack');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _uploadFolder(BuildContext context, WidgetRef ref) async {
    try {
      print('🔍 Requesting storage permissions...');

      if (Platform.isAndroid) {
        var status = await Permission.manageExternalStorage.status;
        print('🔍 Current permission status: $status');

        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          print('🔍 Permission after request: $status');

          if (status.isDenied || status.isPermanentlyDenied) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Storage permission is required to upload folders'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
            return;
          }
        }
      }

      print('🔍 Opening directory picker...');
      final String? directoryPath =
          await FilePicker.platform.getDirectoryPath();

      print('🔍 Selected directory: $directoryPath');

      if (directoryPath != null) {
        if (!context.mounted) return;
        final currentPath = ref.read(currentPathProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scanning folder...'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        print('📁 Scanning directory: $directoryPath');

        final dir = Directory(directoryPath);
        final List<File> files = [];

        try {
          await for (final entity
              in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final relativePath = entity.path.replaceFirst(dir.path, '');
              final segments = relativePath.split(Platform.pathSeparator);
              final isHidden = segments.any((s) => s.startsWith('.'));

              if (isHidden) {
                print('⏭️ Skipping hidden file/folder: ${entity.path}');
                continue;
              }

              files.add(entity);
              print('📄 Found file: ${entity.path}');
            }
          }

          print('📁 Total files found (excluding hidden): ${files.length}');
        } catch (e, stack) {
          print('❌ Error scanning folder: $e');
          print('Stack trace: $stack');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error scanning folder: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        if (files.isEmpty) {
          print('⚠️ No files found in folder');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No files found in folder')),
            );
          }
          return;
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading ${files.length} files...'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        int successCount = 0;

        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          print('📤 Uploading file ${i + 1}/${files.length}: ${file.path}');

          try {
            final relativePath = file.path
                .replaceFirst(dir.parent.path, '')
                .replaceAll(Platform.pathSeparator, '/');

            final cleanRelativePath = relativePath.startsWith('/')
                ? relativePath.substring(1)
                : relativePath;

            String uploadPath;
            final lastSlash = cleanRelativePath.lastIndexOf('/');
            if (lastSlash == -1) {
              uploadPath = currentPath;
            } else {
              final folderPart = cleanRelativePath.substring(0, lastSlash);
              uploadPath =
                  currentPath.isEmpty ? folderPart : '$currentPath/$folderPart';
            }

            final success = await ref.read(fileOpsProvider.notifier).uploadFile(
                  uploadPath,
                  file.path,
                  file.path.split(Platform.pathSeparator).last,
                  uploadId:
                      'upload_${DateTime.now().microsecondsSinceEpoch}_$i',
                  ref: ref,
                );

            if (success) {
              successCount++;
              print('✅ File ${i + 1} uploaded successfully');
            } else {
              print('❌ File ${i + 1} upload failed');
            }
          } catch (e, stack) {
            print('❌ Error uploading file ${i + 1}: $e');
            print('Stack trace: $stack');
          }
        }

        if (!context.mounted) return;
        ref.invalidate(fileListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded $successCount of ${files.length} files'),
            backgroundColor:
                successCount > 0 ? const Color(0xFF2E7D32) : Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        print('✅ Folder upload completed: $successCount/${files.length} files');
      } else {
        print('⚠️ No directory selected');
      }
    } catch (e, stack) {
      print('❌ Fatal error in _uploadFolder: $e');
      print('Stack trace: $stack');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    _showStyledDialog(
      context: context,
      title: 'New Folder',
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Folder name'),
        autofocus: true,
      ),
      onConfirm: () async {
        if (controller.text.isNotEmpty) {
          final currentPath = widget.currentPath;
          final success = await ref
              .read(fileOpsProvider.notifier)
              .createFolder(currentPath, controller.text);
          if (success) ref.invalidate(fileListProvider(currentPath));
        }
      },
      confirmText: 'Create',
    );
  }

  void _handleBulkDelete(BuildContext context, WidgetRef ref) {
    handleBulkDelete(context, ref, widget.currentPath);
  }

  void _handleBulkMove(BuildContext context, WidgetRef ref) {
    handleBulkMove(context, ref, widget.currentPath);
  }
}

class _StorageDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StorageDetailItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.gray,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textBlack,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AddOptionTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(title,
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle,
          style:
              GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.gray)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _FileThumbnail extends ConsumerWidget {
  final FileItem file;
  final double size;
  const _FileThumbnail({required this.file, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = file.name.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);

    if (isImage && !file.isDir) {
      final apiClient = ref.watch(streamApiClientProvider);
      final encodedPath = Uri.encodeComponent(file.path).replaceAll('%2F', '/');
      final streamUrl =
          '${apiClient.baseUrl}/stream/$encodedPath?token=${apiClient.authToken}';

      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: CachedNetworkImage(
          imageUrl: streamUrl,
          httpHeaders: {'Authorization': 'Bearer ${apiClient.authToken}'},
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: 200,
          placeholder: (context, url) => _buildDefaultIcon(),
          errorWidget: (context, url, error) => _buildDefaultIcon(),
        ),
      );
    }

    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Icon(
      file.isDir ? Icons.folder_rounded : _getFileIcon(file.name),
      color: file.isDir ? const Color(0xFF1A73E8) : AppColors.gray,
      size: size * 0.6,
    );
  }
}

class _FileGridCard extends ConsumerWidget {
  final FileItem file;
  final List<FileItem> allFiles;
  const _FileGridCard({required this.file, required this.allFiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FileItemBase(
      file: file,
      allFiles: allFiles,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _FileThumbnail(file: file, size: 70),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              file.name,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              file.isDir ? 'Folder' : _formatBytes(file.size),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.gray,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileListCard extends ConsumerWidget {
  final FileItem file;
  final List<FileItem> allFiles;
  const _FileListCard({required this.file, required this.allFiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _FileItemBase(
        file: file,
        allFiles: allFiles,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F4F9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: file.isDir
                      ? const Color(0xFFE8F0FE)
                      : const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: _FileThumbnail(file: file, size: 48),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.isDir ? 'Folder' : _formatBytes(file.size),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.gray,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileItemBase extends ConsumerWidget {
  final FileItem file;
  final List<FileItem> allFiles;
  final Widget child;

  const _FileItemBase({
    required this.file,
    required this.allFiles,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItems = ref.watch(selectedItemsProvider);
    final isSelected = selectedItems.contains(file.path);
    final isSelectionMode = ref.watch(isSelectionModeProvider);

    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      onLongPressStart: (details) =>
          _showContextMenu(context, ref, details.globalPosition),
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, ref, details.globalPosition),
      child: Stack(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
              ),
              child: child,
            ),
          ),
          if (isSelectionMode)
            Positioned(
              top: 10,
              right: 10,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.gray.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleSelection(WidgetRef ref) {
    final selected = {...ref.read(selectedItemsProvider)};
    if (selected.contains(file.path)) {
      selected.remove(file.path);
    } else {
      selected.add(file.path);
    }
    ref.read(selectedItemsProvider.notifier).state = selected;
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    final isSelectionMode = ref.read(isSelectionModeProvider);
    if (isSelectionMode) {
      _toggleSelection(ref);
      return;
    }

    if (file.isDir) {
      if (ref.read(movingItemsProvider) == null) {
        ref.read(selectedItemsProvider.notifier).state = {};
      }
      context.push(
          Uri(path: '/', queryParameters: {'path': file.path}).toString());
    } else {
      _openFile(context, ref, allFiles);
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Preparing media...',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Initializing viewer...',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFile(
      BuildContext context, WidgetRef ref, List<FileItem> allFiles) async {
    final ext = file.name.split('.').last.toLowerCase();
    final apiClient = ref.read(streamApiClientProvider);
    final encodedPath = Uri.encodeComponent(file.path).replaceAll('%2F', '/');
    final streamUrl =
        '${apiClient.baseUrl}/stream/$encodedPath?token=${apiClient.authToken}';
    final headers = {'Authorization': 'Bearer ${apiClient.authToken}'};

    if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp'
    ].contains(ext)) {
      _showLoadingDialog(context);
    }

    try {
      if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
        final videoController = VideoPlayerController.networkUrl(
          Uri.parse(streamUrl),
          httpHeaders: headers,
        );

        await videoController.initialize().timeout(const Duration(seconds: 60));

        if (context.mounted) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => VideoPlayerDialog(
              videoUrl: streamUrl,
              fileName: file.name,
              headers: headers,
              allFiles: allFiles,
              initialFile: file,
              preInitializedController: videoController,
            ),
          );
        } else {
          videoController.dispose();
        }
      } else if (['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'].contains(ext)) {
        showDialog(
          context: context,
          builder: (context) => AudioPlayerDialog(
            audioUrl: streamUrl,
            fileName: file.name,
            headers: headers,
            allFiles: allFiles,
            initialFile: file,
          ),
        );
      } else if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        final imageProvider =
            CachedNetworkImageProvider(streamUrl, headers: headers);

        final ImageStream stream =
            imageProvider.resolve(ImageConfiguration.empty);
        final completer = Completer<void>();
        final listener = ImageStreamListener(
          (ImageInfo info, bool synchronousCall) {
            if (!completer.isCompleted) completer.complete();
          },
          onError: (Object exception, StackTrace? stackTrace) {
            if (!completer.isCompleted) completer.complete();
          },
        );
        stream.addListener(listener);

        await completer.future
            .timeout(const Duration(seconds: 30), onTimeout: () => null);
        stream.removeListener(listener);

        if (context.mounted) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => ImageViewerDialog(
              imageUrl: streamUrl,
              fileName: file.name,
              headers: headers,
              allFiles: allFiles,
              initialFile: file,
            ),
          );
        }
      } else {
        _showFileDetails(context);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _downloadFile(BuildContext context, WidgetRef ref) async {
    if (file.isDir) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder download not supported yet')),
      );
      return;
    }

    try {
      if (Platform.isAndroid) {
        await [Permission.storage].request();
      }

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      downloadsDir ??= await getApplicationDocumentsDirectory();

      final baseName = file.name;
      String savePath = '${downloadsDir.path}/$baseName';

      var fileToSave = File(savePath);
      var counter = 1;
      while (await fileToSave.exists()) {
        final dotIndex = baseName.lastIndexOf('.');
        if (dotIndex != -1) {
          final name = baseName.substring(0, dotIndex);
          final ext = baseName.substring(dotIndex);
          savePath = '${downloadsDir.path}/$name ($counter)$ext';
        } else {
          savePath = '${downloadsDir.path}/$baseName ($counter)';
        }
        fileToSave = File(savePath);
        counter++;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(child: Text('Downloading ${file.name}...')),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final success = await ref.read(fileOpsProvider.notifier).downloadFile(
            file.path,
            savePath,
          );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: ${savePath.split('/').last}'),
            backgroundColor: const Color(0xFF2E7D32),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(savePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Download failed: $e'),
              backgroundColor: AppColors.usageRed),
        );
      }
    }
  }

  void _showContextMenu(BuildContext context, WidgetRef ref, Offset position) {
    final isSelectionMode = ref.read(isSelectionModeProvider);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: isSelectionMode
          ? [
              _buildPopupItem(Icons.drive_file_move_outlined, 'Move Selected',
                  () {
                final parent = p.dirname(file.path);
                handleBulkMove(context, ref, parent == '.' ? '' : parent);
              }),
              _buildPopupItem(Icons.delete_outline_rounded, 'Delete Selected',
                  () {
                final parent = p.dirname(file.path);
                handleBulkDelete(context, ref, parent == '.' ? '' : parent);
              }, isDestructive: true),
            ]
          : [
              _buildPopupItem(Icons.open_in_new_rounded, 'Open',
                  () => _handleTap(context, ref)),
              if (!file.isDir)
                _buildPopupItem(Icons.download_rounded, 'Download',
                    () => _downloadFile(context, ref)),
              _buildPopupItem(Icons.check_box_outlined, 'Select',
                  () => _toggleSelection(ref)),
              _buildPopupItem(Icons.edit_outlined, 'Rename',
                  () => _showRenameDialog(context, ref)),
              _buildPopupItem(Icons.drive_file_move_outlined, 'Move',
                  () => ref.read(movingItemsProvider.notifier).state = [file]),
              _buildPopupItem(Icons.info_outline_rounded, 'Details',
                  () => _showFileDetails(context)),
              _buildPopupItem(Icons.delete_outline_rounded, 'Delete',
                  () => _showDeleteConfirmation(context, ref),
                  isDestructive: true),
            ],
    );
  }

  PopupMenuItem _buildPopupItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isDestructive ? AppColors.usageRed : AppColors.textBlack),
          const SizedBox(width: 12),
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? AppColors.usageRed
                      : AppColors.textBlack)),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: file.name);
    _showStyledDialog(
      context: context,
      title: 'Rename',
      child: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New name')),
      onConfirm: () async {
        final newName = controller.text.trim();
        if (newName.isNotEmpty && newName != file.name) {
          String finalName = newName;

          if (!file.isDir) {
            final dotIndex = file.name.lastIndexOf('.');
            if (dotIndex != -1) {
              final extension = file.name.substring(dotIndex);
              if (!newName.toLowerCase().endsWith(extension.toLowerCase())) {
                finalName = '$newName$extension';
              }
            }
          }

          final parentPath =
              file.path.substring(0, file.path.lastIndexOf(file.name));
          final newPath = '$parentPath$finalName';

          final success = await ref
              .read(fileOpsProvider.notifier)
              .renameItem(file.path, newPath);
          if (success) ref.invalidate(fileListProvider);
        }
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    _showStyledDialog(
      context: context,
      title: 'Delete',
      child: Text('Are you sure you want to delete "${file.name}"?'),
      onConfirm: () async {
        final success =
            await ref.read(fileOpsProvider.notifier).deleteItem(file.path);
        if (success) ref.invalidate(fileListProvider);
      },
    );
  }

  void _showFileDetails(BuildContext context) {
    _showStyledDialog(
      context: context,
      title: 'Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailLine(label: 'Name', value: file.name),
          _DetailLine(
              label: 'Size',
              value: file.isDir ? 'Folder' : _formatBytes(file.size)),
          _DetailLine(label: 'Path', value: file.path),
        ],
      ),
      onConfirm: () {},
    );
  }
}

void handleBulkDelete(BuildContext context, WidgetRef ref, String currentPath) {
  final selected = ref.read(selectedItemsProvider);
  _showStyledDialog(
    context: context,
    title: 'Delete Items',
    child: Text('Delete ${selected.length} items permanently?'),
    onConfirm: () async {
      final success = await ref
          .read(fileOpsProvider.notifier)
          .deleteMultipleItems(selected.toList());
      if (success) {
        ref.read(selectedItemsProvider.notifier).state = {};
        ref.invalidate(fileListProvider(currentPath));
      }
    },
    confirmText: 'Delete',
    isDestructive: true,
  );
}

void handleBulkMove(BuildContext context, WidgetRef ref, String currentPath) {
  final selectedPaths = ref.read(selectedItemsProvider);
  final fileList = ref.read(filteredFilesProvider(currentPath)).value;
  if (fileList == null) return;

  final itemsToMove =
      fileList.where((f) => selectedPaths.contains(f.path)).toList();

  ref.read(movingItemsProvider.notifier).state = itemsToMove;
  ref.read(selectedItemsProvider.notifier).state = {};
}

IconData _getFileIcon(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
      return Icons.image_rounded;
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'mkv':
      return Icons.video_file_rounded;
    case 'mp3':
    case 'wav':
    case 'flac':
      return Icons.audio_file_rounded;
    case 'zip':
    case 'rar':
    case '7z':
      return Icons.folder_zip_rounded;
    case 'doc':
    case 'docx':
      return Icons.description_rounded;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart_rounded;
    case 'ppt':
    case 'pptx':
      return Icons.slideshow_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

String _formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (math.log(bytes) / math.log(1024)).floor();
  return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

void _showStyledDialog({
  required BuildContext context,
  required String title,
  required Widget child,
  required VoidCallback onConfirm,
  String confirmText = 'Confirm',
  bool isDestructive = false,
}) {
  showDialog(
    context: context,
    builder: (context) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack)),
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppColors.gray,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive
                          ? AppColors.usageRed
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Text(confirmText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  const _DetailLine({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.gray,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(value,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textBlack,
              fontWeight: FontWeight.bold)),
    ]);
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 180,
        decoration: BoxDecoration(
            color: const Color(0xFFEDF0F5),
            borderRadius: BorderRadius.circular(24)));
  }
}

class _UploadProgressOverlay extends ConsumerStatefulWidget {
  const _UploadProgressOverlay();

  @override
  ConsumerState<_UploadProgressOverlay> createState() =>
      _UploadProgressOverlayState();
}

class _UploadProgressOverlayState
    extends ConsumerState<_UploadProgressOverlay> {
  Timer? _autoHideTimer;

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(uploadOverlayVisibleProvider.notifier).state = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uploads = ref.watch(uploadStatusProvider);
    final isVisible = ref.watch(uploadOverlayVisibleProvider);

    // Start auto-hide timer when uploads start
    ref.listen(uploadStatusProvider, (prev, next) {
      if (next.isNotEmpty && (prev?.isEmpty ?? true)) {
        // New upload started, show overlay and start timer
        ref.read(uploadOverlayVisibleProvider.notifier).state = true;
        _startAutoHideTimer();
      } else if (next.isEmpty) {
        // All uploads done, hide overlay
        _autoHideTimer?.cancel();
      }
    });

    if (uploads.isEmpty || !isVisible) return const SizedBox.shrink();

    // Calculate overall progress
    final activeUploads = uploads.values
        .where((s) => !s.isComplete && !s.isError && !s.isCancelled);
    final totalProgress = activeUploads.isEmpty
        ? 1.0
        : activeUploads.map((s) => s.progress).reduce((a, b) => a + b) /
            activeUploads.length;
    final uploadingCount = activeUploads.length;
    final completedCount = uploads.values.where((s) => s.isComplete).length;

    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.of(context).padding.top + 10,
      child: GestureDetector(
        onTap: () {
          // Tap to show overlay again and reset timer
          _startAutoHideTimer();
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.textBlack,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Upload icon with progress ring
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: totalProgress,
                        strokeWidth: 3,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                      const Icon(
                        Icons.cloud_upload_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        uploadingCount > 0
                            ? 'Uploading $uploadingCount file${uploadingCount > 1 ? 's' : ''}...'
                            : '$completedCount file${completedCount > 1 ? 's' : ''} uploaded',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Running in background',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button (hides overlay, upload continues)
                IconButton(
                  onPressed: () {
                    _autoHideTimer?.cancel();
                    ref.read(uploadOverlayVisibleProvider.notifier).state =
                        false;
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: -0.5, end: 0, curve: Curves.easeOutBack).fadeIn();
  }
}
