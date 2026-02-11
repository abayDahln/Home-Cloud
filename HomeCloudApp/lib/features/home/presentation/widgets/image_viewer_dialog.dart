import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/file_provider.dart';

class ImageViewerDialog extends StatefulWidget {
  final String imageUrl;
  final String fileName;
  final Map<String, String> headers;
  final List<FileItem> allFiles;
  final FileItem initialFile;

  const ImageViewerDialog({
    super.key,
    required this.imageUrl,
    required this.fileName,
    required this.headers,
    required this.allFiles,
    required this.initialFile,
  });

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  late List<FileItem> _playlist;
  late int _currentIndex;
  late String _currentFileName;
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentFileName = widget.fileName;
    _currentUrl = widget.imageUrl;


    _playlist =
        widget.allFiles.where((f) => !f.isDir && _isImage(f.name)).toList();
    _currentIndex =
        _playlist.indexWhere((f) => f.path == widget.initialFile.path);
    if (_currentIndex == -1) _currentIndex = 0;
  }

  bool _isImage(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  void _playNext() {
    if (_currentIndex < _playlist.length - 1) {
      _navigateToIndex(_currentIndex + 1);
    }
  }

  void _playPrev() {
    if (_currentIndex > 0) {
      _navigateToIndex(_currentIndex - 1);
    }
  }

  void _navigateToIndex(int index) {
    if (!mounted) return;
    final nextFile = _playlist[index];
    final encodedPath =
        Uri.encodeComponent(nextFile.path).replaceAll('%2F', '/');


    final baseUri = Uri.parse(widget.imageUrl);
    final streamBaseUrl =
        '${baseUri.scheme}://${baseUri.host}:${baseUri.port}${baseUri.path.split('/stream/').first}/stream';

    _resetZoom();
    setState(() {
      _currentIndex = index;
      _currentFileName = nextFile.name;
      _currentUrl = '$streamBaseUrl/$encodedPath';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentFileName,
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_playlist.length > 1)
                          Text(
                            '${_currentIndex + 1} of ${_playlist.length}',
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_currentScale != 1.0)
                    IconButton(
                      icon:
                          const Icon(Icons.zoom_out_map, color: Colors.white54),
                      onPressed: _resetZoom,
                      tooltip: 'Reset zoom',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),


            Flexible(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    onInteractionEnd: (details) {
                      setState(() {
                        _currentScale =
                            _transformationController.value.getMaxScaleOnAxis();
                      });
                    },
                    child: CachedNetworkImage(
                      imageUrl: _currentUrl,
                      httpHeaders: widget.headers,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),


                  if (_playlist.length > 1) ...[

                    if (_currentIndex > 0)
                      Positioned(
                        left: 16,
                        child: _NavButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: _playPrev,
                        ),
                      ),

                    if (_currentIndex < _playlist.length - 1)
                      Positioned(
                        right: 16,
                        child: _NavButton(
                          icon: Icons.chevron_right_rounded,
                          onPressed: _playNext,
                        ),
                      ),
                  ],
                ],
              ),
            ),


            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Center(
                child: Text(
                  'Pinch to zoom • ${(_currentScale * 100).toInt()}%',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                      color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 32),
        onPressed: onPressed,
      ),
    );
  }
}
