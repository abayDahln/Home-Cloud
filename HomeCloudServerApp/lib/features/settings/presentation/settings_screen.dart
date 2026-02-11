import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/providers/server_provider.dart';
import '../models/server_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _portController = TextEditingController();
  final _passwordController = TextEditingController();
  final _quotaController = TextEditingController();
  final _uploadSizeController = TextEditingController();
  final _watchDirController = TextEditingController();
  String _uploadUnit = 'GB';
  bool _obscurePassword = true;
  bool _hasChanges = false;
  bool _isSaving = false;
  static const String _fontFamily = 'Plus Jakarta Sans';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final settings = ref.read(serverSettingsProvider);
    _portController.text = settings.port;
    _passwordController.text = settings.authToken;
    _quotaController.text = settings.storageQuotaGB.toString();
    _watchDirController.text = settings.watchDir;

    // Convert bytes to readable unit
    if (settings.maxUploadSize >= 1073741824) {
      _uploadSizeController.text =
          (settings.maxUploadSize / 1073741824).toStringAsFixed(0);
      _uploadUnit = 'GB';
    } else if (settings.maxUploadSize >= 1048576) {
      _uploadSizeController.text =
          (settings.maxUploadSize / 1048576).toStringAsFixed(0);
      _uploadUnit = 'MB';
    } else {
      _uploadSizeController.text =
          (settings.maxUploadSize / 1024).toStringAsFixed(0);
      _uploadUnit = 'KB';
    }
  }

  int _getUploadSizeInBytes() {
    final size = int.tryParse(_uploadSizeController.text) ?? 1;
    switch (_uploadUnit) {
      case 'GB':
        return size * 1073741824;
      case 'MB':
        return size * 1048576;
      case 'KB':
        return size * 1024;
      default:
        return size;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final port = int.tryParse(_portController.text);
    if (port == null || port < 1024 || port > 65535) {
      _showError('Port must be between 1024 and 65535');
      setState(() => _isSaving = false);
      return;
    }

    final quota = int.tryParse(_quotaController.text);
    if (quota == null || quota < 1 || quota > 1000) {
      _showError('Storage quota must be between 1 and 1000 GB');
      setState(() => _isSaving = false);
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showError('Password cannot be empty');
      setState(() => _isSaving = false);
      return;
    }

    final settings = ServerSettings(
      port: _portController.text.trim(),
      authToken: _passwordController.text.trim(),
      storageQuotaGB: quota,
      maxUploadSize: _getUploadSizeInBytes(),
      watchDir: _watchDirController.text.trim(),
    );

    await ref.read(serverSettingsProvider.notifier).update(settings);

    // Automatically sync with server if it's running
    final server = ref.read(serverServiceProvider);
    bool restarted = false;
    if (server.isRunning) {
      await server.restart();
      restarted = true;
    }

    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                restarted
                    ? 'Settings saved and server synchronized!'
                    : 'Settings saved! Start server to apply changes.',
                style: const TextStyle(fontFamily: _fontFamily),
              ),
            ],
          ),
          backgroundColor: AppColors.usageGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(message, style: const TextStyle(fontFamily: _fontFamily)),
            ],
          ),
          backgroundColor: AppColors.usageRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Storage Directory',
    );
    if (result != null) {
      _watchDirController.text = result;
      _markChanged();
    }
  }

  @override
  void dispose() {
    _portController.dispose();
    _passwordController.dispose();
    _quotaController.dispose();
    _uploadSizeController.dispose();
    _watchDirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'Settings',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure your HomeCloud server',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 14,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_hasChanges)
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Settings form
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        children: [
                          _SettingsCard(
                            title: 'Network',
                            icon: Icons.lan_rounded,
                            children: [
                              _SettingsField(
                                label: 'Server Port',
                                hint: 'e.g., 8080',
                                controller: _portController,
                                onChanged: (_) => _markChanged(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                helperText: 'Range: 1024 – 65535',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _SettingsCard(
                            title: 'Security',
                            icon: Icons.shield_rounded,
                            children: [
                              _SettingsField(
                                label: 'Password / Auth Token',
                                hint: 'Enter server password',
                                controller: _passwordController,
                                onChanged: (_) => _markChanged(),
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                helperText: 'Used by HomeCloudApp to connect',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right column
                    Expanded(
                      child: Column(
                        children: [
                          _SettingsCard(
                            title: 'Storage',
                            icon: Icons.storage_rounded,
                            children: [
                              _SettingsField(
                                label: 'Storage Quota',
                                hint: 'e.g., 100',
                                controller: _quotaController,
                                onChanged: (_) => _markChanged(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                helperText: 'Range: 1 – 1000 GB',
                                suffix: const Text(
                                  'GB',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    color: AppColors.gray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _SettingsField(
                                      label: 'Max Upload Size',
                                      hint: 'e.g., 1',
                                      controller: _uploadSizeController,
                                      onChanged: (_) => _markChanged(),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Unit',
                                          style: TextStyle(
                                            fontFamily: _fontFamily,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textBlack,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F4F9),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _uploadUnit,
                                              isExpanded: true,
                                              items: ['KB', 'MB', 'GB']
                                                  .map((u) => DropdownMenuItem(
                                                        value: u,
                                                        child: Text(u),
                                                      ))
                                                  .toList(),
                                              onChanged: (v) {
                                                if (v != null) {
                                                  setState(
                                                      () => _uploadUnit = v);
                                                  _markChanged();
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _SettingsField(
                                label: 'Storage Directory',
                                hint: './uploads',
                                controller: _watchDirController,
                                onChanged: (_) => _markChanged(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.folder_open_rounded,
                                      size: 20),
                                  onPressed: _pickDirectory,
                                ),
                                helperText: 'Where uploaded files are stored',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  static const String _fontFamily = 'Plus Jakarta Sans';

  const _SettingsCard({
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
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 16,
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

class _SettingsField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? helperText;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? suffix;
  static const String _fontFamily = 'Plus Jakarta Sans';

  const _SettingsField({
    required this.label,
    required this.hint,
    required this.controller,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.helperText,
    this.obscureText = false,
    this.suffixIcon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          style: const TextStyle(fontFamily: _fontFamily, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF1F4F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: suffixIcon,
            suffix: suffix,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 11,
              color: AppColors.gray,
            ),
          ),
        ],
      ],
    );
  }
}
