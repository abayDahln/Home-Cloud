import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/file_provider.dart';

class AudioPlayerDialog extends StatefulWidget {
  final String audioUrl;
  final String fileName;
  final Map<String, String> headers;
  final List<FileItem> allFiles;
  final FileItem initialFile;

  const AudioPlayerDialog({
    super.key,
    required this.audioUrl,
    required this.fileName,
    required this.headers,
    required this.allFiles,
    required this.initialFile,
  });

  @override
  State<AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<AudioPlayerDialog> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  late List<FileItem> _playlist;
  late int _currentIndex;
  late String _currentFileName;
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentFileName = widget.fileName;
    _currentUrl = widget.audioUrl;


    _playlist =
        widget.allFiles.where((f) => !f.isDir && _isAudio(f.name)).toList();
    _currentIndex =
        _playlist.indexWhere((f) => f.path == widget.initialFile.path);
    if (_currentIndex == -1) _currentIndex = 0;

    _initializePlayer();
  }

  bool _isAudio(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'].contains(ext);
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state == PlayerState.playing);
        }
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() => _duration = duration);
        }
      });

      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        _playNext();
      });


      final uri = Uri.parse(_currentUrl);
      String? token;
      final authHeader = widget.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
      }

      final playerUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          if (token != null) 'token': token,
        },
      );

      final finalUrl = playerUri.toString();
      debugPrint('🎵 Audio Player attempting: $finalUrl');

      await _audioPlayer.play(UrlSource(finalUrl));

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Audio Player Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _getReadableError(e.toString());
        });
      }
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


    final baseUri = Uri.parse(widget.audioUrl);
    final streamBaseUrl =
        '${baseUri.scheme}://${baseUri.host}:${baseUri.port}${baseUri.path.split('/stream/').first}/stream';

    setState(() {
      _currentIndex = index;
      _currentFileName = nextFile.name;
      _currentUrl = '$streamBaseUrl/$encodedPath';
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    _initializePlayer();
  }

  String _getReadableError(String error) {
    if (error.contains('80070005') || error.contains('Access is denied')) {
      return 'Access Denied. Check server permissions or authentication.';
    }
    if (error.contains('404')) return 'Audio file not found on server.';
    if (error.contains('401')) return 'Session expired. Please login again.';
    return 'Failed to load audio: $error';
  }

  Future<void> _retry() async {
    await _initializePlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_playlist.length > 1)
                      Text(
                        '${_currentIndex + 1}/${_playlist.length}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),


                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isPlaying) _RotatingGlow(isPlaying: _isPlaying),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(Icons.music_note_rounded,
                          color: Colors.white, size: 60),
                    ),
                  ],
                ),
                const SizedBox(height: 20),


                Text(
                  _currentFileName,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Audio File',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 24),


                if (_error != null)
                  _buildErrorState()
                else if (!_isLoading)
                  _buildPlayerControls()
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          'Error Playback',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error!,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _retry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerControls() {
    return Column(
      children: [

        Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(24, (index) {
              return _WaveBar(isPlaying: _isPlaying, index: index);
            }),
          ),
        ),

        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 4,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white12,
            thumbColor: AppColors.primary,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble() > 0
                ? _duration.inSeconds.toDouble()
                : 1,
            onChanged: (value) {
              _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position),
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text(_formatDuration(_duration),
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 32),


        FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              IconButton(
                icon: Icon(Icons.skip_previous_rounded,
                    color: _currentIndex > 0 ? Colors.white70 : Colors.white12,
                    size: 32),
                onPressed: _currentIndex > 0 ? _playPrev : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.replay_10_rounded,
                    color: Colors.white70, size: 32),
                onPressed: () {
                  final newPosition = _position - const Duration(seconds: 10);
                  _audioPlayer.seek(newPosition > Duration.zero
                      ? newPosition
                      : Duration.zero);
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (_isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.resume();
                  }
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded,
                    color: Colors.white70, size: 32),
                onPressed: () {
                  final newPosition = _position + const Duration(seconds: 10);
                  _audioPlayer
                      .seek(newPosition < _duration ? newPosition : _duration);
                },
              ),
              const SizedBox(width: 8),

              IconButton(
                icon: Icon(Icons.skip_next_rounded,
                    color: _currentIndex < _playlist.length - 1
                        ? Colors.white70
                        : Colors.white12,
                    size: 32),
                onPressed:
                    _currentIndex < _playlist.length - 1 ? _playNext : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _WaveBar extends StatefulWidget {
  final bool isPlaying;
  final int index;

  const _WaveBar({required this.isPlaying, required this.index});

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250 + _random.nextInt(400)),
    );


    final double targetHeight = 10.0 + _random.nextDouble() * 40.0;

    _animation = Tween<double>(begin: 6.0, end: targetHeight).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_WaveBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: widget.isPlaying ? _animation.value : 6.0,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}

class _RotatingGlow extends StatefulWidget {
  final bool isPlaying;
  const _RotatingGlow({required this.isPlaying});

  @override
  State<_RotatingGlow> createState() => _RotatingGlowState();
}

class _RotatingGlowState extends State<_RotatingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.0),
              AppColors.primary.withValues(alpha: 0.3),
              AppColors.primary.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
