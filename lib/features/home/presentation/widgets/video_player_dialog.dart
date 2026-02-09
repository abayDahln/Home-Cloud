import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/file_provider.dart';

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  final String fileName;
  final Map<String, String> headers;
  final List<FileItem> allFiles;
  final FileItem initialFile;
  final VideoPlayerController? preInitializedController;

  const VideoPlayerDialog({
    super.key,
    required this.videoUrl,
    required this.fileName,
    required this.headers,
    required this.allFiles,
    required this.initialFile,
    this.preInitializedController,
  });

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  bool _isRetrying = false;

  late List<FileItem> _playlist;
  late int _currentIndex;
  late String _currentFileName;
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentFileName = widget.fileName;
    _currentUrl = widget.videoUrl;


    _playlist =
        widget.allFiles.where((f) => !f.isDir && _isVideo(f.name)).toList();
    _currentIndex =
        _playlist.indexWhere((f) => f.path == widget.initialFile.path);
    if (_currentIndex == -1) _currentIndex = 0;

    _initializePlayer();
  }

  bool _isVideo(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isRetrying = false;
    });

    try {
      if (widget.preInitializedController != null &&
          _videoController == null &&
          _currentUrl == widget.videoUrl) {
        debugPrint('🎬 Using pre-initialized video player');
        _videoController = widget.preInitializedController;

        _videoController!.removeListener(_videoListener);
        _videoController!.addListener(_videoListener);
        _isLoading = false;
      } else {
        debugPrint('🎬 Initializing video player...');
        debugPrint('📍 URL: $_currentUrl');


        _chewieController?.dispose();
        _videoController?.dispose();
        _chewieController = null;
        _videoController = null;

        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(_currentUrl),
          httpHeaders: widget.headers,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );


        _videoController!.addListener(_videoListener);


        await _videoController!.initialize().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception(
                'Connection timeout - server took too long to respond');
          },
        );
      }

      debugPrint('✅ Video initialized successfully');

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        showOptions: false,
        progressIndicatorDelay: Duration.zero,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.white),
                SizedBox(height: 16),
                Text(
                  'Buffering...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Playback Error',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, stack) {
      debugPrint('❌ Video initialization error: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _getReadableError(e.toString());
        });
      }
    }
  }

  void _videoListener() {
    if (_videoController == null) return;

    if (_videoController!.value.hasError == true && mounted) {
      setState(() {
        _error = _videoController?.value.errorDescription ??
            'Unknown playback error';
      });
    }


    if (_videoController!.value.position >= _videoController!.value.duration &&
        _videoController!.value.isInitialized &&
        !_videoController!.value.isPlaying &&
        !_isLoading) {
      _playNext();
    }
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


    final baseUri = Uri.parse(widget.videoUrl);
    final streamBaseUrl =
        '${baseUri.scheme}://${baseUri.host}:${baseUri.port}${baseUri.path.split('/stream/').first}/stream';

    setState(() {
      _currentIndex = index;
      _currentFileName = nextFile.name;
      _currentUrl = '$streamBaseUrl/$encodedPath';
    });
    _initializePlayer();
  }

  String _getReadableError(String error) {
    if (error.contains('timeout')) {
      return 'Connection timeout. Please check your network connection and server status.';
    }
    if (error.contains('404') || error.contains('Not Found')) {
      return 'Video not found on server.';
    }
    if (error.contains('401') || error.contains('Unauthorized')) {
      return 'Unauthorized. Please login again.';
    }
    if (error.contains('403') || error.contains('Forbidden')) {
      return 'Access denied.';
    }
    if (error.contains('Connection refused') ||
        error.contains('ECONNREFUSED')) {
      return 'Cannot connect to server. Please make sure the server is running.';
    }
    if (error.contains('SocketException') || error.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load video: $error';
  }

  Future<void> _retryPlayback() async {
    setState(() => _isRetrying = true);
    await _initializePlayer();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      Icons.play_circle_outline,
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
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_videoController?.value.isInitialized == true)
                          Text(
                            _formatDuration(_videoController!.value.duration),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_playlist.length > 1) ...[
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: AppColors.white),
                      onPressed: _currentIndex > 0 ? _playPrev : null,
                    ),
                    Text(
                      '${_currentIndex + 1}/${_playlist.length}',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70, fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          color: AppColors.white),
                      onPressed: _currentIndex < _playlist.length - 1
                          ? _playNext
                          : null,
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),


            Flexible(
              child: _buildVideoContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isLoading) {
      return Container(
        height: 400,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isRetrying ? 'Retrying...' : 'Loading video...',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preparing stream',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading Video',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _retryPlayback,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }


    if (_chewieController != null && _videoController!.value.isInitialized) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
